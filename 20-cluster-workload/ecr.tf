module "ecr" {
  source   = "terraform-aws-modules/ecr/aws"
  version  = "~> 3.0"
  for_each = toset(var.ecr_repository_names)

  repository_name                 = each.value
  repository_image_tag_mutability = var.ecr_image_tag_mutability
  repository_image_scan_on_push   = true
  repository_encryption_type      = "AES256"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.ecr_lifecycle_policy_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_lifecycle_policy_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = var.tags
}
