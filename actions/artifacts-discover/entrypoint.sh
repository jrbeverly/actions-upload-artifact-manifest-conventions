#!/usr/bin/env bash
set -euo pipefail

# Scan a directory, classify files by extension, emit the JSON manifest
# (the stable contract consumed by upload-artifacts).

dir="${ARTIFACT_DIR:?ARTIFACT_DIR not set}"
out="${MANIFEST_PATH:?MANIFEST_PATH not set}"
[ -d "$dir" ] || { echo "artifacts-discover: '$dir' is not a directory" >&2; exit 1; }

mkdir -p "$(dirname "$out")"
entries=()
while IFS= read -r f; do
  name="$(basename "$f")"
  case "$name" in
    *.docker.tar) kind=container format=docker-archive ;;
    *.oci.tar)    kind=container format=oci-archive ;;
    *.whl)        kind=package   format=pypi ;;
    *.nupkg)      kind=package   format=nuget ;;
    *.zip)        kind=generic   format=zip ;;
    *)            kind=unknown   format=unknown ;;
  esac
  version="$(echo "$name" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"
  sha256="$(sha256sum "$f" | cut -d' ' -f1)"
  entries+=("$(jq -n --arg id "$kind:$name" --arg kind "$kind" --arg format "$format" \
    --arg path "$f" --arg file_name "$name" --arg version "$version" --arg sha256 "$sha256" \
    '{id:$id,kind:$kind,format:$format,path:$path,file_name:$file_name,
      version:(if $version=="" then null else $version end),sha256:$sha256}')")
done < <(find "$dir" -type f ! -name '*.sha256' | sort)

[ "${#entries[@]}" -gt 0 ] || { echo "artifacts-discover: no files under '$dir'" >&2; exit 1; }
printf '%s\n' "${entries[@]}" | jq -s '{schema_version:"v1",artifacts:.}' > "$out"
echo "artifacts-discover: ${#entries[@]} artifact(s) -> $out"
