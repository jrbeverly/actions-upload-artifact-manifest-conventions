#!/usr/bin/env bash
set -euo pipefail
# blob/aws: S3 put-object. Bucket + key are route-derived.
op="${1:?usage: blob-aws.sh <op-json>}"
f() { jq -r "$1" <<<"$op"; }
path="$(f .path)"; bucket="$(f .target.bucket)"; key="$(f .target.key)"
[ -f "$path" ] || { echo "blob-aws: missing $path" >&2; exit 1; }
aws s3 cp "$path" "s3://${bucket}/${key}"
echo "blob-aws: $(f .file_name) -> s3://${bucket}/${key}"
