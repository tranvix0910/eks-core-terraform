data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket  = "eks-tfstate-${var.account_id}"
    key     = "network/terraform.tfstate"
    region  = "ap-southeast-1"
    profile = var.aws_profile
  }
}

data "terraform_remote_state" "cluster_workload" {
  backend = "s3"

  config = {
    bucket  = "eks-tfstate-${var.account_id}"
    key     = "cluster-workload/terraform.tfstate"
    region  = "ap-southeast-1"
    profile = var.aws_profile
  }
}

# Set var.internal_observability_alb_name after the LB controller has created the ALB
data "aws_lb" "observability_internal" {
  count = var.internal_observability_alb_name == null ? 0 : 1
  name  = var.internal_observability_alb_name
}
