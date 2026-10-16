variable "environment" {
  description = "Deployment environment. Drives naming and tagging."
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "environment must be one of: dev, uat, prod."
  }
}

variable "aws_profile" {
  description = <<-EOT
    Named profile from ~/.aws/config used by the aws provider. Must resolve to
    var.aws_account_id, the account that owns the state bucket and the VPC.

    Defaulted so the profile lives in code and matches the profile in
    backend.hcl. Set to null to fall back to the default credential chain
    (AWS_PROFILE, static env vars, instance/container role) - CI has no
    ~/.aws/config, so pass -var aws_profile= or TF_VAR_aws_profile= there.

    This covers the provider only. The S3 backend resolves credentials
    separately and cannot read variables - see backend.tf.
  EOT
  type        = string
  default     = "eks-core"
}

variable "internal_observability_alb_name" {
  description = <<-EOT
    Name of the internal ALB created by the AWS Load Balancer Controller for
    Mimir and Loki. Leave null during the first apply: the controller cannot
    create the ALB until its Helm release and Ingress objects already exist.
    Set the discovered name and apply again to create Route 53 alias records.
  EOT
  type        = string
  default     = null
  nullable    = true
}

variable "aws_account_id" {
  description = <<-EOT
    AWS account that owns the state bucket and the VPC. The provider refuses
    to run against any other account. Set it in account.auto.tfvars
    (gitignored, see account.auto.tfvars.example).
  EOT
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
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
