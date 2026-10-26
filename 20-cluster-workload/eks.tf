module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name
  kubernetes_version = var.eks_kubernetes_version

  vpc_id     = local.vpc_id
  subnet_ids = local.node_subnet_ids

  endpoint_public_access  = var.eks_endpoint_public_access
  endpoint_private_access = true

  enabled_log_types                      = var.eks_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.eks_cloudwatch_log_group_retention_in_days

  enable_cluster_creator_admin_permissions = true

  addons = local.eks_cluster_addons

  # Node groups stay inside the module so non-before_compute addons (coredns) wait for nodes
  eks_managed_node_groups = {
    infra = {
      ami_type       = var.eks_nodegroup_ami_type
      instance_types = var.eks_nodegroup_instance_types
      capacity_type  = var.eks_nodegroup_capacity_type

      min_size     = var.eks_nodegroup_min_size
      max_size     = var.eks_nodegroup_max_size
      desired_size = var.eks_nodegroup_desired_size

      labels = { role = "infra" }

      # Keep application Pods off the platform nodes; every platform chart
      # already tolerates this taint (local.critical_addons_toleration).
      taints = {
        critical_addons_only = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.name
  }

  node_security_group_additional_rules = merge(
    {
      egress_nfs = {
        description = "NFS to EFS mount targets"
        protocol    = "tcp"
        from_port   = 2049
        to_port     = 2049
        type        = "egress"
        cidr_blocks = [local.vpc_cidr]
      }
    },
    {
      for port in var.eks_extension_apiserver_ports : "ingress_extension_apiserver_${port}" => {
        description                   = "Control plane to extension apiserver on ${port}"
        protocol                      = "tcp"
        from_port                     = port
        to_port                       = port
        type                          = "ingress"
        source_cluster_security_group = true
      }
    },
  )

  tags = var.tags
}
