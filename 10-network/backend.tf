# Partial backend config: bucket and profile come from backend.hcl
# (gitignored). Copy backend.hcl.example, fill it in, then run
#   terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {
    key          = "network/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}

