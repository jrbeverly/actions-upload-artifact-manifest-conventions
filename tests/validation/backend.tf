# Pre-existing org state bucket (ambient prerequisite). Per-run isolation
# is by Terraform workspace, selected in CI, not by the key.
terraform {
  backend "s3" {
    profile = "patterneddesigns"
    bucket  = "org-terraform-state-700555016924"
    key     = "temporary-state/actions-upload-artifact-manifest-conventions/validation.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
