# ---------------------------------------------------------------
# Rancher internal ALB - cluster-agent registration from layer 21 nodes
# Name is referenced by the Rancher Ingress in gitops - do not rename
# ---------------------------------------------------------------
module "rancher_internal_alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name            = "${local.name}-rancher-internal-alb"
  use_name_prefix = false
  description     = "Internal ALB for Rancher cluster-agent registration, cluster 2 nodes only"
  vpc_id          = local.vpc_id

  # Added on the next apply once layer 21 exists
  ingress_with_source_security_group_id = local.observability_node_security_group_id == null ? [] : [
    {
      description              = "Rancher agent registration from cluster 2 nodes"
      rule                     = "https-443-tcp"
      source_security_group_id = local.observability_node_security_group_id
    },
  ]

  egress_with_cidr_blocks = [
    {
      description = "ALB to its own target (Rancher pod)"
      rule        = "all-all"
      cidr_blocks = local.vpc_cidr
    },
  ]

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "node_from_rancher_internal_alb" {
  security_group_id = module.eks.node_security_group_id

  description                  = "Rancher pod from its own internal ALB"
  referenced_security_group_id = module.rancher_internal_alb_sg.security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
