# Helm values come from the eks-core-gitops repository, cloned next to this one
# (see var.gitops_repo_path). Account-specific placeholders in those files are
# filled in here so the committed manifests stay free of account IDs.
locals {
  gitops_dir = "${path.module}/../${var.gitops_repo_path}"
}

resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "3.4.0"
  namespace        = "kube-system"
  create_namespace = false

  skip_crds = false
  wait      = true
  atomic    = true
  timeout   = 900

  values = [yamlencode({
    clusterName = module.cluster.cluster_name
    region      = local.region
    vpcId       = local.vpc_id

    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
    }

    nodeSelector = {
      role = "infra"
    }

    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]

    replicaCount      = 2
    defaultTargetType = "ip"

    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        memory = "256Mi"
      }
    }
  })]

  # The controller's webhook must have live endpoints before any other chart
  # creates Services. Wait for the EKS add-ons/node group as one module first.
  depends_on = [
    module.cluster,
    module.lb_controller_pod_identity,
  ]
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.14.1"
  namespace  = "kube-system"

  skip_crds = false
  wait      = true
  atomic    = true
  timeout   = 900

  values = [
    replace(file("${local.gitops_dir}/platform/addons/karpenter/values.yaml"), "<AWS_ACCOUNT_ID>", var.aws_account_id),
    yamlencode({
      settings = {
        clusterName       = module.cluster.cluster_name
        interruptionQueue = module.karpenter.queue_name
      }
      serviceAccount = {
        create = true
        name   = module.karpenter.service_account
      }
    }),
  ]

  depends_on = [
    module.cluster,
    module.karpenter,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.3.0"
  namespace        = "argocd"
  create_namespace = true

  wait    = true
  atomic  = true
  timeout = 900

  values = [replace(file("${local.gitops_dir}/platform/addons/argocd/values.yaml"), "<AWS_ACCOUNT_ID>", var.aws_account_id)]

  depends_on = [
    module.cluster,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "88.6.2"
  namespace        = "monitoring"
  create_namespace = true

  wait      = false
  skip_crds = false

  values = [replace(file("${local.gitops_dir}/platform/addons/prometheus/values.yaml"), "<AWS_ACCOUNT_ID>", var.aws_account_id)]

  depends_on = [
    module.cluster,
    helm_release.aws_load_balancer_controller,
  ]
}

# Metrics Server implements metrics.k8s.io, which Kite uses for the resource
# utilization and network panels. Prometheus does not replace this Kubernetes
# API, so it must be installed independently.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.14.0"
  namespace  = "kube-system"

  wait    = true
  atomic  = true
  timeout = 900

  values = [replace(file("${local.gitops_dir}/platform/addons/metrics-server/values.yaml"), "<AWS_ACCOUNT_ID>", var.aws_account_id)]

  depends_on = [
    module.cluster,
    helm_release.aws_load_balancer_controller,
  ]
}

# The workload cluster's stateful platform components use EBS gp3 volumes.
# This must be Terraform-owned because Helm releases (including Kite) create
# their PVCs before any optional GitOps manifest is reconciled.
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [
    module.cluster,
    module.ebs_csi_pod_identity,
    helm_release.aws_load_balancer_controller,
  ]
}

