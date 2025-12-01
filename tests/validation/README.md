# tests/validation

Disposable per-PR AWS validation targets (S3 + ECR + CodeArtifact,
`us-west-2`): the real destinations the `e2e-aws` job publishes to, then
destroys.

- Committed S3 backend (`backend.tf`); per-run isolation is by Terraform
  workspace, selected in CI. No bootstrap step.
- CI passes `name_prefix` (the workspace name, e.g. `pr-42`) so resource
  names are unique per PR.
- `terraform output -json route_targets` is the capability-typed
  destination map the publish step consumes.
