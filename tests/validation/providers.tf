provider "aws" {
  region  = "us-west-2"
  profile = "patterneddesigns"
  default_tags {
    tags = {
      ManagedBy = "terraform"
      Purpose   = "disposable-pr-validation"
    }
  }
}
