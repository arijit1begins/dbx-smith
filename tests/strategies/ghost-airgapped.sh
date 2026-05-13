#!/usr/bin/env bash
# tests/strategies/ghost-airgapped.sh - Validation plugin for 'ghost-airgapped' strategy

set -euo pipefail

box_name="$1"
target_image="$2"

source "$(dirname "${BASH_SOURCE[0]}")/common_asserts.sh"

echo "=== Testing Strategy: ghost-airgapped ==="
assert_common_setup "ghost-airgapped" "$box_name" "$target_image"
assert_ghost_identity "$box_name" "true"
assert_network_offline "$box_name"
assert_common_teardown "$box_name"
echo "=== Strategy ghost-airgapped OK ==="
