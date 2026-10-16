locals {
  name   = "eks-observability"
  region = "ap-northeast-1"

  kubernetes_version = "1.34"

  # From layer 10. Never hardcode a subnet id or CIDR that already exists as
  # an output there - see terraform/10-network/outputs.tf.
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr        = data.terraform_remote_state.network.outputs.vpc_cidr
  node_subnet_ids = data.terraform_remote_state.network.outputs.observability_node_subnet_ids

  # From layer 20. Needed for the one cross-cluster piece Terraform owns: a
  # security group rule letting cluster 1's nodes reach cluster 2's internal
  # ALB (Mimir remote_write, Loki push). Everything past that rule - the
  # Ingress objects, the Helm values pointing at the ALB DNS name - is
  # GitOps/kubectl, same split as everywhere else in this project.
  workload_node_security_group_id = data.terraform_remote_state.cluster_workload.outputs.node_security_group_id

  # Lab sizing. This node group runs Mimir + Loki + Grafana - three Java/Go
  # processes each holding an in-memory index and a handful of goroutines/
  # threads, not a fleet of user-facing services. 2 nodes rather than 1 for
  # the same reason cluster 1's infra group is not 1: losing the only node to
  # an AZ issue or a node upgrade would take down every observability tool at
  # once, including the ability to see why.
  monitoring_instance_types = ["t3.medium"]
  monitoring_desired_size   = 2

  tags = {
    Project     = "eks-core"
    Owner       = "tranvix0910"
    ManagedBy   = "terraform"
    Layer       = "21-cluster-observability"
    Environment = var.environment
  }
}
