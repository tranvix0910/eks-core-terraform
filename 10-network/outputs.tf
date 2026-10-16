output "vpc_id" {
  description = "Shared VPC hosting both clusters"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "azs" {
  value = local.azs
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "workload_node_subnet_ids" {
  description = "Node subnets for cluster eks-workload"
  value       = slice(module.vpc.private_subnets, 0, 3)
}

output "observability_node_subnet_ids" {
  description = "Node subnets for cluster eks-observability"
  value       = slice(module.vpc.private_subnets, 3, 6)
}

output "nat_gateway_ids" {
  value = module.vpc.natgw_ids
}

output "cluster_names" {
  description = "Canonical cluster names, also used as karpenter.sh/discovery tag values"
  value       = local.clusters
}
