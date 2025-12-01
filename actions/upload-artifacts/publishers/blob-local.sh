#!/usr/bin/env bash
set -euo pipefail
# blob/local: copy into a job-local directory tree.
op="${1:?usage: blob-local.sh <op-json>}"
f() { jq -r "$1" <<<"$op"; }
path="$(f .path)"; root="$(f .target.root_dir)"; key="$(f .target.key)"
[ -f "$path" ] || { echo "blob-local: missing $path" >&2; exit 1; }
dest="${root%/}/${key}"
mkdir -p "$(dirname "$dest")"
cp "$path" "$dest"
echo "blob-local: $(f .file_name) -> $dest"
