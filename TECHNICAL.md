# Technical

A small set of Gitea composite actions, concise Bash, demonstrating
manifest-driven, registry-agnostic artifact distribution.

## Flow

1. CI creates a run directory `.artifact-routing/run-<id>/` and exports the
   paths it holds: `MANIFEST`, `ROUTES_RAW`, `ROUTES`, `PLAN`, `RECEIPT`.
2. `actions/artifacts-discover` scans a directory and writes `MANIFEST` — a
   JSON list of `{id, kind, format, path, file_name, version, sha256}`. It
   carries no destination concept.
3. `actions/upload-artifacts` reads `MANIFEST` plus a raw `route_targets`
   map, normalizes it into `ROUTES` (adding the fixed routing rules),
   writes a `PLAN`, and — when `execute` is true — runs the publishers and
   writes a `RECEIPT`.

Classification is filename-driven: `*.docker.tar`/`*.oci.tar` → container,
`*.whl` → pypi, `*.nupkg` → nuget, `*.zip` → generic, else unknown.

## Destinations are typed by capability, not vendor

`route_targets` keys are stable; each value carries `type`
(`blob` | `oci` | `pkg`) and `backend` (`local` | `aws`) plus that
backend's addressing. The same manifest and plan flow to either backend
unchanged — only the addressing differs, checked by
`docs/examples/verify.sh`.

```json
{
  "blob": { "type": "blob", "backend": "aws", "bucket": "..." },
  "oci":  { "type": "oci",  "backend": "aws", "repository_url": "..." },
  "pkg_nuget": { "type": "pkg", "backend": "aws", "format": "nuget",
                 "domain": "...", "repository": "..." }
}
```

The `local` backend (`tests/local-targets/up.sh`) emits the same shape with
`backend: "local"` and `root_dir`/`registry`/`feed_dir` addressing.
Routing: generic → blob + pkg_generic; container → oci; nuget/pypi → blob +
pkg_(nuget|pypi).

## Validation

Two parallel PR jobs run the identical flow: `e2e-local` (hermetic — a
filesystem blob dir, a local `registry:2`, on-disk pkg feeds; no cloud, no
credentials) and `e2e-aws` (real S3/ECR/CodeArtifact in `us-west-2`,
disposable per PR, destroyed `if: always()`). The artifact distributed is
the real package `src/Sample` builds; other kinds are synthetic.
`tests/validation` is a committed S3-backed Terraform config isolated per
PR by workspace; CI passes `name_prefix`.

Two operations are deliberate `unsupported` v1 gaps, symmetric across
backends: `pkg_generic` (an arbitrary blob has no package feed) and the
`oci-archive` leg (`docker load` is not portable for OCI layout tars; the
`docker-archive` of the same image publishes).
