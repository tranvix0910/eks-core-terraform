# Helm values come from the eks-core-gitops repository, cloned next to this one
# (see var.gitops_repo_path). Account-specific placeholders in those files are
# filled in here so the committed manifests stay free of account IDs.
locals {
  gitops_dir = "${path.module}/../${var.gitops_repo_path}"
}

# Terraform owns these charts; GitOps only keeps the Ingress and dashboard manifests

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [module.eks]
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
    clusterName = module.eks.cluster_name
    region      = var.region
    vpcId       = local.vpc_id
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
    }
    nodeSelector      = { role = "monitoring" }
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

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "88.6.2"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  skip_crds = false
  wait      = true
  atomic    = true
  timeout   = 900

  values = [replace(file("${local.gitops_dir}/platform/observability/prometheus/values.yaml"), "<AWS_ACCOUNT_ID>", var.account_id)]

  depends_on = [
    kubernetes_storage_class_v1.gp3,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "helm_release" "mimir" {
  name       = "mimir"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "mimir-distributed"
  version    = "6.1.0"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  wait    = true
  atomic  = true
  timeout = 1800

  values = [replace(file("${local.gitops_dir}/platform/observability/mimir/values.yaml"), "<AWS_ACCOUNT_ID>", var.account_id)]

  depends_on = [
    kubernetes_storage_class_v1.gp3,
    module.s3_pod_identity,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "7.3.0"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  wait    = true
  atomic  = true
  timeout = 900

  values = [replace(file("${local.gitops_dir}/platform/observability/loki/values.yaml"), "<AWS_ACCOUNT_ID>", var.account_id)]

  depends_on = [
    kubernetes_storage_class_v1.gp3,
    module.s3_pod_identity,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "kubernetes_config_map_v1" "enterprise_workload_dashboard" {
  metadata {
    name      = "enterprise-workload-dashboard"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    "enterprise-workload-360.json" = file("${local.gitops_dir}/platform/observability/grafana/dashboards/enterprise-workload-360.json")
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "10.5.15"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  wait    = true
  atomic  = true
  timeout = 900

  values = [replace(file("${local.gitops_dir}/platform/observability/grafana/values.yaml"), "<AWS_ACCOUNT_ID>", var.account_id)]

  depends_on = [
    helm_release.mimir,
    helm_release.loki,
    kubernetes_config_map_v1.enterprise_workload_dashboard,
  ]
}
