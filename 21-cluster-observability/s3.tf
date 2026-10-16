# Object storage for Mimir (metric blocks) and Loki (log chunks + index).
#
# Both charts support filesystem storage on a PVC, which would be simpler to
# wire up - no bucket, no Pod Identity, no IAM policy. Not used here because
# it silently caps this at exactly the node the pod landed on: no replication,
# and a node replacement (upgrade, AZ issue) loses every block that had not
# been part of a manual backup. S3 costs nothing extra to set up correctly the
# first time and removes that failure mode entirely.

resource "aws_s3_bucket" "mimir" {
  bucket = "${local.name}-mimir-${var.aws_account_id}"
  tags   = local.tags
}

resource "aws_s3_bucket" "loki" {
  bucket = "${local.name}-loki-${var.aws_account_id}"
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "mimir" {
  bucket = aws_s3_bucket.mimir.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "loki" {
  bucket = aws_s3_bucket.loki.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning off deliberately - this is lab data, not an audit trail. On
# would mean every compaction rewrite keeps the old version around forever
# with no lifecycle rule cleaning it up, growing storage cost for nothing
# anyone would ever restore.
resource "aws_s3_bucket_versioning" "mimir" {
  bucket = aws_s3_bucket.mimir.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_versioning" "loki" {
  bucket = aws_s3_bucket.loki.id
  versioning_configuration {
    status = "Disabled"
  }
}

# Lab retention: 30 days is enough to demonstrate the pipeline and debug
# anything recent, without the bucket growing unbounded while this runs.
resource "aws_s3_bucket_lifecycle_configuration" "mimir" {
  bucket = aws_s3_bucket.mimir.id

  rule {
    id     = "expire-old-blocks"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    id     = "expire-old-chunks"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# Pod Identity, one role per component, scoped to its own bucket only - Mimir
# has no business reading Loki's chunks or vice versa.
module "mimir_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.name}-mimir"

  additional_policy_arns = {
    s3 = aws_iam_policy.mimir_s3.arn
  }

  associations = {
    this = {
      cluster_name    = module.cluster.cluster_name
      namespace       = "monitoring"
      service_account = "mimir"
    }
  }

  tags = local.tags
}

module "loki_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.name}-loki"

  additional_policy_arns = {
    s3 = aws_iam_policy.loki_s3.arn
  }

  associations = {
    this = {
      cluster_name    = module.cluster.cluster_name
      namespace       = "monitoring"
      service_account = "loki"
    }
  }

  tags = local.tags
}

data "aws_iam_policy_document" "mimir_s3" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.mimir.arn]
  }

  statement {
    sid       = "ReadWriteObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.mimir.arn}/*"]
  }
}

data "aws_iam_policy_document" "loki_s3" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.loki.arn]
  }

  statement {
    sid       = "ReadWriteObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.loki.arn}/*"]
  }
}

resource "aws_iam_policy" "mimir_s3" {
  name   = "${local.name}-mimir-s3"
  policy = data.aws_iam_policy_document.mimir_s3.json
  tags   = local.tags
}

resource "aws_iam_policy" "loki_s3" {
  name   = "${local.name}-loki-s3"
  policy = data.aws_iam_policy_document.loki_s3.json
  tags   = local.tags
}
