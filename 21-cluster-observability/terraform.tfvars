region      = "ap-northeast-1"
aws_profile = "vitrandai-vib"

env     = "dev"
project = "eks"

# ---------------------------------------------------------------
# EKS Variable Zone
# ---------------------------------------------------------------
eks_kubernetes_version                     = "1.34"
eks_endpoint_public_access                 = true
eks_enabled_log_types                      = ["api", "audit", "authenticator"]
eks_cloudwatch_log_group_retention_in_days = 7

# ---------------------------------------------------------------
# EKS Node Group Variable Zone
# ---------------------------------------------------------------
eks_nodegroup_instance_types = ["t3.medium"]
eks_nodegroup_capacity_type  = "ON_DEMAND"
eks_nodegroup_ami_type       = "AL2023_x86_64_STANDARD"
eks_nodegroup_desired_size   = 2
eks_nodegroup_min_size       = 2
eks_nodegroup_max_size       = 3

# ---------------------------------------------------------------
# S3 Variable Zone
# ---------------------------------------------------------------
s3_expiration_days = 30

# ---------------------------------------------------------------
# Route53 Variable Zone
# ---------------------------------------------------------------
route53_private_zone_name       = "observability.internal"
internal_observability_alb_name = null

# ---------------------------------------------------------------
# Tags Zone
# ---------------------------------------------------------------
tags = {
  "project"    = "eks"
  "env"        = "dev"
  "owner"      = "vi.trandai"
  "managed_by" = "terraform"
}
