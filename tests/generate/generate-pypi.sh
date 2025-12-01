#!/usr/bin/env bash
set -euo pipefail

# tests/generate/generate-pypi.sh
#
# Generate a synthetic Python wheel for end-to-end validation.
# A .whl is a ZIP archive (PEP 427). This script constructs one directly
# so no Python build toolchain (setuptools, build, pip wheel) is needed.
# The output is a structurally valid wheel publishable through Twine.

out_dir="${1:?usage: generate-pypi.sh <output-dir> [name] [version]}"
name="${2:-demo-lib}"
version="${3:-2.0.1}"

fail() { echo "generate-pypi: $*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || fail "python3 is required but was not found on PATH."

mkdir -p "$out_dir"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# The wheel distribution name normalises dashes to underscores.
pkg_name="$(echo "$name" | tr '-' '_')"
pkg_dir="${work}/${pkg_name}"
dist_info="${work}/${pkg_name}-${version}.dist-info"
mkdir -p "$pkg_dir" "$dist_info"

# --- package payload -------------------------------------------------------
cat > "${pkg_dir}/__init__.py" <<'EOF'
"""Synthetic package for end-to-end validation."""
EOF

# --- dist-info ------------------------------------------------------------
cat > "${dist_info}/METADATA" <<META
Metadata-Version: 2.1
Name: ${name}
Version: ${version}
Summary: Synthetic package for end-to-end artifact validation

META

cat > "${dist_info}/WHEEL" <<'WHEEL'
Wheel-Version: 1.0
Generator: tests/generate/generate-pypi.sh
Root-Is-Purelib: true
Tag: py3-none-any
WHEEL

echo "${pkg_name}" > "${dist_info}/top_level.txt"

# --- RECORD (file list with sha256, size) ---------------------------------
# Build the wheel in a temporary path first so the RECORD only covers the
# final contents.
wheel_tmp="${work}/tmp.whl"
python3 -c "
import zipfile, hashlib, os, base64

whl = '$wheel_tmp'
lines = []
with zipfile.ZipFile(whl, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk('$work'):
        for fname in files:
            fpath = os.path.join(root, fname)
            arcname = os.path.relpath(fpath, '$work')
            if arcname in ('tmp.whl', 'RECORD'):
                continue
            zf.write(fpath, arcname)
            with open(fpath, 'rb') as f:
                digest = hashlib.sha256(f.read()).digest()
            lines.append(
                f'{arcname},sha256={base64.urlsafe_b64encode(digest).decode().rstrip(\"=\")},'
                f'{os.path.getsize(fpath)}'
            )
lines.append('${pkg_name}-${version}.dist-info/RECORD,,')
with zipfile.ZipFile(whl, 'a', zipfile.ZIP_DEFLATED) as zf:
    zf.writestr('${pkg_name}-${version}.dist-info/RECORD', '\n'.join(lines) + '\n')
" || fail "python3 wheel construction failed."

# Wheel filename: {dist}-{version}-py3-none-any.whl
wheel_file="${out_dir}/${pkg_name}-${version}-py3-none-any.whl"
mv "$wheel_tmp" "$wheel_file"

echo "generate-pypi: produced ${wheel_file}"
