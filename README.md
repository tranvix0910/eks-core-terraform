# Terraform in the EKS Workshop

Terraform creates the network and two clusters, plus selected Helm releases and StorageClasses. Start with the [prerequisites](https://tranvix0910.github.io/eks-core-docs/docs/architecture/organizational-constraints-and-prerequisites) and apply layers in dependency order.

| Layer | Purpose | State key | Lab |
|---|---|---|---|
| `10-network` | Shared network, subnets, NAT, and endpoints | `network/terraform.tfstate` | [Step 1](https://tranvix0910.github.io/eks-core-docs/docs/architecture/layer-10-network) |
| `20-cluster-workload` | EKS, infrastructure nodes, IAM/Karpenter, EFS/ECR, and platform releases | `cluster-workload/terraform.tfstate` | [Step 2](https://tranvix0910.github.io/eks-core-docs/docs/architecture/layer-20-cluster-workload) |
| `21-cluster-observability` | EKS, monitoring nodes, S3, receivers, and private DNS | `cluster-observability/terraform.tfstate` | [Step 3](https://tranvix0910.github.io/eks-core-docs/docs/architecture/layer-21-cluster-observability) |

Fresh bootstrap: network → AWS foundation 20 → AWS foundation 21 → full 20 → prerequisites 21 → full 21. Foundation targeting is an exception required by the current state/provider structure. Review a full plan afterward.

For ongoing changes: initialize when needed → format and validate → save a plan → review → apply → verify running workloads. Backend and provider configuration lives in `main.tf` and `provider.tf`; outputs currently use `output.tf`. Older documentation filenames do not establish whether a resource exists.

Layer 20 disables EFS and creates no ECR repositories by default; enable them as described in the workshop. Update account-specific ARNs, buckets, and endpoints consistently. Keep `.terraform`, plans, state, and private keys out of Git.

Read [cleanup and circular dependencies](https://tranvix0910.github.io/eks-core-docs/docs/operations/lifecycle-and-cleanup) before destroying resources. Deleting clusters before applications and load balancers can leave resources outside Terraform state.
