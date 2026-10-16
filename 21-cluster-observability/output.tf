# node_security_group_id is read by layer 20 via terraform_remote_state - do not rename

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value     = module.eks.cluster_certificate_authority_data
  sensitive = true
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}${var.aws_profile == null ? "" : " --profile ${var.aws_profile}"} --alias ${module.eks.cluster_name}"
}

output "internal_alb_security_group_id" {
  value = module.observability_internal_alb_sg.security_group_id
}

output "mimir_bucket_name" {
  value = module.s3["mimir"].s3_bucket_id
}

output "loki_bucket_name" {
  value = module.s3["loki"].s3_bucket_id
}

output "mimir_url" {
  value = "https://mimir.${var.route53_private_zone_name}:9009"
}

output "loki_url" {
  value = "https://loki.${var.route53_private_zone_name}:3100"
}
