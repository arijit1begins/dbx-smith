#!/usr/bin/env bash
# tests/strategies/ghost-isolated-net.sh - Validation plugin for 'ghost-isolated-net' strategy

set -euo pipefail

box_name="$1"
target_image="$2"

source "$(dirname "${BASH_SOURCE[0]}")/common_asserts.sh"

echo "=== Testing Strategy: ghost-isolated-net ==="
assert_common_setup "ghost-isolated-net" "$box_name" "$target_image"
assert_ghost_identity "$box_name" "true"
assert_isolated_bridge "$box_name"
assert_common_teardown "$box_name"
echo "=== Strategy ghost-isolated-net OK ==="
