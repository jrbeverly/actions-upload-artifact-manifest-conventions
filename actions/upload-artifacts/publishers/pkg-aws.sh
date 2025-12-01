#!/usr/bin/env bash
set -euo pipefail
# pkg/aws: CodeArtifact. generic has no feed concept -> v1 gap, exit 3.
op="${1:?usage: pkg-aws.sh <op-json>}"
f() { jq -r "$1" <<<"$op"; }
path="$(f .path)"; fmt="$(f .target.format)"
domain="$(f .target.domain)"; repo="$(f .target.repository)"
[ -f "$path" ] || { echo "pkg-aws: missing $path" >&2; exit 1; }
[ "$fmt" = generic ] && { echo "pkg-aws: generic feed is a v1 gap; unsupported"; exit 3; }

token="$(aws codeartifact get-authorization-token --domain "$domain" --query authorizationToken --output text)"
endpoint="$(aws codeartifact get-repository-endpoint --domain "$domain" --repository "$repo" --format "$fmt" --query repositoryEndpoint --output text)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

case "$fmt" in
  nuget)
    # CodeArtifact is a NuGet v3 feed: push to <endpoint>v3/index.json with
    # basic auth (user "aws"), not --api-key; the bare endpoint 404s.
    cat > "$work/nuget.config" <<XML
<?xml version="1.0"?>
<configuration>
  <packageSources><add key="ca" value="${endpoint%/}/v3/index.json" /></packageSources>
  <packageSourceCredentials><ca>
    <add key="Username" value="aws" />
    <add key="ClearTextPassword" value="$token" />
  </ca></packageSourceCredentials>
</configuration>
XML
    dotnet nuget push "$path" --source ca --api-key az --configfile "$work/nuget.config"
    ;;
  pypi)
    # Run twine as a module so a pip --user install need not be on PATH.
    python3 -c 'import twine' 2>/dev/null || { echo "pkg-aws: twine not importable" >&2; exit 1; }
    cat > "$work/.pypirc" <<EOF
[distutils]
index-servers = ca
[ca]
repository = $endpoint
username = aws
password = $token
EOF
    python3 -m twine upload --config-file "$work/.pypirc" --repository ca --non-interactive "$path"
    ;;
  *) echo "pkg-aws: unknown format $fmt" >&2; exit 1 ;;
esac
echo "pkg-aws: $(f .file_name) -> $fmt"
