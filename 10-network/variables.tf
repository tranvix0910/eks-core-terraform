# ---------------------------------------------------------------
# General
# ---------------------------------------------------------------
variable "region" {
  type        = string
  description = "AWS region hosting the VPC"
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
# VPC
# ---------------------------------------------------------------
variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the shared VPC"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones, one subnet of each tier per AZ"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDRs (NAT Gateway, internet-facing load balancers), same order as azs"
}

variable "workload_subnets" {
  type        = list(string)
  description = "Private node subnet CIDRs for the workload cluster, same order as azs"
}

variable "observability_subnets" {
  type        = list(string)
  description = "Private node subnet CIDRs for the observability cluster, same order as azs"
}

variable "single_nat_gateway" {
  type        = bool
  description = "One NAT Gateway shared by all AZs (cheap). Set false for one NAT Gateway per AZ"
  default     = true
}

variable "enable_flow_log" {
  type        = bool
  description = "Enable VPC flow logs to CloudWatch Logs"
  default     = true
}

# ---------------------------------------------------------------
# EKS
# ---------------------------------------------------------------
variable "cluster_names" {
  type        = map(string)
  description = "Cluster names keyed by role (workload, observability). Also used as karpenter.sh/discovery tag values"

  validation {
    condition     = alltrue([for k in ["workload", "observability"] : contains(keys(var.cluster_names), k)])
    error_message = "cluster_names must contain the keys workload and observability."
  }
}
