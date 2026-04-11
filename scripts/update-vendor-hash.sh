#!/usr/bin/env bash
set -euo pipefail

FLAKE_FILE="$(cd "$(dirname "$0")/.." && pwd)/flake.nix"

# Replace the current vendorHash with an empty string to trigger a hash mismatch
sed -i 's/vendorHash = "sha256-[^"]*"/vendorHash = ""/' "$FLAKE_FILE"

echo "Building to determine new vendorHash..."
BUILD_OUTPUT=$(nix build .#scion 2>&1 || true)
NEW_HASH=$(echo "$BUILD_OUTPUT" | grep 'got:' | awk '{print $2}')

if [[ -z "$NEW_HASH" ]]; then
  echo "Error: could not determine new vendorHash. The build may have succeeded with an empty hash." >&2
  git checkout -- "$FLAKE_FILE"
  exit 1
fi

sed -i "s|vendorHash = \"\"|vendorHash = \"${NEW_HASH}\"|" "$FLAKE_FILE"

echo "Updated vendorHash to ${NEW_HASH}"
