terraform {
  # >= 1.10 is a hard floor: backend.tf uses use_lockfile for S3-native state
  # locking, which does not exist in 1.9.
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 6.x required by terraform-aws-modules/vpc v6 (>= 6.28) and by the
      # EKS module v21 used in 20-cluster-*. Keep every stack on the same major.
      version = "~> 6.28"
    }
  }
}

provider "aws" {
  region              = local.region
  profile             = var.aws_profile
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = local.tags
  }

  ignore_tags {
    key_prefixes = ["kubernetes.io/", "karpenter.sh/"]
  }

}
