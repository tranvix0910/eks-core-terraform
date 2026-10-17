# Helm values come from the eks-core-gitops repository, cloned next to this one
# (see var.gitops_repo_path). Account-specific placeholders in those files are
# filled in here so the committed manifests stay free of account IDs.
locals {
  gitops_dir = "${path.module}/../${var.gitops_repo_path}"
}

# ---------------------------------------------------------------
# AWS Load Balancer Controller
# Its webhook must be up before any other chart creates Services
# ---------------------------------------------------------------
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.4.0"
  namespace  = "kube-system"

  skip_crds = false
  wait      = true
  atomic    = true
  timeout   = 900

  values = [yamlencode({
    clusterName = module.eks.cluster_name
    region      = var.region
    vpcId       = local.vpc_id
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
    }
    nodeSelector      = { role = "infra" }
    tolerations       = local.critical_addons_toleration
    replicaCount      = 2
    defaultTargetType = "ip"
    resources = {
      requests = { cpu = "100m", memory = "128Mi" }
      limits   = { memory = "256Mi" }
    }
  })]

  depends_on = [
    module.eks,
    module.lb_controller_pod_identity,
  ]
}

# ---------------------------------------------------------------
# Karpenter
# ---------------------------------------------------------------
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
    replace(file("${local.gitops_dir}/platform/addons/karpenter/values.yaml"), "<AWS_ACCOUNT_ID>", var.account_id),
    yamlencode({
      settings = {
        clusterName       = module.eks.cluster_name
        interruptionQueue = module.karpenter.queue_name
      }
      serviceAccount = {
        create = true
        name   = module.karpenter.service_account
      }
    }),
  ]

  depends_on = [
    module.karpenter,
    helm_release.aws_load_balancer_controller,
  ]
}

# ---------------------------------------------------------------
# ArgoCD
# ---------------------------------------------------------------
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

  values = [replace(file("${local.gitops_dir}/platform/addons/argocd/values.yaml"), "<AWS_ACCOUNT_ID>", var.account_id)]

  depends_on = [helm_release.aws_load_balancer_controller]
}

# ---------------------------------------------------------------
# Prometheus + Metrics Server
# metrics.k8s.io (Kite, HPA) is not provided by Prometheus
# ---------------------------------------------------------------
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "88.6.2"
  namespace        = "monitoring"
  create_namespace = true

  wait      = false
  skip_crds = false

  values = [replace(file("${local.gitops_dir}/platform/addons/prometheus/values.yaml"), "<AWS_ACCOUNT_ID>", var.account_id)]

  depends_on = [helm_release.aws_load_balancer_controller]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.14.0"
  namespace  = "kube-system"

  wait    = true
  atomic  = true
  timeout = 900

  values = [replace(file("${local.gitops_dir}/platform/addons/metrics-server/values.yaml"), "<AWS_ACCOUNT_ID>", var.account_id)]

  depends_on = [helm_release.aws_load_balancer_controller]
}

# ---------------------------------------------------------------
# Grafana - separate from kube-prometheus-stack (Grafana disabled there)
# ---------------------------------------------------------------
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

  # monitoring namespace is created by the prometheus release
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
    nodeSelector = { role = "infra" }
    tolerations  = local.critical_addons_toleration
    resources = {
      requests = { cpu = "100m", memory = "256Mi" }
      limits   = { memory = "512Mi" }
    }
  })]

  depends_on = [kubernetes_secret_v1.grafana_admin]
}

resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "monitoring"

    annotations = {
      "alb.ingress.kubernetes.io/group.name"       = local.name
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

  depends_on = [helm_release.grafana]
}