# Kite is a cluster administration dashboard. Its chart needs broad Kubernetes
# RBAC to provide the resource-management features requested by the product;
# keep it on the managed infra node group and do not expose it publicly by
# default. A secure, Terraform-generated Secret replaces the chart's insecure
# default encryption key.
resource "kubernetes_namespace_v1" "kite" {
  metadata {
    name = "kite-system"
  }

  depends_on = [
    module.cluster,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "random_password" "kite_jwt" {
  length  = 64
  special = false
}

resource "random_password" "kite_encryption" {
  length  = 64
  special = false
}

resource "kubernetes_secret_v1" "kite" {
  metadata {
    name      = "kite"
    namespace = kubernetes_namespace_v1.kite.metadata[0].name
  }

  type = "Opaque"

  data = {
    JWT_SECRET       = random_password.kite_jwt.result
    KITE_ENCRYPT_KEY = random_password.kite_encryption.result
    DB_TYPE          = "sqlite"
  }
}

resource "helm_release" "kite" {
  name       = "kite"
  repository = "oci://ghcr.io/kite-org/charts"
  chart      = "kite"
  version    = "0.15.0"
  namespace  = kubernetes_namespace_v1.kite.metadata[0].name

  wait    = true
  atomic  = true
  timeout = 900

  values = [yamlencode({
    # SQLite is acceptable for this single-replica dashboard only when its
    # data is persistent. Recreate avoids two pods contending for one RWO PVC
    # during a chart upgrade.
    replicaCount = 1
    deploymentStrategy = {
      type = "Recreate"
    }
    secret = {
      create         = false
      existingSecret = kubernetes_secret_v1.kite.metadata[0].name
    }
    db = {
      type = "sqlite"
      sqlite = {
        persistence = {
          pvc = {
            enabled      = true
            storageClass = "gp3"
            accessModes  = ["ReadWriteOnce"]
            size         = "5Gi"
          }
        }
      }
    }
    nodeSelector = {
      role = "infra"
    }
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]
    resources = {
      requests = {
        cpu    = "250m"
        memory = "256Mi"
      }
      limits = {
        memory = "512Mi"
      }
    }
    # No Ingress until a private hostname and ACM certificate are configured.
    ingress = {
      enabled = false
    }
  })]

  depends_on = [
    kubernetes_secret_v1.kite,
    kubernetes_storage_class_v1.gp3,
  ]
}

# Grafana is deliberately a separate release from kube-prometheus-stack.  The
# latter has Grafana disabled in its values because this dashboard is exposed
# through the workload cluster's ALB and needs an independently managed login.
resource "random_password" "grafana_admin" {
  length  = 32
  special = false
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = "monitoring"
  }

  type = "Opaque"

  data = {
    "admin-user"     = "admin"
    "admin-password" = random_password.grafana_admin.result
  }

  # kube-prometheus-stack creates the monitoring namespace on the initial
  # deployment, so wait for it before creating this release's login secret.
  depends_on = [helm_release.prometheus]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "10.5.15"
  namespace  = "monitoring"

  wait    = true
  atomic  = true
  timeout = 900

  values = [yamlencode({
    admin = {
      existingSecret = kubernetes_secret_v1.grafana_admin.metadata[0].name
      userKey        = "admin-user"
      passwordKey    = "admin-password"
    }

    persistence = {
      enabled          = true
      type             = "pvc"
      storageClassName = kubernetes_storage_class_v1.gp3.metadata[0].name
      accessModes      = ["ReadWriteOnce"]
      size             = "5Gi"
    }

    # Make the workload-cluster Prometheus the default datasource.  Grafana
    # queries it through the in-cluster Service instead of a public endpoint.
    datasources = {
      "datasources.yaml" = {
        apiVersion = 1
        datasources = [{
          name      = "Prometheus"
          type      = "prometheus"
          access    = "proxy"
          url       = "http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090"
          isDefault = true
        }]
      }
    }

    nodeSelector = {
      role = "infra"
    }
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]
    resources = {
      requests = {
        cpu    = "100m"
        memory = "256Mi"
      }
      limits = {
        memory = "512Mi"
      }
    }
  })]

  depends_on = [
    kubernetes_secret_v1.grafana_admin,
    kubernetes_storage_class_v1.gp3,
    helm_release.aws_load_balancer_controller,
  ]
}

# A dedicated listener keeps Grafana separate from the existing admin ingress
# paths.  It intentionally starts as HTTP because no DNS name or ACM
# certificate has been supplied. Restrict inbound-cidrs and add HTTPS/ACM
# before using this outside a lab environment.
resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "monitoring"

    annotations = {
      "alb.ingress.kubernetes.io/group.name"       = "eks-workload"
      "alb.ingress.kubernetes.io/group.order"      = "50"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 3000}]"
      "alb.ingress.kubernetes.io/inbound-cidrs"    = "0.0.0.0/0"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.grafana,
    helm_release.aws_load_balancer_controller,
  ]
}
