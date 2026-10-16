# VPC shared by both clusters.
#
# Decision record: docs/decisions/0002-single-vpc-for-both-clusters.md
#
# Three NAT Gateways, one per AZ, shared by both clusters. This is where the
# saving over a two-VPC design comes from: 3 NAT Gateways instead of 6, and
# 3 Elastic IPs instead of 6.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = local.name
  cidr = local.vpc_cidr
  azs  = local.azs

  public_subnets  = local.public_subnets
  private_subnets = concat(local.workload_node_subnets, local.observability_node_subnets)

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_retention_in_days = 3

  tags = local.tags
}
