# ---------------------------------------------------------------
# Internal ALB for Mimir remote_write + Loki push from layer 20 nodes
# Name is referenced by the Mimir/Loki Ingress in gitops - do not rename
# ---------------------------------------------------------------
module "observability_internal_alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name            = "${local.name}-internal-alb"
  use_name_prefix = false
  description     = "Internal ALB for Mimir remote_write + Loki push, cluster 1 nodes only"
  vpc_id          = local.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "Mimir remote_write from cluster 1 nodes"
      from_port                = 9009
      to_port                  = 9009
      protocol                 = "tcp"
      source_security_group_id = local.workload_node_security_group_id
    },
    {
      description              = "Loki push from cluster 1 nodes"
      from_port                = 3100
      to_port                  = 3100
      protocol                 = "tcp"
      source_security_group_id = local.workload_node_security_group_id
    },
  ]

  egress_with_cidr_blocks = [
    {
      description = "ALB to its own targets (Mimir/Loki pods)"
      rule        = "all-all"
      cidr_blocks = local.vpc_cidr
    },
  ]

  tags = var.tags
}

# target-type ip dials the gateway containerPort (8080), not the Service port
resource "aws_vpc_security_group_ingress_rule" "node_from_observability_alb" {
  security_group_id = module.eks.node_security_group_id

  description                  = "Mimir/Loki gateway pods from their own internal ALB"
  referenced_security_group_id = module.observability_internal_alb_sg.security_group_id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}
