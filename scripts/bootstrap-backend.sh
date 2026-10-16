#!/usr/bin/env bash
# Creates the S3 bucket and DynamoDB table that hold Terraform state.
# Run once, before the first `terraform init`. Safe to re-run.
set -euo pipefail

PROFILE="${AWS_PROFILE:-eks-core}"
REGION="${AWS_REGION:-ap-southeast-1}"
ACCOUNT="$(aws sts get-caller-identity --profile "$PROFILE" --region "$REGION" --query Account --output text)"
BUCKET="eks-tfstate-${ACCOUNT}"
TABLE="eks-tfstate-lock"

echo "Account : $ACCOUNT"
echo "Bucket  : $BUCKET"
echo "Table   : $TABLE"
echo

if aws s3api head-bucket --bucket "$BUCKET" --profile "$PROFILE" --region "$REGION" 2>/dev/null; then
  echo "Bucket already exists, skipping."
else
  aws s3api create-bucket --bucket "$BUCKET" --profile "$PROFILE" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
  aws s3api put-bucket-versioning --bucket "$BUCKET" --profile "$PROFILE" --region "$REGION" \
    --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "$BUCKET" --profile "$PROFILE" --region "$REGION" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
  aws s3api put-public-access-block --bucket "$BUCKET" --profile "$PROFILE" --region "$REGION" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  echo "Bucket created."
fi

if aws dynamodb describe-table --table-name "$TABLE" --profile "$PROFILE" --region "$REGION" >/dev/null 2>&1; then
  echo "Lock table already exists, skipping."
else
  aws dynamodb create-table --table-name "$TABLE" --profile "$PROFILE" --region "$REGION" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST >/dev/null
  echo "Lock table created."
fi

echo
echo "Done. Backend config in each layer's backend.tf should read:"
echo "  bucket = \"$BUCKET\""
