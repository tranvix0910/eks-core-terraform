# Mimir blocks / Loki chunks. Versioning off: compaction rewrites would pile up old versions
module "s3" {
  source   = "terraform-aws-modules/s3-bucket/aws"
  version  = "~> 5.0"
  for_each = local.s3_buckets

  bucket = each.value

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle_rule = [
    {
      id      = "expire-old-objects"
      enabled = true
      filter  = {}
      expiration = {
        days = var.s3_expiration_days
      }
    }
  ]

  tags = var.tags
}
