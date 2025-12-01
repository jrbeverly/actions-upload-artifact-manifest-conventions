# tests/local-targets

The hermetic LOCAL destination family — the zero-cost, no-credentials,
fork-safe counterpart of `tests/validation` (AWS). Both emit the same
capability-typed `route_targets` shape, so the same manifest and plan flow
to either backend (see TECHNICAL.md).

- `blob` → a job-local directory tree
- `oci` → a job-local `registry:2` on 127.0.0.1 (insecure; no TLS/login)
- `pkg` → job-local per-format feed directories

Prereqs: `docker`, `jq`, `curl`. No AWS, no network egress to a cloud.

```bash
tests/local-targets/up.sh   "$RUN_ROOT" > "$ROUTES_RAW"
tests/local-targets/down.sh "$RUN_ROOT"   # if: always()
```
