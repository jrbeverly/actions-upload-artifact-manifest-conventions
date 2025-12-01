#!/usr/bin/env bash
set -euo pipefail
# oci/aws: ECR push (AWS-derived docker login). oci-archive is a
# documented v1 gap (see oci-local.sh) -> exit 3.
op="${1:?usage: oci-aws.sh <op-json>}"
f() { jq -r "$1" <<<"$op"; }
path="$(f .path)"; repo="$(f .target.repository_url)"
[ -f "$path" ] || { echo "oci-aws: missing $path" >&2; exit 1; }
[ "$(f .format)" = oci-archive ] && { echo "oci-aws: oci-archive is a v1 gap; unsupported"; exit 3; }
version="$(f '.version // ""')"; sha="$(f '.sha256 // ""')"
[ -n "$version" ] && [ "$version" != null ] && tag="$version" || tag="sha-${sha:0:12}"
registry="${repo%%/*}"
region="$(sed -n 's/.*\.dkr\.ecr\.\([^.]*\)\.amazonaws\.com$/\1/p' <<<"$registry")"
region="${region:-${AWS_REGION:-${AWS_DEFAULT_REGION:-us-west-2}}}"
aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$registry"
loaded="$(docker load -i "$path")"
ref="$(sed -n 's/^Loaded image: //p' <<<"$loaded" | tail -n1)"
docker tag "$ref" "${repo}:${tag}"
docker push "${repo}:${tag}"
echo "oci-aws: $(f .file_name) -> ${repo}:${tag}"
