locals {
  ### GENERAL
  region_short            = lookup({ "ap-southeast-1" = "sg", "ap-northeast-1" = "jp" }, var.region, var.region)
  prefix                  = "aws-${local.region_short}-${var.project}-${var.env}"
  flowlogs_retention_days = var.env == "prod" ? 30 : 3
  account_id              = data.aws_caller_identity.current.account_id

  ### SUBNET NAMES
  az_suffix                  = [for az in var.azs : substr(az, -1, 1)]
  public_subnet_names        = [for s in local.az_suffix : "${local.prefix}-public-subnet-${s}"]
  workload_subnet_names      = [for s in local.az_suffix : "${local.prefix}-workload-subnet-${s}"]
  observability_subnet_names = [for s in local.az_suffix : "${local.prefix}-observability-subnet-${s}"]
}

locals {
  ### SUBNET ID MAPS
  # private_subnets order: workload first, then observability
  workload_subnet_ids = slice(module.vpc.private_subnets, 0, length(var.workload_subnets))
  observability_subnet_ids = slice(
    module.vpc.private_subnets,
    length(var.workload_subnets),
    length(var.workload_subnets) + length(var.observability_subnets),
  )

  # Keyed by CIDR so for_each keys are known at plan time
  workload_subnets_by_cidr = {
    for idx, cidr in var.workload_subnets : cidr => module.vpc.private_subnets[idx]
  }
  observability_subnets_by_cidr = {
    for idx, cidr in var.observability_subnets : cidr => module.vpc.private_subnets[idx + length(var.workload_subnets)]
  }
  public_subnets_by_cidr = {
    for idx, cidr in var.public_subnets : cidr => module.vpc.public_subnets[idx]
  }
  private_subnets_by_cidr = merge(local.workload_subnets_by_cidr, local.observability_subnets_by_cidr)
}
