#!/usr/bin/env bash
set -euo pipefail
# Tool-light proof (jq only): discover classifies, routing maps, and the
# plan is the same across the local and aws backends (registry-agnostic).

root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/a"
for n in svc-1.2.3.docker.tar lib-1.2.3.nupkg bundle-1.2.3.zip NOTES.md; do echo x > "$tmp/a/$n"; done

ARTIFACT_DIR="$tmp/a" MANIFEST_PATH="$tmp/m.json" "$root/actions/artifacts-discover/entrypoint.sh" >/dev/null
jq -e '.artifacts|length==4 and (map(.kind)|sort==["container","generic","package","unknown"])' "$tmp/m.json" >/dev/null \
  || { echo "verify: manifest kinds wrong"; jq -c '[.artifacts[].kind]' "$tmp/m.json"; exit 1; }

cat > "$tmp/local.in" <<'J'
{"blob":{"type":"blob","backend":"local","root_dir":"/r"},
 "oci":{"type":"oci","backend":"local","registry":"127.0.0.1:5000/x"},
 "pkg_generic":{"type":"pkg","backend":"local","format":"generic","feed_dir":"/g"},
 "pkg_nuget":{"type":"pkg","backend":"local","format":"nuget","feed_dir":"/n"},
 "pkg_pypi":{"type":"pkg","backend":"local","format":"pypi","feed_dir":"/p"}}
J
cat > "$tmp/aws.in" <<'J'
{"blob":{"type":"blob","backend":"aws","bucket":"b"},
 "oci":{"type":"oci","backend":"aws","repository_url":"r"},
 "pkg_generic":{"type":"pkg","backend":"aws","format":"generic","domain":"d","repository":"g"},
 "pkg_nuget":{"type":"pkg","backend":"aws","format":"nuget","domain":"d","repository":"n"},
 "pkg_pypi":{"type":"pkg","backend":"aws","format":"pypi","domain":"d","repository":"p"}}
J
plan() { MANIFEST="$tmp/m.json" ROUTES_RAW="$tmp/$1.in" ROUTES="$tmp/$1.routes" \
  PLAN="$tmp/$1.plan" "$root/actions/upload-artifacts/entrypoint.sh" >/dev/null; }
plan local; plan aws

jq -e '[.operations[]|select(.type=="oci")|.artifact_id]|all(startswith("container"))' "$tmp/local.plan" >/dev/null \
  || { echo "verify: routing wrong"; exit 1; }

norm() { jq -S '[.operations[]|{artifact_id,destination,type}]|sort' "$tmp/$1.plan"; }
[ "$(norm local)" = "$(norm aws)" ] \
  || { echo "verify: plans diverge across backends (registry-agnosticism broken)"; exit 1; }

echo "verify: OK -- manifest, routing, and backend-invariant plan agree"
