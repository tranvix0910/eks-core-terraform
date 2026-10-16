provider "aws" {
  region              = var.region
  profile             = var.aws_profile
  allowed_account_ids = [var.account_id]

  ignore_tags {
    key_prefixes = ["kubernetes.io/", "karpenter.sh/"]
  }
}

terraform {
  required_version = ">= 1.10, < 2.0"

  # Partial config: bucket and profile come from backend.hcl (gitignored).
  #   terraform init -backend-config=backend.hcl
  backend "s3" {
    key          = "network/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28"
    }
  }
}
