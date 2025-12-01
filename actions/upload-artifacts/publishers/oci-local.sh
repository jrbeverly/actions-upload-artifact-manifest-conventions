#!/usr/bin/env bash
set -euo pipefail
# oci/local: docker push to a job-local 127.0.0.1 registry (insecure, no
# login). oci-archive is a documented v1 gap (docker load is not portable
# for OCI layout tars; the docker-archive twin publishes) -> exit 3.
op="${1:?usage: oci-local.sh <op-json>}"
f() { jq -r "$1" <<<"$op"; }
path="$(f .path)"; registry="$(f .target.registry)"
[ -f "$path" ] || { echo "oci-local: missing $path" >&2; exit 1; }
[ "$(f .format)" = oci-archive ] && { echo "oci-local: oci-archive is a v1 gap; unsupported"; exit 3; }
version="$(f '.version // ""')"; sha="$(f '.sha256 // ""')"
[ -n "$version" ] && [ "$version" != null ] && tag="$version" || tag="sha-${sha:0:12}"
loaded="$(docker load -i "$path")"
ref="$(sed -n 's/^Loaded image: //p' <<<"$loaded" | tail -n1)"
docker tag "$ref" "${registry}:${tag}"
docker push "${registry}:${tag}"
echo "oci-local: $(f .file_name) -> ${registry}:${tag}"
