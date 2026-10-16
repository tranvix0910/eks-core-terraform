# eks-core-terraform

Terraform for the EKS Core platform: the network and the two EKS clusters, split into layers by blast radius. A change to a cluster layer never touches the VPC.

| Layer | Responsibility | State key (bucket `eks-tfstate-<AWS_ACCOUNT_ID>`) |
|---|---|---|
| **`10-network`** | VPC `10.20.0.0/16`, subnets, NAT gateway, VPC endpoints, subnet tags, flow logs | `network/terraform.tfstate` |
| **`20-cluster-workload`** | EKS `eks-workload`, managed node group `infra`, IAM, SQS, ECR, EFS, Pod Identity | `cluster-workload/terraform.tfstate` |
| **`21-cluster-observability`** | EKS `eks-observability`, node group `monitoring`, S3 buckets for Mimir/Loki | `cluster-observability/terraform.tfstate` |

Layers read earlier layers' outputs through `terraform_remote_state`; never duplicate a value an earlier layer already outputs.

## Related repositories

| Repository | Contents |
|---|---|
| [eks-core-docs](https://github.com/tranvix0910/eks-core-docs) | Documentation — [published site](https://tranvix0910.github.io/eks-core-docs/) |
| **eks-core-terraform** | This repository |
| [eks-core-gitops](https://github.com/tranvix0910/eks-core-gitops) | ArgoCD, add-ons, Karpenter node pools, ShopNow Helm charts |
| [eks-core-apps](https://github.com/tranvix0910/eks-core-apps) | ShopNow service source code and image build script |

## Account-specific values

Nothing account-specific is committed. Each layer reads it from two gitignored files; copy the examples and fill them in:

```bash
for layer in 10-network 20-cluster-workload 21-cluster-observability; do
  cp $layer/backend.hcl.example        $layer/backend.hcl
  cp $layer/account.auto.tfvars.example $layer/account.auto.tfvars
done
```

| File | Holds |
|---|---|
| `backend.hcl` | State bucket `eks-tfstate-<AWS_ACCOUNT_ID>` and the AWS profile for the S3 backend |
| `account.auto.tfvars` | `aws_account_id` (the provider refuses any other account) and, optionally, `aws_profile` |

The default AWS profile name is `eks-core`.

## Deploy

```bash
./scripts/check-prereqs.sh
./scripts/bootstrap-backend.sh      # once: creates the state bucket

cd 10-network
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Then `20-cluster-workload`, then `21-cluster-observability`, in that order.

`21-cluster-observability/tls.tf` expects the ACM-imported certificate files in `certs/` at the repository root (gitignored).

## File layout per layer

```
versions.tf          Terraform and provider versions, provider config
backend.tf           S3 backend (partial; completed by backend.hcl)
variables.tf         Input variables
locals.tf            Naming, tags, derived values
main.tf              Resources
outputs.tf           Outputs consumed by later layers
terraform.tfvars     Non-secret environment values
```

Full walkthrough: [Tokyo region migration runbook](https://tranvix0910.github.io/eks-core-docs/docs/operations/tokyo-region-migration-runbook).
