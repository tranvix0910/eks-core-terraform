# Terraform-owned so it exists before any Helm release creates a PVC
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [
    module.eks,
    module.ebs_csi_pod_identity,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "kubernetes_storage_class_v1" "efs" {
  count = var.efs_create ? 1 : 0

  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"
  volume_binding_mode = "Immediate"
  reclaim_policy      = "Delete"

  # One access point per PVC under /dynamic; uid/gid 10001 matches USER in the service images
  parameters = {
    provisioningMode      = "efs-ap"
    fileSystemId          = module.efs.id
    directoryPerms        = "700"
    basePath              = "/dynamic"
    subPathPattern        = "$${.PVC.namespace}/$${.PVC.name}"
    ensureUniqueDirectory = "true"
    uid                   = "10001"
    gid                   = "10001"
  }

  depends_on = [module.efs_csi_pod_identity]
}
