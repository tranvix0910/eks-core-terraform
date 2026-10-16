# Read by layers 20/21 via terraform_remote_state - do not rename

output "region_name" {
  value = data.aws_region.current.region
}

output "account_id" {
  value = local.account_id
}

output "vpc_id" {
  description = "Shared VPC hosting both clusters"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "azs" {
  value = var.azs
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "workload_node_subnet_ids" {
  description = "Node subnets for the workload cluster"
  value       = local.workload_subnet_ids
}

output "observability_node_subnet_ids" {
  description = "Node subnets for the observability cluster"
  value       = local.observability_subnet_ids
}

output "nat_gateway_ids" {
  value = module.vpc.natgw_ids
}

output "s3_vpc_endpoint_id" {
  value = module.vpc_endpoints.endpoints["s3"].id
}

output "cluster_names" {
  description = "Canonical cluster names, also used as karpenter.sh/discovery tag values"
  value       = var.cluster_names
}
