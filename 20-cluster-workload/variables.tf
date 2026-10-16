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

variable "eks_extension_apiserver_ports" {
  type        = list(number)
  description = "Extra ports nodes accept from the control plane for aggregated APIServices (e.g. Rancher 6666)"
  default     = []
}

# ---------------------------------------------------------------
# EKS Node Group
# ---------------------------------------------------------------
variable "eks_nodegroup_instance_types" {
  type        = list(string)
  description = "Instance types of the infra node group"
}

variable "eks_nodegroup_capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT"
  default     = "ON_DEMAND"
}

variable "eks_nodegroup_ami_type" {
  type        = string
  description = "AMI type of the infra node group"
  default     = "AL2023_x86_64_STANDARD"
}

variable "eks_nodegroup_desired_size" {
  type        = number
  description = "Desired number of infra nodes"
}

variable "eks_nodegroup_min_size" {
  type        = number
  description = "Minimum number of infra nodes"
}

variable "eks_nodegroup_max_size" {
  type        = number
  description = "Maximum number of infra nodes"
}

# ---------------------------------------------------------------
# ECR
# ---------------------------------------------------------------
variable "ecr_repository_names" {
  type        = list(string)
  description = "ECR repositories to create. Empty list creates none"
  default     = []
}

variable "ecr_image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the ECR repositories"
  default     = "MUTABLE"
}

variable "ecr_lifecycle_policy_image_count" {
  type        = number
  description = "Number of images to keep per repository"
  default     = 10
}

# ---------------------------------------------------------------
# EFS
# ---------------------------------------------------------------
variable "efs_create" {
  type        = bool
  description = "Create the shared EFS file system and its efs-sc StorageClass"
  default     = false
}

variable "efs_transition_to_ia" {
  type        = string
  description = "Move files to Infrequent Access after this long untouched"
  default     = "AFTER_30_DAYS"
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
