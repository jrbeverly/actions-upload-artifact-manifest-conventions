# actions/

Reusable Gitea actions. Runtime logic lives under `actions/<name>/` and
runs from `gitea.action_path`; no root-level `bin/`/`scripts/`. CI-only
helpers (e.g. `tf-workspace-name`) live under `.gitea/actions/`.

- `artifacts-discover` — scan a directory, emit the JSON manifest.
- `upload-artifacts` — normalize routes, plan, and (when `execute`)
  dispatch each op to `publishers/<type>-<backend>.sh`.

The manifest is the stable contract and has no destination concept;
destinations are capability-typed (`blob`/`oci`/`pkg` + `local`/`aws`).
See [TECHNICAL.md](../TECHNICAL.md).
