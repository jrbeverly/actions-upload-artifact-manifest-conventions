#!/usr/bin/env bash
set -euo pipefail
# Tear down the LOCAL destinations. Idempotent; safe under if: always().
run_root="${1:?usage: down.sh <run_root>}"
[ -d "$run_root" ] || exit 0
root="$(cd "$run_root" && pwd)"
id="$(basename "$root")"; id="${id#run-}"
docker rm -f "artifact-local-registry-${id}" >/dev/null 2>&1 || true
rm -rf "$root/local"
