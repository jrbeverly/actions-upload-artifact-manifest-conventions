#!/usr/bin/env bash
set -euo pipefail

# tests/generate/generate-nuget.sh
#
# Generate a synthetic NuGet package for end-to-end validation.
# Produces a minimal *.nupkg via dotnet pack so the output is structurally
# valid and publishable through dotnet nuget push to CodeArtifact NuGet.

out_dir="${1:?usage: generate-nuget.sh <output-dir> [name] [version]}"
name="${2:-Demo.Lib}"
version="${3:-3.1.0}"

fail() { echo "generate-nuget: $*" >&2; exit 1; }

command -v dotnet >/dev/null 2>&1 || fail "dotnet is required but was not found on PATH."

mkdir -p "$out_dir"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

proj_dir="${work}/${name}"
mkdir -p "$proj_dir"

cat > "${proj_dir}/${name}.csproj" <<CSPROJ
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Version>${version}</Version>
    <Description>Synthetic package for end-to-end artifact validation.</Description>
    <Authors>validation</Authors>
    <PackageId>${name}</PackageId>
  </PropertyGroup>
</Project>
CSPROJ

cat > "${proj_dir}/Placeholder.cs" <<'CS'
namespace Demo.Lib;

public class Placeholder
{
    public static string Message => "synthetic-nuget-artifact";
}
CS

echo "generate-nuget: packing ${name} ${version}"
dotnet pack "$proj_dir" \
  --configuration Release \
  --output "$out_dir" \
  --nologo \
  || fail "dotnet pack failed."

# dotnet pack produces Demo.Lib.3.1.0.nupkg — matches the discover
# convention of <Package>.<version>.nupkg.

nupkg="$(find "$out_dir" -maxdepth 1 -name "${name}.${version}.nupkg" -print -quit)"
[ -n "$nupkg" ] || fail "nupkg was not produced; expected ${name}.${version}.nupkg in ${out_dir}"

echo "generate-nuget: produced ${nupkg}"
