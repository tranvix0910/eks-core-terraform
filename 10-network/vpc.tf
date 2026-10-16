# Shared by both clusters
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = "${local.prefix}-vpc"
  cidr = var.vpc_cidr
  azs  = var.azs

  public_subnets       = var.public_subnets
  public_subnet_names  = local.public_subnet_names
  private_subnets      = concat(var.workload_subnets, var.observability_subnets)
  private_subnet_names = concat(local.workload_subnet_names, local.observability_subnet_names)

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_flow_log                                 = var.enable_flow_log
  create_flow_log_cloudwatch_log_group            = var.enable_flow_log
  create_flow_log_cloudwatch_iam_role             = var.enable_flow_log
  flow_log_cloudwatch_log_group_retention_in_days = local.flowlogs_retention_days

  tags = var.tags
}
