#!/usr/bin/env bash
set -euo pipefail
# Stand up the LOCAL destinations and print route_targets (same shape the
# aws Terraform emits, backend "local"). Usage: up.sh <run_root> > routes
run_root="${1:?usage: up.sh <run_root>}"
mkdir -p "$run_root"
root="$(cd "$run_root" && pwd)"
id="$(basename "$root")"; id="${id#run-}"
blob="$root/local/blob"
gen="$root/local/pkg/generic"; nug="$root/local/pkg/nuget"; pyp="$root/local/pkg/pypi"
mkdir -p "$blob" "$gen" "$nug" "$pyp"

name="artifact-local-registry-${id}"
if [ "$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null || echo false)" != true ]; then
  docker rm -f "$name" >/dev/null 2>&1 || true
  docker run -d --name "$name" -p 127.0.0.1::5000 registry:2 >/dev/null
fi
hostport="$(docker port "$name" 5000/tcp | head -n1)"
for _ in $(seq 1 30); do curl -fsS "http://${hostport}/v2/" >/dev/null 2>&1 && break; sleep 1; done

jq -n --arg blob "$blob" --arg reg "${hostport}/artifact-validation" \
  --arg gen "$gen" --arg nug "$nug" --arg pyp "$pyp" '{
  blob:        {type:"blob",backend:"local",root_dir:$blob},
  oci:         {type:"oci",backend:"local",registry:$reg},
  pkg_generic: {type:"pkg",backend:"local",format:"generic",feed_dir:$gen},
  pkg_nuget:   {type:"pkg",backend:"local",format:"nuget",feed_dir:$nug},
  pkg_pypi:    {type:"pkg",backend:"local",format:"pypi",feed_dir:$pyp}
}'
echo "local-targets/up: registry ${hostport}/artifact-validation" >&2
