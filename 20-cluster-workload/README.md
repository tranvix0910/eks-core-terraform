# Workload cluster

This layer creates the cluster that runs ShopNow and the `infra` Managed Node Group for controllers. Enable the optional EFS and ECR resources to complete the workshop.

The [full lab](https://tranvix0910.github.io/eks-core-docs/docs/architecture/layer-20-cluster-workload) covers tfvars, foundation bootstrap, plan/apply, connection, and verification. Resolve the Layer 21 remote-state dependency before a full apply in a new environment.

After bootstrap, use full saved plans for updates and review the Terraform-owned releases in `helm_releases.tf`. Keep a single owner for ArgoCD, Karpenter, Prometheus, and StorageClasses; avoid duplicate installations through Helm CLI or ArgoCD.

Continue with [GitOps application deployment](https://tranvix0910.github.io/eks-core-docs/docs/apps-shopnow/shopnow-end-to-end-deployment-guide), [EFS](https://tranvix0910.github.io/eks-core-docs/docs/apps-shopnow/efs-persistent-volumes), and [cleanup](https://tranvix0910.github.io/eks-core-docs/docs/operations/lifecycle-and-cleanup).
