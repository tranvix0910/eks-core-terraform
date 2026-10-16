data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket  = "eks-tfstate-${var.aws_account_id}"
    key     = "network/terraform.tfstate"
    region  = "ap-southeast-1"
    profile = var.aws_profile
  }
}

data "terraform_remote_state" "cluster_workload" {
  backend = "s3"

  config = {
    bucket  = "eks-tfstate-${var.aws_account_id}"
    key     = "cluster-workload/terraform.tfstate"
    region  = "ap-southeast-1"
    profile = var.aws_profile
  }
}

module "cluster" {
  source = "../20-cluster-workload/modules/eks_cluster"

  name               = local.name
  kubernetes_version = local.kubernetes_version

  vpc_id     = local.vpc_id
  vpc_cidr   = local.vpc_cidr
  subnet_ids = local.node_subnet_ids

  node_groups = {
    monitoring = {
      instance_types = local.monitoring_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = local.monitoring_desired_size
      max_size     = local.monitoring_desired_size + 1
      desired_size = local.monitoring_desired_size

      labels = { role = "monitoring" }
      taints = {}
    }
  }

  enable_karpenter_discovery = false
  enable_efs_egress          = false

  tags = local.tags
}

module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.name}-ebs-csi"

  attach_aws_ebs_csi_policy = true

  associations = {
    this = {
      cluster_name    = module.cluster.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = local.tags
}

module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.name}-lb-controller"

  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.cluster.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = local.tags
}

resource "aws_security_group" "observability_alb" {
  name        = "${local.name}-internal-alb"
  description = "Internal ALB for Mimir remote_write + Loki push, cluster 1 nodes only"
  vpc_id      = local.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-internal-alb" })
}

resource "aws_vpc_security_group_ingress_rule" "from_cluster_workload_mimir" {
  security_group_id = aws_security_group.observability_alb.id

  description                  = "Mimir remote_write from cluster 1 nodes"
  referenced_security_group_id = local.workload_node_security_group_id
  from_port                    = 9009
  to_port                      = 9009
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "from_cluster_workload_loki" {
  security_group_id = aws_security_group.observability_alb.id

  description                  = "Loki push from cluster 1 nodes"
  referenced_security_group_id = local.workload_node_security_group_id
  from_port                    = 3100
  to_port                      = 3100
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "observability_alb_to_targets" {
  security_group_id = aws_security_group.observability_alb.id

  description = "ALB to its own targets (Mimir/Loki pods)"
  cidr_ipv4   = local.vpc_cidr
  ip_protocol = "-1"
}

# The other half of the path this SG's egress rule above only covers one side
# of: an egress rule on the ALB's SG says the ALB is allowed to send traffic
# out, but the node SG on the receiving end (where the actual Mimir/Loki pods
# live, since this is target-type: ip pointed at pod ENIs sharing the node's
# security group) has no matching ingress rule admitting it. Same class of
# gap as terraform/20-cluster-workload/main.tf's
# aws_vpc_security_group_ingress_rule.node_from_rancher_internal_alb - found
# there first (agent connect timeouts despite a healthy target group), so
# added here proactively instead of waiting for the same failure to repeat
# on remote_write/log push once cluster 1 starts sending real traffic.
# gateway containerPort is 8080 for both mimir-gateway and loki-gateway -
# confirmed on the live pods, not assumed from the chart's Service port
# (which is 80, not what target-type: ip actually dials).
resource "aws_vpc_security_group_ingress_rule" "node_from_observability_alb" {
  security_group_id = module.cluster.node_security_group_id

  description                  = "Mimir/Loki gateway pods from their own internal ALB"
  referenced_security_group_id = aws_security_group.observability_alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}
