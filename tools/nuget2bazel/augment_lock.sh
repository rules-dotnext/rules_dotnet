#!/usr/bin/env bash
# nuget2bazel — Augment a NuGet packages.lock.json with .nupkg file hashes.
#
# The standard NuGet lock file contains `contentHash` values that are hashes of
# the package *content*, not the .nupkg archive file itself. Bazel's
# repository_ctx.download() needs the hash of the downloaded file for integrity
# checking. This tool downloads each .nupkg, computes its SHA-512 hash, and
# writes back the lock file with `nupkgSha512` fields added.
#
# Usage:
#   ./augment_lock.sh <packages.lock.json> [source_url]
#
# Requirements: curl, jq, sha512sum, base64
#
# Output: Writes the augmented lock file to stdout. Redirect to overwrite:
#   ./augment_lock.sh packages.lock.json > packages.lock.augmented.json

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <packages.lock.json> [source_url]" >&2
    exit 1
fi

LOCK_FILE="$1"
SOURCE="${2:-https://api.nuget.org/v3/index.json}"

if [ ! -f "$LOCK_FILE" ]; then
    echo "Error: Lock file not found: $LOCK_FILE" >&2
    exit 1
fi

# Resolve the PackageBaseAddress from the V3 service index
BASE_URL=$(curl -sS "$SOURCE" | jq -r '.resources[] | select(.["@type"] == "PackageBaseAddress/3.0.0") | .["@id"]')

if [ -z "$BASE_URL" ]; then
    echo "Error: Could not resolve PackageBaseAddress from $SOURCE" >&2
    exit 1
fi

# Ensure trailing slash
if [[ ! "$BASE_URL" == */ ]]; then
    BASE_URL="${BASE_URL}/"
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Build a mapping of package_id|version -> sha512 hash
declare -A HASHES

# Extract unique id|version pairs from the lock file
jq -r '.dependencies | to_entries[] | .value | to_entries[] | [.key, .value.resolved] | @tsv' "$LOCK_FILE" | \
  sort -u | while IFS=$'\t' read -r id version; do
    id_lower=$(echo "$id" | tr '[:upper:]' '[:lower:]')
    version_lower=$(echo "$version" | tr '[:upper:]' '[:lower:]')
    url="${BASE_URL}${id_lower}/${version_lower}/${id_lower}.${version_lower}.nupkg"

    nupkg_file="${TMPDIR}/${id_lower}.${version_lower}.nupkg"

    echo "Downloading ${id}@${version}..." >&2
    if curl -sSL -o "$nupkg_file" "$url"; then
        hash=$(openssl dgst -sha512 -binary "$nupkg_file" | base64 -w0)
        echo "${id}|${version}|sha512-${hash}"
    else
        echo "Warning: Failed to download ${id}@${version} from ${url}" >&2
    fi
    rm -f "$nupkg_file"
done > "${TMPDIR}/hashes.txt"

# Now augment the lock file with nupkgSha512 fields using jq
# Read hashes into a jq-friendly format
HASH_JSON=$(awk -F'|' '{printf "%s|%s\t%s\n", $1, $2, $3}' "${TMPDIR}/hashes.txt" | \
  jq -Rn '[inputs | split("\t") | {key: .[0], value: .[1]}] | from_entries')

jq --argjson hashes "$HASH_JSON" '
  .dependencies |= with_entries(
    .value |= with_entries(
      .value += {
        nupkgSha512: ($hashes[(.key + "|" + .value.resolved)] // "")
      }
    )
  )
' "$LOCK_FILE"
