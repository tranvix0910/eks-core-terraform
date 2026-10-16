# Partial backend config: bucket and profile come from backend.hcl
# (gitignored). Copy backend.hcl.example, fill it in, then run
#   terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {
    key          = "cluster-workload/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true

    # The backend resolves credentials on its own, before and independently of
    # the provider block, so var.aws_profile does not reach it. Backend blocks
    # accept literals only - no var, no local, no interpolation.
    #
    # Hardcoding the profile here means CI, which has no ~/.aws/config, will
    # fail with "profile not found". Override it there without editing this
    # file: terraform init -backend-config="profile=" (empty falls back to the
    # default credential chain).
  }
}
