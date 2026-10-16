# ---------------------------------------------------------------
# Pod Identity for EKS addons / controllers
# ---------------------------------------------------------------
module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name                      = "${local.name}-ebs-csi"
  attach_aws_ebs_csi_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = var.tags
}

module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name                            = "${local.name}-lb-controller"
  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------
# Pod Identity for Mimir / Loki - each scoped to its own bucket
# ---------------------------------------------------------------
data "aws_iam_policy_document" "s3" {
  for_each = local.s3_buckets

  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [module.s3[each.key].s3_bucket_arn]
  }

  statement {
    sid       = "ReadWriteObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.s3[each.key].s3_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "s3" {
  for_each = local.s3_buckets

  name   = "${local.name}-${each.key}-s3"
  policy = data.aws_iam_policy_document.s3[each.key].json
  tags   = var.tags
}

module "s3_pod_identity" {
  source   = "terraform-aws-modules/eks-pod-identity/aws"
  version  = "~> 2.0"
  for_each = local.s3_buckets

  name = "${local.name}-${each.key}"

  additional_policy_arns = {
    s3 = aws_iam_policy.s3[each.key].arn
  }

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "monitoring"
      service_account = each.key
    }
  }

  tags = var.tags
}
