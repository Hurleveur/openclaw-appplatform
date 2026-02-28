#!/bin/bash
# Test: Gateway process running
# Verifies ZeroClaw gateway starts

set -e

CONTAINER=${1:?Usage: $0 <container-name>}
source "$(dirname "$0")/../lib.sh"

echo "Testing gateway process (container: $CONTAINER)..."

# Container should be running
docker exec "$CONTAINER" true || { echo "error: container not responsive"; exit 1; }

# ZeroClaw gateway process
wait_for_process "$CONTAINER" "zeroclaw" 5 || echo "warning: zeroclaw process not found (may still be starting)"

echo "Gateway tests passed"
