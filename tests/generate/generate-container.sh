#!/usr/bin/env bash
set -euo pipefail

# Synthetic container artifacts: *.docker.tar (docker save) and, best
# effort, *.oci.tar (buildx --output type=oci). Minimal FROM-scratch image.

out_dir="${1:?usage: generate-container.sh <output-dir> [name] [version]}"
name="${2:-service}"
version="${3:-1.4.0}"

fail() { echo "generate-container: $*" >&2; exit 1; }

command -v docker >/dev/null 2>&1 || fail "docker is required but was not found on PATH."
docker info >/dev/null 2>&1 || fail "docker daemon is unreachable."

mkdir -p "$out_dir"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cat > "$work/Dockerfile" <<'EOF'
FROM scratch
COPY payload /
EOF
echo "synthetic-container-artifact" > "$work/payload"

image_tag="${name}:${version}"
docker_archive="${out_dir}/${name}.${version}.docker.tar"
oci_archive="${out_dir}/${name}.${version}.oci.tar"

# --- docker-archive -------------------------------------------------------
echo "generate-container: building ${image_tag} for docker-archive"
docker build -t "$image_tag" "$work"

echo "generate-container: docker save -> ${docker_archive}"
docker save "$image_tag" -o "$docker_archive"

# oci-archive is best-effort: the default docker driver cannot export
# type=oci; try it, then a throwaway docker-container builder. Skipped (not
# fatal) if neither works -- the docker-archive is the required deliverable.
echo "generate-container: building OCI archive -> ${oci_archive}"
oci_ok=false
if docker buildx build --output "type=oci,dest=${oci_archive}" "$work" 2>/dev/null; then
  oci_ok=true
else
  builder="genoci-$$"
  if docker buildx create --name "$builder" --driver docker-container >/dev/null 2>&1; then
    if docker buildx build --builder "$builder" \
        --output "type=oci,dest=${oci_archive}" "$work" >/dev/null 2>&1; then
      oci_ok=true
    fi
    docker buildx rm "$builder" >/dev/null 2>&1 || true
  fi
fi

if [ "$oci_ok" = true ]; then
  echo "generate-container: produced ${docker_archive} and ${oci_archive}"
else
  echo "generate-container: WARNING - this runner's docker/buildx cannot export type=oci; skipping the OCI archive. Produced ${docker_archive} only." >&2
fi
