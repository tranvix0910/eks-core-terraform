# Subnet tags for cluster auto-discovery.
#
# These are applied outside the VPC module on purpose. The module's
# private_subnet_tags input applies one uniform tag set to every private subnet,
# but the two clusters share this VPC and need DIFFERENT karpenter.sh/discovery
# values. Same value on both would make Karpenter in one cluster discover the
# other cluster's subnets and launch nodes into them.
#
# Ordering note: module.vpc.private_subnets follows the order of the
# private_subnets input, so the first three are the workload subnets and the
# next three the observability ones. Same assumption as outputs.tf.

locals {
  # Plain lists, for reading and for outputs. Nothing uses these as for_each
  # keys, so an apply-time value is fine here.
  workload_subnet_ids = slice(
    module.vpc.private_subnets,
    0,
    length(local.workload_node_subnets),
  )

  observability_subnet_ids = slice(
    module.vpc.private_subnets,
    length(local.workload_node_subnets),
    length(local.workload_node_subnets) + length(local.observability_node_subnets),
  )

  # The same subnets, keyed by CIDR, for for_each.
  #
  # for_each cannot take a set of subnet ids. The ids do not exist until the VPC
  # is created, so on a first apply terraform cannot know which instance keys
  # will exist and refuses to plan:
  #
  #   Error: Invalid for_each argument
  #   The "for_each" set includes values derived from resource attributes that
  #   cannot be determined until apply
  #
  # A map avoids it because only the VALUES are apply-time. The KEYS come from
  # local.*_subnets in locals.tf, which are literal CIDR strings in config and
  # therefore known before anything is created.
  #
  # Keying by CIDR rather than by index also keeps resource addresses stable:
  #   aws_ec2_tag.workload_subnet_discovery["10.20.16.0/20"]
  # Inserting or reordering a subnet then touches only its own tag, whereas
  # index keys would shift every subsequent element and re-tag subnets that did
  # not change.
  workload_subnets_by_cidr = {
    for idx, cidr in local.workload_node_subnets :
    cidr => module.vpc.private_subnets[idx]
  }

  observability_subnets_by_cidr = {
    for idx, cidr in local.observability_node_subnets :
    cidr => module.vpc.private_subnets[idx + length(local.workload_node_subnets)]
  }

  public_subnets_by_cidr = {
    for idx, cidr in local.public_subnets :
    cidr => module.vpc.public_subnets[idx]
  }

  # Safe to merge: CIDRs are unique within a VPC, so no key can collide.
  private_subnets_by_cidr = merge(
    local.workload_subnets_by_cidr,
    local.observability_subnets_by_cidr,
  )
}

# --- Karpenter subnet discovery, one value per cluster ---

resource "aws_ec2_tag" "workload_subnet_discovery" {
  for_each    = local.workload_subnets_by_cidr
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = local.clusters.workload
}

resource "aws_ec2_tag" "observability_subnet_discovery" {
  for_each    = local.observability_subnets_by_cidr
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = local.clusters.observability
}

# --- Load balancer subnet discovery ---
# Private subnets host internal load balancers, public subnets host
# internet-facing ones. The AWS Load Balancer Controller looks for these.
# Public subnets are shared by both clusters, which is fine.

resource "aws_ec2_tag" "private_internal_elb" {
  for_each    = local.private_subnets_by_cidr
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_elb" {
  for_each    = local.public_subnets_by_cidr
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

# --- Cluster ownership ---
# "shared" rather than "owned": these subnets are not exclusive to one cluster,
# and the tag must never cause one cluster's teardown to disown another's subnet.

resource "aws_ec2_tag" "workload_cluster" {
  for_each    = merge(local.workload_subnets_by_cidr, local.public_subnets_by_cidr)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.clusters.workload}"
  value       = "shared"
}

resource "aws_ec2_tag" "observability_cluster" {
  for_each    = merge(local.observability_subnets_by_cidr, local.public_subnets_by_cidr)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.clusters.observability}"
  value       = "shared"
}
