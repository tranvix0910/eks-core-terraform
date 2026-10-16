locals {
  ### GENERAL
  # Cluster name comes from layer 10 - it is also the karpenter.sh/discovery tag value
  name       = data.terraform_remote_state.network.outputs.cluster_names["workload"]
  account_id = data.aws_caller_identity.current.account_id

  ### NETWORK (layer 10)
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr        = data.terraform_remote_state.network.outputs.vpc_cidr
  node_subnet_ids = data.terraform_remote_state.network.outputs.workload_node_subnet_ids

  ### LAYER 21
  observability_node_security_group_id = try(
    data.terraform_remote_state.cluster_observability.outputs.node_security_group_id,
    null,
  )

  eks_get_token_args = concat(
    ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region],
    var.aws_profile == null ? [] : ["--profile", var.aws_profile],
  )

  ### EKS ADDONS
  critical_addons_toleration = [{
    key      = "CriticalAddonsOnly"
    operator = "Exists"
    effect   = "NoSchedule"
  }]

  eks_cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        tolerations = local.critical_addons_toleration
      })
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    aws-ebs-csi-driver = {}
    aws-efs-csi-driver = {
      resolve_conflicts_on_create = "OVERWRITE"
    }
  }
}
