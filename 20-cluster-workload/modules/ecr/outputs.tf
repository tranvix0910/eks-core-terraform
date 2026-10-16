output "repository_urls" {
  description = "name => repository_url, e.g. \"shopnow/shopnow-frontend\" => \"963...dkr.ecr.../shopnow/shopnow-frontend\""
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  value = { for k, v in aws_ecr_repository.this : k => v.arn }
}
