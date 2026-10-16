module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  enabled_log_types = var.enabled_log_types

  addons = {
    coredns = {
      configuration_values = jsonencode({
        tolerations = [{
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }]
      })
    }

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
      configuration_values = jsonencode({
        env = var.enable_prefix_delegation ? {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        } : {}
      })
    }

    eks-pod-identity-agent = {
      before_compute = true
    }

    aws-ebs-csi-driver = {}

    aws-efs-csi-driver = {
      resolve_conflicts_on_create = "OVERWRITE"
    }
  }

  eks_managed_node_groups = var.node_groups

  node_security_group_tags = var.enable_karpenter_discovery ? {
    "karpenter.sh/discovery" = var.name
  } : {}

  node_security_group_additional_rules = merge(
    var.enable_efs_egress ? {
      egress_nfs = {
        description = "NFS to EFS mount targets"
        protocol    = "tcp"
        from_port   = 2049
        to_port     = 2049
        type        = "egress"
        cidr_blocks = [var.vpc_cidr]
      }
    } : {},
    {
      for port in var.extension_apiserver_ports : "ingress_extension_apiserver_${port}" => {
        description                   = "Control plane to extension apiserver on ${port}"
        protocol                      = "tcp"
        from_port                     = port
        to_port                       = port
        type                          = "ingress"
        source_cluster_security_group = true
      }
    }
  )

  tags = var.tags
}
