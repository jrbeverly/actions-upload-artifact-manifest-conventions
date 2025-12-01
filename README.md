# actions-upload-artifact-manifest-conventions

> [!WARNING]
> **AI-authored:** This change was autonomously planned and implemented by an AI software factory from a human-authored specification, with possible subsequent human review or modification.

> [!WARNING]
> This experiment is effectively abandoned. The generated material is retained primarily as a research artifact.

Manifest-driven, registry-agnostic artifact distribution as a few reusable Gitea actions.

Artifacts are just immutable content plus metadata, but CI usually welds them to one registry's APIs and infrastructure (see PROBLEM.md). Here the two are decoupled: `artifacts-discover` scans a directory and emits a JSON manifest (the stable contract; no destination concept), and `upload-artifacts` reads the manifest plus a route file, plans, and moves the bytes.

Destinations are typed by capability (`blob`, `oci`, `pkg`) plus a backend (`local`, `aws`), never by vendor. The same manifest and plan flow to either backend unchanged — that equivalence is the whole point and is a committed check (`docs/examples/verify.sh`).

Every PR runs the identical flow twice in parallel: `e2e-local` (hermetic filesystem/registry/feed; no cloud, fork-safe) and `e2e-aws` (real S3/ECR/CodeArtifact, disposable per PR). The package the flow distributes is the real one `src/Sample` builds.

```bash
actions/{artifacts-discover,upload-artifacts}/   the product
actions/upload-artifacts/publishers/             <capability>-<backend>.sh
tests/local-targets/  tests/validation/          the two backends
docs/examples/                                    the contract + checks
```
