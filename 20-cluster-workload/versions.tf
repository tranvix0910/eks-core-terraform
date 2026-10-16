terraform {
  # >= 1.10 is a hard floor: backend.tf uses use_lockfile for S3-native state
  # locking, which does not exist in 1.9.
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 6.x required by terraform-aws-modules/vpc v6 (>= 6.28) and by the
      # EKS module v21. Keep every stack on the same major.
      version = "~> 6.28"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
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

}

# module.cluster, not module.eks.
#
# The EKS module was wrapped in ./modules/eks_cluster (see the moved block in
# main.tf), so module.eks no longer exists at this level. Nothing caught it
# because no resource uses this provider yet - terraform evaluates a provider
# configuration only when something needs it - so the first helm_release added
# here would have failed with "Reference to undeclared module".
provider "helm" {
  kubernetes = {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks", "get-token",
        "--cluster-name", module.cluster.cluster_name,
        "--region", local.region,
        "--profile", var.aws_profile,
      ]
    }
  }
}

provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", module.cluster.cluster_name,
      "--region", local.region,
      "--profile", var.aws_profile,
    ]
  }
}
