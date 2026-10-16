# EFS file system for ReadWriteMany volumes.
#
# EBS cannot back a ReadWriteMany PVC: a gp3 volume attaches to exactly one node,
# so the second pod of a Deployment scheduled elsewhere sits Pending on
# "Multi-Attach error". Any volume shared by more than one replica has to be EFS.
#
# Only the file system, its security group and the mount targets live here. IAM
# for the CSI controller stays in the calling stack next to ebs_csi_pod_identity
# and lb_controller_pod_identity, so there is one place to look for permissions.

resource "aws_efs_file_system" "this" {
  creation_token = var.name

  encrypted = true

  # Elastic bills per GB read/written and needs no provisioned number. Bursting
  # ties throughput to stored size, and a near-empty file system - which is what
  # this is - gets throttled to the 1 MiB/s floor once its burst credits run out.
  throughput_mode = "elastic"

  lifecycle_policy {
    transition_to_ia = var.transition_to_ia
  }

  tags = merge(var.tags, { Name = var.name })
}

# Nodes reach EFS over NFS on 2049. The matching egress rule on the node
# security group is enable_efs_egress in modules/eks_cluster.
resource "aws_security_group" "this" {
  name        = "${var.name}-efs"
  description = "NFS from the ${var.name} cluster nodes to EFS mount targets"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-efs" })

  # The mount targets reference this group; replacing it in place would fail.
  lifecycle {
    create_before_destroy = true
  }
}

# Sourced from the node security group, not the VPC CIDR. The CIDR would also
# admit anything else in the VPC - the second cluster, an ad-hoc EC2 instance -
# which is not the intent.
resource "aws_vpc_security_group_ingress_rule" "nfs" {
  security_group_id = aws_security_group.this.id
  description       = "NFS from cluster nodes"

  referenced_security_group_id = var.node_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
}

# One mount target per AZ. A pod resolves the file system DNS name to the mount
# target in its own AZ; an AZ without one cannot mount at all, and cross-AZ NFS
# would be billed as inter-AZ traffic even when it works.
resource "aws_efs_mount_target" "this" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.this.id]
}
