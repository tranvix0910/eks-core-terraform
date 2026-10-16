output "cluster_name" {
  value = module.cluster.cluster_name
}

output "cluster_endpoint" {
  value = module.cluster.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value     = module.cluster.cluster_certificate_authority_data
  sensitive = true
}

output "node_security_group_id" {
  value = module.cluster.node_security_group_id
}

output "oidc_provider_arn" {
  value = module.cluster.oidc_provider_arn
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.cluster.cluster_name} --region ${local.region} --profile ${var.aws_profile} --alias eks-observability"
}

output "internal_alb_security_group_id" {
  description = "Attach via alb.ingress.kubernetes.io/security-groups on the Mimir/Loki Ingress"
  value       = aws_security_group.observability_alb.id
}

output "mimir_bucket_name" {
  value = aws_s3_bucket.mimir.bucket
}

output "loki_bucket_name" {
  value = aws_s3_bucket.loki.bucket
}

output "mimir_url" {
  value = "https://mimir.observability.internal:9009"
}

output "loki_url" {
  value = "https://loki.observability.internal:3100"
}
