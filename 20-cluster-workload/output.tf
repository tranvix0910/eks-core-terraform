# node_security_group_id is read by layer 21 via terraform_remote_state - do not rename

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

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
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

output "karpenter_node_iam_role_name" {
  description = "EC2NodeClass spec.role"
  value       = module.karpenter.node_iam_role_name
}

output "karpenter_queue_name" {
  value = module.karpenter.queue_name
}

output "karpenter_service_account" {
  value = module.karpenter.service_account
}

output "rancher_internal_alb_security_group_id" {
  value = module.rancher_internal_alb_sg.security_group_id
}

output "ecr_repository_urls" {
  value = { for k, v in module.ecr : k => v.repository_url }
}

output "efs_file_system_id" {
  value = module.efs.id
}

output "grafana_admin_password" {
  value     = random_password.grafana_admin.result
  sensitive = true
}
