# aws_ec2_tag instead of module tags: each cluster needs its own karpenter.sh/discovery value

# ---------------------------------------------------------------
# Karpenter discovery
# ---------------------------------------------------------------
resource "aws_ec2_tag" "workload_subnet_discovery" {
  for_each    = local.workload_subnets_by_cidr
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_names["workload"]
}

resource "aws_ec2_tag" "observability_subnet_discovery" {
  for_each    = local.observability_subnets_by_cidr
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_names["observability"]
}

# ---------------------------------------------------------------
# Load balancer discovery
# ---------------------------------------------------------------
resource "aws_ec2_tag" "private_internal_elb" {
  for_each    = local.private_subnets_by_cidr
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_elb" {
  for_each    = local.public_subnets_by_cidr
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

# ---------------------------------------------------------------
# Cluster ownership
# ---------------------------------------------------------------
resource "aws_ec2_tag" "workload_cluster" {
  for_each    = merge(local.workload_subnets_by_cidr, local.public_subnets_by_cidr)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_names["workload"]}"
  value       = "shared"
}

resource "aws_ec2_tag" "observability_cluster" {
  for_each    = merge(local.observability_subnets_by_cidr, local.public_subnets_by_cidr)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_names["observability"]}"
  value       = "shared"
}
