locals {
  ### GENERAL
  name       = data.terraform_remote_state.network.outputs.cluster_names["observability"]
  account_id = data.aws_caller_identity.current.account_id

  ### NETWORK (layer 10)
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr        = data.terraform_remote_state.network.outputs.vpc_cidr
  node_subnet_ids = data.terraform_remote_state.network.outputs.observability_node_subnet_ids

  ### LAYER 20
  workload_node_security_group_id = data.terraform_remote_state.cluster_workload.outputs.node_security_group_id

  eks_get_token_args = concat(
    ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region],
    var.aws_profile == null ? [] : ["--profile", var.aws_profile],
  )

  ### S3 - bucket names are hardcoded in gitops mimir/loki values
  s3_buckets = {
    mimir = "${local.name}-mimir-${local.account_id}"
    loki  = "${local.name}-loki-${local.account_id}"
  }

  ### EKS ADDONS
  eks_cluster_addons = {
    coredns    = {}
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
  }
}
