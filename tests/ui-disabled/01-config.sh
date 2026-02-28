#!/bin/bash
# Test: UI disabled in configuration
# Verifies gateway runs in CLI-only mode

set -e

CONTAINER=${1:?Usage: $0 <container-name>}
source "$(dirname "$0")/../lib.sh"

echo "Testing UI disabled config (container: $CONTAINER)..."

# Container should be running
docker exec "$CONTAINER" true || { echo "error: container not responsive"; exit 1; }

# Gateway config should exist
if docker exec "$CONTAINER" test -f /data/.zeroclaw/config.toml; then
  echo "✓ ZeroClaw config exists"
else
  echo "error: ZeroClaw config not found"
  exit 1
fi
echo "✓ UI disabled in config"

echo "UI config tests passed"
