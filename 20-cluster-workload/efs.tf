# Shared file system for ReadWriteMany PVCs (EBS gp3 is ReadWriteOnce only)
module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 2.0"

  create         = var.efs_create
  name           = "${local.name}-efs"
  creation_token = local.name

  encrypted       = true
  throughput_mode = "elastic"

  lifecycle_policy = {
    transition_to_ia = var.efs_transition_to_ia
  }

  # One mount target per AZ
  mount_targets = { for idx, subnet_id in local.node_subnet_ids : "az-${idx}" => { subnet_id = subnet_id } }

  security_group_name        = "${local.name}-efs"
  security_group_description = "NFS from the ${local.name} cluster nodes to EFS mount targets"
  security_group_vpc_id      = local.vpc_id
  security_group_ingress_rules = {
    nodes = {
      description                  = "NFS from cluster nodes"
      referenced_security_group_id = module.eks.node_security_group_id
    }
  }

  attach_policy        = false
  enable_backup_policy = false

  tags = var.tags
}
