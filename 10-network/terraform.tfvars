region      = "ap-northeast-1"
aws_profile = "eks-core"

env     = "dev"
project = "eks"

# ---------------------------------------------------------------
# VPC Variable Zone
# ---------------------------------------------------------------
vpc_cidr = "10.20.0.0/16"
azs      = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]

public_subnets        = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
workload_subnets      = ["10.20.16.0/20", "10.20.32.0/20", "10.20.48.0/20"]
observability_subnets = ["10.20.64.0/20", "10.20.80.0/20", "10.20.96.0/20"]

single_nat_gateway = true
enable_flow_log    = true

# ---------------------------------------------------------------
# EKS Variable Zone
# ---------------------------------------------------------------
cluster_names = {
  workload      = "eks-workload"
  observability = "eks-observability"
}

# ---------------------------------------------------------------
# Tags Zone
# ---------------------------------------------------------------
tags = {
  "project"    = "eks"
  "env"        = "dev"
  "owner"      = "vi.trandai"
  "managed_by" = "terraform"
}
