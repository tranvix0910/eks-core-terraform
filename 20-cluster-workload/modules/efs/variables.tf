variable "name" {
  description = "Prefix for the creation token, the security group and the Name tag."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = <<-EOT
    Subnets to place mount targets in - the same node subnets the cluster uses.

    One per AZ. EFS rejects a second mount target in an AZ that already has one.
  EOT
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Cluster node security group, the only source allowed to mount."
  type        = string
}

variable "transition_to_ia" {
  description = "Move a file to Infrequent Access after this long untouched. AFTER_1_DAY is the cheapest for data nothing reads."
  type        = string
  default     = "AFTER_30_DAYS"
}

variable "tags" {
  type    = map(string)
  default = {}
}
