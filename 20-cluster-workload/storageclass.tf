
# resource "kubernetes_storage_class_v1" "efs" {
#   metadata {
#     name = "efs-sc"
#   }
# 
#   storage_provisioner = "efs.csi.aws.com"
# 
#   # EFS is a network filesystem with no AZ affinity, so there is nothing to wait
#   # for - unlike gp3, which uses WaitForFirstConsumer to avoid creating a volume
#   # in an AZ where the pod cannot run.
#   volume_binding_mode = "Immediate"
# 
#   # Deletes the access point when the PVC goes away. The filesystem itself is
#   # managed by module.shopnow_efs and is untouched by this.
#   reclaim_policy = "Delete"
# 
#   parameters = {
#     provisioningMode = "efs-ap"
#     fileSystemId     = module.shopnow_efs.file_system_id
#     directoryPerms   = "700"
# 
#     # One access point per PVC, each rooted at its own subdirectory. Without it
#     # every claim would see the whole filesystem and one service could read
#     # another's files.
#     basePath       = "/dynamic"
#     subPathPattern = "$${.PVC.namespace}/$${.PVC.name}"
# 
#     # Refuse to provision into a subdirectory that already exists rather than
#     # handing a new PVC someone else's data.
#     ensureUniqueDirectory = "true"
# 
#     # The access point forces this uid/gid on every file, whatever the process
#     # claims. 10001 matches USER in the service Dockerfiles and the fsGroup the
#     # Helm charts set - a mismatch here is the usual cause of permission denied
#     # on an EFS mount that otherwise looks healthy.
#     uid = "10001"
#     gid = "10001"
#   }
# }
