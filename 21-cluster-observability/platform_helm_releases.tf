# Helm values come from the eks-core-gitops repository, cloned next to this one
# (see var.gitops_repo_path). Account-specific placeholders in those files are
# filled in here so the committed manifests stay free of account IDs.
locals {
  gitops_dir = "${path.module}/../${var.gitops_repo_path}"
}

# Terraform owns platform Helm releases in this cluster. GitOps retains the
# Ingress and dashboard manifests, but must not install these charts again.

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [module.cluster]
}

# All persistent observability components use gp3 EBS volumes. Keeping the
# class here ensures it exists before Helm creates any PVC, and avoids relying
# on an account-specific default StorageClass.
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

  depends_on = [module.ebs_csi_pod_identity]
}

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
    clusterName = module.cluster.cluster_name
    region      = local.region
    vpcId       = local.vpc_id
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
    }
    nodeSelector = {
      role = "monitoring"
    }
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

  depends_on = [module.lb_controller_pod_identity]
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "88.6.2"
  namespace        = kubernetes_namespace_v1.monitoring.metadata[0].name
  create_namespace = false

  skip_crds = false
  wait      = true
  atomic    = true
  timeout   = 900

  values = [replace(file("${local.gitops_dir}/platform/observability/prometheus/values.yaml"), "<AWS_ACCOUNT_ID>", var.aws_account_id)]

  depends_on = [kubernetes_storage_class_v1.gp3]
}

resource "helm_release" "mimir" {
  name             = "mimir"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "mimir-distributed"
  version          = "6.1.0"
  namespace        = kubernetes_namespace_v1.monitoring.metadata[0].name
  create_namespace = false

  wait    = true
  atomic  = true
  timeout = 1800

  values = [replace(file("${local.gitops_dir}/platform/observability/mimir/values.yaml"), "<AWS_ACCOUNT_ID>", var.aws_account_id)]

  depends_on = [
    kubernetes_storage_class_v1.gp3,
    module.mimir_pod_identity,
  ]
}

resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = "7.3.0"
  namespace        = kubernetes_namespace_v1.monitoring.metadata[0].name
  create_namespace = false

  wait    = true
  atomic  = true
  timeout = 900

  values = [replace(file("${local.gitops_dir}/platform/observability/loki/values.yaml"), "<AWS_ACCOUNT_ID>", var.aws_account_id)]

  depends_on = [
    kubernetes_storage_class_v1.gp3,
    module.loki_pod_identity,
  ]
}

resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = "10.5.15"
  namespace        = kubernetes_namespace_v1.monitoring.metadata[0].name
  create_namespace = false

  wait    = true
  atomic  = true
  timeout = 900

  values = [replace(file("${local.gitops_dir}/platform/observability/grafana/values.yaml"), "<AWS_ACCOUNT_ID>", var.aws_account_id)]

  depends_on = [
    kubernetes_storage_class_v1.gp3,
    helm_release.mimir,
    helm_release.loki,
  ]
}
