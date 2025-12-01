#!/usr/bin/env bash
set -euo pipefail

# tests/generate/generate-all.sh
#
# Generate synthetic artifacts of every supported kind for end-to-end
# validation. Produces deterministic outputs in a caller-specified (or
# default) directory so CI and local verification share the same generation
# path. No binary fixtures are committed.
#
# Usage:
#   tests/generate/generate-all.sh [output-dir]
#
# Output (every kind the discover action classifies):
#   container:    service-1.4.0.docker.tar, service-1.4.0.oci.tar
#   package/pypi: demo_lib-2.0.1-py3-none-any.whl
#   package/nuget: Demo.Lib.3.1.0.nupkg
#   generic/zip:  bundle-0.9.0.zip

out_dir="${1:-dist}"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() { echo "generate-all: $*" >&2; exit 1; }

mkdir -p "$out_dir"

generators=(
  "${here}/generate-container.sh"
  "${here}/generate-pypi.sh"
  "${here}/generate-nuget.sh"
  "${here}/generate-generic.sh"
)

had_failures=false
for gen in "${generators[@]}"; do
  name="$(basename "$gen")"
  echo "generate-all: running ${name}"
  if "$gen" "$out_dir"; then
    echo "generate-all: ${name} OK"
  else
    echo "generate-all: ${name} FAILED" >&2
    had_failures=true
  fi
done

echo "generate-all: artifacts in ${out_dir}:"
find "$out_dir" -type f | sort | while read -r f; do
  printf '  %s  %s\n' "$(du -h "$f" | cut -f1)" "$(basename "$f")"
done

if [ "$had_failures" = true ]; then
  fail "one or more generators failed."
fi

echo "generate-all: OK"
