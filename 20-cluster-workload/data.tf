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

data "terraform_remote_state" "cluster_observability" {
  backend = "s3"

  config = {
    bucket  = "eks-tfstate-${var.account_id}"
    key     = "cluster-observability/terraform.tfstate"
    region  = "ap-southeast-1"
    profile = var.aws_profile
  }
}
