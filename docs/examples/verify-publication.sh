#!/usr/bin/env bash
set -euo pipefail
# Post-publish check (both backends). Publishers exit non-zero on a real
# upload failure, so a clean receipt means the bytes moved. The only
# allowed non-published ops are the two documented v1 gaps: pkg_generic
# and the oci-archive container leg.

r="${RECEIPT:?RECEIPT not set}"
jq -e '
  .failed == 0 and .published >= 1
  and ([ .results[]
         | select(.status != "published")
         | select(((.destination | startswith("pkg_generic"))
                   or (.type == "oci" and .format == "oci-archive")) | not)
       ] | length == 0)
' "$r" >/dev/null \
  || { echo "verify-publication: unexpected non-published operations" >&2; jq '.results' "$r" >&2; exit 1; }

echo "verify-publication: OK ($(jq -r .published "$r") published, $(jq -r .unsupported "$r") documented gap(s))"
