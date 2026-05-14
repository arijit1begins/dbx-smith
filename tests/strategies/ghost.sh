#!/usr/bin/env bash
# shellcheck disable=SC1091
# tests/strategies/ghost.sh - Validation plugin for 'ghost' strategy

set -euo pipefail

box_name="$1"
target_image="$2"

source "$(dirname "${BASH_SOURCE[0]}")/common_asserts.sh"

echo "=== Testing Strategy: ghost ==="
assert_common_setup "ghost" "$box_name" "$target_image"
assert_ghost_identity "$box_name" "false"
assert_common_teardown "$box_name"
echo "=== Strategy ghost OK ==="
