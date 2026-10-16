variable "name" {
  description = "Cluster name. Also the value of the karpenter.sh/discovery tag when discovery is enabled."
  type        = string
}

variable "kubernetes_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  description = "Used for the NFS egress rule when enable_efs_egress is set."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the control plane ENIs and the node groups."
  type        = list(string)
}

variable "node_groups" {
  description = <<-EOT
    Managed node groups, keyed by name. Pass {} for a control-plane-only cluster.

    Each entry:
      instance_types  list(string)
      capacity_type   "ON_DEMAND" | "SPOT"
      min_size        number
      max_size        number
      desired_size    number
      labels          map(string)
      taints          map(object({ key, value, effect }))
  EOT
  type        = any
  default     = {}
}

variable "enable_prefix_delegation" {
  description = <<-EOT
    Give each ENI slot a /28 instead of a single IP. Multiplies pods per node
    without the ~30% node capacity loss that VPC CNI custom networking costs.
  EOT
  type        = bool
  default     = true
}

variable "enable_karpenter_discovery" {
  description = <<-EOT
    Tag the node security group with karpenter.sh/discovery = var.name.

    Both clusters share one VPC, so the value must be cluster-specific. The same
    value on two clusters lets one cluster's Karpenter attach the other's
    security group.

    Leave false on clusters that do not run Karpenter.
  EOT
  type        = bool
  default     = false
}

variable "enable_efs_egress" {
  description = <<-EOT
    Allow the nodes to reach EFS mount targets on TCP 2049.

    Set this when the cluster is created, not later: adding the rule afterwards
    forces a change on every node in the group.
  EOT
  type        = bool
  default     = false
}

variable "extension_apiserver_ports" {
  description = <<-EOT
    Extra ports the node security group must accept from the cluster security
    group, on top of the module's own webhook-port defaults (443, 4443, 6443,
    8443, 9443, 10250, 10251).

    Anything that registers a Kubernetes APIService (an aggregated / extension
    apiserver) needs the control plane to reach its pod directly on whatever
    port it serves. Miss this and discovery just times out - for most
    extensions that is a degraded feature, but at least one real case in this
    project (Rancher's imperative API, port 6666) treats that timeout as fatal
    and crash-loops the whole pod instead of starting up without it.
  EOT
  type        = list(number)
  default     = []
}

variable "endpoint_public_access" {
  description = "Lab default is true so kubectl works without a bastion. Narrow public_access_cidrs for anything real."
  type        = bool
  default     = true
}

variable "enabled_log_types" {
  type    = list(string)
  default = ["api", "audit", "authenticator"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
