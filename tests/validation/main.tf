# Disposable per-PR validation targets: S3 + ECR + CodeArtifact. force
# destroy/delete so `terraform destroy` is clean after publishing.
locals {
  name = "artifact-validation-${var.name_prefix}"
}

resource "aws_s3_bucket" "releases" {
  bucket        = "${local.name}-releases"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "releases" {
  bucket                  = aws_s3_bucket.releases.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ecr_repository" "service" {
  name         = "${local.name}/service"
  force_delete = true
}

resource "aws_codeartifact_domain" "main" {
  domain = local.name
}

resource "aws_codeartifact_repository" "generic" {
  domain     = aws_codeartifact_domain.main.domain
  repository = "${local.name}-generic"
}

resource "aws_codeartifact_repository" "nuget" {
  domain     = aws_codeartifact_domain.main.domain
  repository = "${local.name}-nuget"
}

resource "aws_codeartifact_repository" "pypi" {
  domain     = aws_codeartifact_domain.main.domain
  repository = "${local.name}-pypi"
}
