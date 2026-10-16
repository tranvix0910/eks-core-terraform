locals {
  name   = "eks-workload"
  region = "ap-northeast-1"

  kubernetes_version = "1.34"

  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr        = data.terraform_remote_state.network.outputs.vpc_cidr
  azs             = data.terraform_remote_state.network.outputs.azs
  node_subnet_ids = data.terraform_remote_state.network.outputs.workload_node_subnet_ids

  infra_instance_types = ["t3.large"]
  infra_capacity_type  = "ON_DEMAND"
  infra_desired_size   = 3

  # Cluster observability is applied after this stack because it consumes this
  # stack's node security-group output. Its state is therefore legitimately
  # empty during the first workload apply. The Rancher cross-cluster rule is
  # added on the next workload apply once the output exists.
  observability_node_security_group_id = try(
    data.terraform_remote_state.cluster_observability.outputs.node_security_group_id,
    null,
  )

  tags = {
    Project     = "eks-core"
    Owner       = "tranvix0910"
    ManagedBy   = "terraform"
    Layer       = "20-cluster-workload"
    Environment = var.environment
  }
}
