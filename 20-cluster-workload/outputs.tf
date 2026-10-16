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

output "cluster_security_group_id" {
  description = "Control plane security group, created by EKS"
  value       = module.cluster.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Tagged karpenter.sh/discovery=eks-workload, ready for stage 3"
  value       = module.cluster.node_security_group_id
}

output "oidc_provider_arn" {
  value = module.cluster.oidc_provider_arn
}

output "kubeconfig_command" {
  description = "Run this to configure kubectl context for this cluster"
  value       = "aws eks update-kubeconfig --name ${module.cluster.cluster_name} --region ${local.region} --profile ${var.aws_profile}"
}

# --- Karpenter ---

output "karpenter_node_iam_role_name" {
  description = "Goes into EC2NodeClass spec.role"
  value       = module.karpenter.node_iam_role_name
}

output "karpenter_queue_name" {
  description = "Goes into the Helm values as settings.interruptionQueue"
  value       = module.karpenter.queue_name
}

output "karpenter_service_account" {
  description = "Goes into the Helm values as serviceAccount.name"
  value       = module.karpenter.service_account
}

# # --- EFS ---
# 
# output "efs_file_system_id" {
#   description = "Goes into the efs-sc StorageClass parameters as fileSystemId"
#   value       = module.shopnow_efs.file_system_id
# }
# 
# output "efs_dns_name" {
#   value = module.shopnow_efs.dns_name
# }
# 
# # --- ECR ---
# 
# output "ecr_repository_urls" {
#   description = "image.repository value for each ShopNow service's Helm chart"
#   value       = module.shopnow_ecr.repository_urls
# }

# --- Rancher multi-cluster ---

output "rancher_internal_alb_security_group_id" {
  description = "Attach via alb.ingress.kubernetes.io/security-groups on the Rancher Ingress"
  value       = aws_security_group.rancher_internal_alb.id
}
