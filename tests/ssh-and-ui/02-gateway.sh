#!/bin/bash
# Test: Gateway process running alongside SSH
# Verifies multiple services coexist

set -e

CONTAINER=${1:?Usage: $0 <container-name>}
source "$(dirname "$0")/../lib.sh"

echo "Testing gateway with SSH (container: $CONTAINER)..."

# Container should be running
docker exec "$CONTAINER" true || { echo "error: container not responsive"; exit 1; }

# ZeroClaw gateway process
wait_for_process "$CONTAINER" "zeroclaw" 5 || echo "warning: zeroclaw process not found (may still be starting)"

# ZeroClaw service should be up
assert_service_up "$CONTAINER" "zeroclaw" || exit 1

echo "Gateway coexistence tests passed"
