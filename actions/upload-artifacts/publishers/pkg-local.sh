#!/usr/bin/env bash
set -euo pipefail
# pkg/local: drop the package into a job-local feed dir (a dir is a valid
# nuget/pip source). generic has no feed concept -> documented gap, exit 3.
op="${1:?usage: pkg-local.sh <op-json>}"
f() { jq -r "$1" <<<"$op"; }
path="$(f .path)"; fmt="$(f .target.format)"; feed="$(f .target.feed_dir)"
[ -f "$path" ] || { echo "pkg-local: missing $path" >&2; exit 1; }
[ "$fmt" = generic ] && { echo "pkg-local: generic feed is a v1 gap; unsupported"; exit 3; }
mkdir -p "$feed"
cp "$path" "${feed%/}/$(f .file_name)"
echo "pkg-local: $(f .file_name) -> ${fmt} feed"
