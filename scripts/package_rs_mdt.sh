#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$REPO_ROOT/dist"
TMP_DIR="$DIST_DIR/rs_mdt"

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cp -R "$REPO_ROOT/fivem_mdt"/* "$TMP_DIR"/

mkdir -p "$DIST_DIR"
(
  cd "$DIST_DIR"
  rm -f rs_mdt.zip
  zip -r rs_mdt.zip rs_mdt >/dev/null
)

echo "Created: $DIST_DIR/rs_mdt.zip"
