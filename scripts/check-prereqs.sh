#!/usr/bin/env bash
# Pre-flight checks. Run before the first terraform apply.
set -uo pipefail

PROFILE="${AWS_PROFILE:-eks-core}"
REGION="${AWS_REGION:-ap-southeast-1}"
export AWS_PROFILE="$PROFILE" AWS_REGION="$REGION"

fail=0
ok()   { printf "  \033[32mOK\033[0m   %s\n" "$1"; }
warn() { printf "  \033[33mWARN\033[0m %s\n" "$1"; }
bad()  { printf "  \033[31mFAIL\033[0m %s\n" "$1"; fail=1; }

echo "Pre-flight: $PROFILE @ $REGION"
echo

acct=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) \
  && ok "credentials valid (account $acct)" || bad "cannot authenticate"

# EKS and EFS are region-restricted by an Organizations SCP. Confirm this region is allowed.
aws eks list-clusters >/dev/null 2>&1 && ok "EKS allowed in $REGION" \
  || bad "EKS denied in $REGION — check SCP <SCP_POLICY_ID>, allowed: ap-southeast-1, ap-southeast-5, ap-northeast-1"
aws efs describe-file-systems >/dev/null 2>&1 && ok "EFS allowed in $REGION" || bad "EFS denied in $REGION"

# VPC headroom. The design needs 1 slot; zero headroom is a real risk.
vq=$(aws service-quotas get-service-quota --service-code vpc --quota-code L-F678F1CE --query 'Quota.Value' --output text 2>/dev/null | cut -d. -f1)
vu=$(aws ec2 describe-vpcs --query 'length(Vpcs)' --output text 2>/dev/null)
free=$(( vq - vu ))
if   [ "$free" -ge 3 ]; then ok   "VPC quota $vu/$vq ($free free)"
elif [ "$free" -ge 1 ]; then warn "VPC quota $vu/$vq (only $free free) — request an increase to 20"
else                         bad  "VPC quota exhausted ($vu/$vq)"
fi

# 3 NAT Gateways need 3 EIPs. Quota reporting is unreliable here, so test for real.
alloc=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text 2>/dev/null)
if [ -n "$alloc" ] && [ "$alloc" != "None" ]; then
  aws ec2 release-address --allocation-id "$alloc" >/dev/null 2>&1
  ok "EIP allocation works (test address released)"
else
  bad "cannot allocate an EIP — 3 are needed for the NAT Gateways"
fi

# Spot capacity for the 1:3 node pool.
score=$(aws ec2 get-spot-placement-scores --region-names "$REGION" --target-capacity 64 \
  --target-capacity-unit-type vcpu \
  --instance-requirements-with-metadata '{"ArchitectureTypes":["x86_64"],"VirtualizationTypes":["hvm"],"InstanceRequirements":{"VCpuCount":{"Min":2,"Max":16},"MemoryMiB":{"Min":4096}}}' \
  --query 'SpotPlacementScores[0].Score' --output text 2>/dev/null)
if [ -n "$score" ] && [ "$score" -ge 7 ] 2>/dev/null; then ok "spot placement score $score/10"
else warn "spot placement score ${score:-unknown}/10 — widen the instance type list in the node pools"; fi

echo
[ "$fail" -eq 0 ] && echo "Ready to apply." || echo "Fix the FAIL items before applying."
exit "$fail"
