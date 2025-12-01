# Examples

The manifest is the stable contract between discovery and distribution.
[`manifest.sample.json`](manifest.sample.json) shows its shape: a
`schema_version` and an `artifacts` array of
`{id, kind, format, path, file_name, version, sha256}`. It carries no
destination concept — routing is layered on later by `upload-artifacts`.

Checks (run by `make verify` and in CI):

- [`verify.sh`](verify.sh) — jq only: discover classifies, routing maps,
  and the plan is identical across the `local` and `aws` backends.
- [`verify-publication.sh`](verify-publication.sh) — after a real publish,
  asserts the receipt has no failures (only the two documented v1 gaps,
  `pkg_generic` and `oci-archive`, may be `unsupported`).
