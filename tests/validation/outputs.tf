# Capability-typed destinations (aws backend). The local family
# (tests/local-targets/up.sh) emits the same shape with backend "local".
output "route_targets" {
  value = {
    blob        = { type = "blob", backend = "aws", bucket = aws_s3_bucket.releases.bucket }
    oci         = { type = "oci", backend = "aws", repository_url = aws_ecr_repository.service.repository_url }
    pkg_generic = { type = "pkg", backend = "aws", format = "generic", domain = aws_codeartifact_domain.main.domain, repository = aws_codeartifact_repository.generic.repository }
    pkg_nuget   = { type = "pkg", backend = "aws", format = "nuget", domain = aws_codeartifact_domain.main.domain, repository = aws_codeartifact_repository.nuget.repository }
    pkg_pypi    = { type = "pkg", backend = "aws", format = "pypi", domain = aws_codeartifact_domain.main.domain, repository = aws_codeartifact_repository.pypi.repository }
  }
}
