# ---------------------------------------------------------------
# General
# ---------------------------------------------------------------
variable "region" {
  type        = string
  description = "AWS region hosting the cluster"
}

variable "aws_profile" {
  type        = string
  description = "Named profile in ~/.aws/config. Set to null in CI to use the default credential chain"
  default     = null
}

variable "account_id" {
  type        = string
  description = "The only AWS account this stack is allowed to run against"
}

variable "env" {
  type        = string
  description = "The current environment"

  validation {
    condition     = contains(["dev", "nprod", "uat", "prod"], var.env)
    error_message = "env must be one of: dev, nprod, uat, prod."
  }
}

variable "project" {
  type        = string
  description = "The project"
}

variable "tags" {
  type        = map(string)
  description = "List of required tags"
}

# ---------------------------------------------------------------
# EKS
# ---------------------------------------------------------------
variable "eks_kubernetes_version" {
  type        = string
  description = "Kubernetes version of the EKS cluster"
}

variable "eks_endpoint_public_access" {
  type        = bool
  description = "Enable public access to the cluster endpoint"
  default     = true
}

variable "eks_enabled_log_types" {
  type        = list(string)
  description = "Control plane log types to enable"
  default     = ["api", "audit", "authenticator"]
}

variable "eks_cloudwatch_log_group_retention_in_days" {
  type        = number
  description = "Retention of the control plane log group"
  default     = 7
}

# ---------------------------------------------------------------
# EKS Node Group
# ---------------------------------------------------------------
variable "eks_nodegroup_instance_types" {
  type        = list(string)
  description = "Instance types of the monitoring node group"
}

variable "eks_nodegroup_capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT"
  default     = "ON_DEMAND"
}

variable "eks_nodegroup_ami_type" {
  type        = string
  description = "AMI type of the monitoring node group"
  default     = "AL2023_x86_64_STANDARD"
}

variable "eks_nodegroup_desired_size" {
  type        = number
  description = "Desired number of monitoring nodes"
}

variable "eks_nodegroup_min_size" {
  type        = number
  description = "Minimum number of monitoring nodes"
}

variable "eks_nodegroup_max_size" {
  type        = number
  description = "Maximum number of monitoring nodes"
}

# ---------------------------------------------------------------
# S3
# ---------------------------------------------------------------
variable "s3_expiration_days" {
  type        = number
  description = "Days before Mimir blocks / Loki chunks are expired"
  default     = 30
}

# ---------------------------------------------------------------
# Route53
# ---------------------------------------------------------------
variable "route53_private_zone_name" {
  type        = string
  description = "Private hosted zone for the Mimir/Loki endpoints"
  default     = "observability.internal"
}

variable "internal_observability_alb_name" {
  type        = string
  description = "Internal ALB created by the LB controller for Mimir/Loki. Leave null on the first apply"
  default     = null
  nullable    = true
}

variable "gitops_repo_path" {
  description = <<-EOT
    Path to a local clone of eks-core-gitops, relative to the root of this
    repository. The Helm releases here read their values files from it.
    Defaults to a sibling clone (../eks-core-gitops).
  EOT
  type        = string
  default     = "../eks-core-gitops"
}
