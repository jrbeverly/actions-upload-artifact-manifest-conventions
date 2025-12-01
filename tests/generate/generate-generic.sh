#!/usr/bin/env bash
set -euo pipefail

# tests/generate/generate-generic.sh
#
# Generate a synthetic generic (ZIP) artifact for end-to-end validation.
# Produces a minimal *.zip so discover classifies it as kind=generic,
# format=zip and the S3 publisher can exercise the put-object path.

out_dir="${1:?usage: generate-generic.sh <output-dir> [name] [version]}"
name="${2:-bundle}"
version="${3:-0.9.0}"

fail() { echo "generate-generic: $*" >&2; exit 1; }

# zip is the obvious tool, but a .zip is a well-defined format and python3 is
# already a hard dependency of the generation path (generate-pypi.sh builds a
# wheel with it). Fall back to python3's zipfile so a minimal runner without
# the `zip` binary still produces a valid generic artifact.
command -v zip >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1 \
  || fail "neither zip nor python3 is available to build the .zip artifact."

# Absolutize before any `cd`: both build paths below run from inside the
# scratch dir, so a relative out_dir (e.g. CI's "src/Sample/artifacts")
# would not resolve once we cd away.
mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

content_dir="${work}/${name}-${version}"
mkdir -p "$content_dir"

echo "synthetic-generic-artifact" > "${content_dir}/README.txt"
echo "placeholder"               > "${content_dir}/data.bin"

zip_file="${out_dir}/${name}-${version}.zip"

echo "generate-generic: creating ${zip_file}"
if command -v zip >/dev/null 2>&1; then
  (cd "$work" && zip -qr "$zip_file" "${name}-${version}") \
    || fail "zip failed."
else
  echo "generate-generic: zip not found; building with python3 zipfile"
  ( cd "$work" && python3 - "$zip_file" "${name}-${version}" <<'PY'
import os, sys, zipfile
zip_file, root = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_file, "w", zipfile.ZIP_DEFLATED) as zf:
    for dirpath, _, files in os.walk(root):
        for fn in sorted(files):
            full = os.path.join(dirpath, fn)
            zf.write(full, os.path.relpath(full, "."))
PY
  ) || fail "python3 zip construction failed."
fi

echo "generate-generic: produced ${zip_file}"
