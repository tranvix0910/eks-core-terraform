output "file_system_id" {
  description = "Goes into the StorageClass parameters as fileSystemId"
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  value = aws_efs_file_system.this.arn
}

output "dns_name" {
  value = aws_efs_file_system.this.dns_name
}

output "security_group_id" {
  value = aws_security_group.this.id
}

output "mount_target_ids" {
  value = { for k, v in aws_efs_mount_target.this : k => v.id }
}
