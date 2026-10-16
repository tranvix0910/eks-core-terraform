locals {
  name = "eks-lab"

  region = "ap-northeast-1"

  azs = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]

  vpc_cidr = "10.20.0.0/16"

  public_subnets = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]

  workload_node_subnets      = ["10.20.16.0/20", "10.20.32.0/20", "10.20.48.0/20"]
  observability_node_subnets = ["10.20.64.0/20", "10.20.80.0/20", "10.20.96.0/20"]

  clusters = {
    workload      = "eks-workload"
    observability = "eks-observability"
  }

  tags = {
    Project     = "eks-core"
    Owner       = "tranvix0910"
    ManagedBy   = "terraform"
    Environment = var.environment
  }
}
