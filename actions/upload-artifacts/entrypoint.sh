#!/usr/bin/env bash
set -euo pipefail

# Manifest-driven distribution. Normalize route input, build a publish
# plan, and (when EXECUTE) dispatch each op to publishers/<type>-<backend>.sh.
# Destinations are typed by capability (blob|oci|pkg) + backend
# (local|aws); the same manifest and plan flow to either backend.

manifest="${MANIFEST:?MANIFEST not set}"
routes_in="${ROUTES_RAW:?ROUTES_RAW not set}"
routes="${ROUTES:?ROUTES not set}"
plan="${PLAN:?PLAN not set}"
[ -f "$manifest" ] && [ -f "$routes_in" ] || { echo "upload-artifacts: missing manifest/routes input" >&2; exit 1; }

# Normalize: pass an already-resolved file through; wrap a raw route_targets
# map with the fixed routing policy. Rules key off backend-independent names.
if jq -e 'has("destinations") and has("rules")' "$routes_in" >/dev/null 2>&1; then
  jq '.' "$routes_in" > "$routes"
else
  jq '{
    destinations: (if has("blob") then .blob += {key_template:"{kind}/{version}/{file_name}"} else . end),
    rules: [
      {match:{kind:"generic"},                publish_to:["blob","pkg_generic"]},
      {match:{kind:"container"},               publish_to:["oci"]},
      {match:{kind:"package",format:"nuget"},  publish_to:["blob","pkg_nuget"]},
      {match:{kind:"package",format:"pypi"},   publish_to:["blob","pkg_pypi"]}
    ]
  }' "$routes_in" > "$routes"
fi

# One operation per (artifact, destination) a rule selects. target carries
# the destination's addressing verbatim, with blob's key template expanded.
jq -n --slurpfile m "$manifest" --slurpfile r "$routes" '
  $r[0] as $routes | $m[0].artifacts as $arts
  | def match($a): [$routes.rules[] | select(.match|to_entries|all(.value==($a[.key])))][0];
  {
    operations: [ $arts[] | . as $a | match($a) as $rule | select($rule)
      | $rule.publish_to[] as $dn | $routes.destinations[$dn] as $d
      | { artifact_id:$a.id, kind:$a.kind, format:$a.format, path:$a.path,
          file_name:$a.file_name, version:$a.version, sha256:$a.sha256,
          type:$d.type, backend:$d.backend, destination:$dn,
          target: (($d|del(.type)|del(.key_template))
            + (if $d.type=="blob" then
                 {key:($d.key_template|gsub("\\{kind\\}";$a.kind)
                   |gsub("\\{version\\}";($a.version//"unversioned"))
                   |gsub("\\{file_name\\}";$a.file_name))}
               else {} end)) } ],
    skipped: [ $arts[] | select(match(.)|not) | .id ]
  }' > "$plan"

echo "upload-artifacts: $(jq '.operations|length' "$plan") op(s), $(jq '.skipped|length' "$plan") skipped"

case "${EXECUTE:-false}" in true|1|yes|on) ;; *) echo "upload-artifacts: plan only"; exit 0 ;; esac
receipt="${RECEIPT:?RECEIPT not set}"
pubdir="$(cd "$(dirname "${BASH_SOURCE[0]}")/publishers" && pwd)"

# Publisher exit: 0 published, 3 unsupported (documented v1 gap), else failed.
results="[]"; failed=false; n="$(jq '.operations|length' "$plan")"; i=0
while [ "$i" -lt "$n" ]; do
  op="$(jq -c ".operations[$i]" "$plan")"
  t="$(jq -r '.type' <<<"$op")"; b="$(jq -r '.backend' <<<"$op")"
  script="${pubdir}/${t}-${b}.sh"
  if [ -x "$script" ]; then
    rc=0; ( "$script" "$op" ) || rc=$?
    case "$rc" in 0) s=published ;; 3) s=unsupported ;; *) s=failed; failed=true ;; esac
  else
    s=unsupported
  fi
  results="$(jq -c --argjson op "$op" --arg s "$s" \
    '. + [{artifact_id:$op.artifact_id,destination:$op.destination,type:$op.type,format:$op.format,status:$s}]' <<<"$results")"
  i=$((i + 1))
done

jq -n --argjson r "$results" '{
  results:$r,
  published:([$r[]|select(.status=="published")]|length),
  failed:([$r[]|select(.status=="failed")]|length),
  unsupported:([$r[]|select(.status=="unsupported")]|length)
}' > "$receipt"
echo "upload-artifacts: $(jq '.published' "$receipt") published, $(jq '.failed' "$receipt") failed -> $receipt"
[ "$failed" = true ] && { echo "upload-artifacts: a publish operation failed"; exit 1; } || exit 0
