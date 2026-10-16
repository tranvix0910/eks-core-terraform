# 20-cluster-workload

EKS cluster `eks-workload` — runs all business microservices for ShopNow and operational platform add-ons (ArgoCD, Karpenter, cert-manager, Rancher, Prometheus, Alloy).

Reads all network values from `10-network` via `terraform_remote_state`. Never hardcode Subnet IDs or CIDRs here.

---

## 1. Current Cluster Specifications (Tokyo Region `ap-northeast-1`)

| Component | Specification |
|---|---|
| **Cluster Name** | `eks-workload` |
| **Kubernetes Version** | `1.34` (platform `eks.31`) |
| **AWS Region** | `ap-northeast-1` (Tokyo) |
| **Base Node Group** | `infra`: 3× `t3.large` (On-Demand, role=infra, untainted) |
| **Secrets Encryption** | AWS KMS (`alias/eks/eks-workload`) |
| **Core Add-ons** | `coredns`, `kube-proxy`, `vpc-cni`, `eks-pod-identity-agent` |
| **Autoscaling** | Karpenter v1.14.0 (IAM, SQS Interruption Queue, 5 EventBridge Rules) |
| **Storage** | AWS EBS (gp3), AWS EFS Shared Filesystem |
| **Registries** | 6 ECR Repositories (`shopnow/*`) |

---

## 2. Connecting with `kubectl`

```bash
# Update kubeconfig
aws eks update-kubeconfig --name eks-workload --region ap-northeast-1 --profile eks-core --alias eks-workload

# Switch context
kubectl config use-context eks-workload

# Verify node status
kubectl get nodes -o wide
```

---

## 3. Operational Documentation

* [docs/00-architecture/04-layer-20-cluster-workload.md](https://tranvix0910.github.io/eks-core-docs/docs/architecture/layer-20-cluster-workload) — Layer 20 EKS Workload Architecture.
* [docs/02-karpenter/](https://github.com/tranvix0910/eks-core-docs/tree/main/docs/02-karpenter) — Karpenter Autoscaling deep-dive.
* [docs/06-operations/01-tokyo-region-migration-runbook.md](https://tranvix0910.github.io/eks-core-docs/docs/operations/tokyo-region-migration-runbook) — Tokyo migration runbook.
