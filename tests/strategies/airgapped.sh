#!/usr/bin/env bash
# shellcheck disable=SC1091
# tests/strategies/airgapped.sh - Validation plugin for 'airgapped' strategy

set -euo pipefail

box_name="$1"
target_image="$2"

source "$(dirname "${BASH_SOURCE[0]}")/common_asserts.sh"

echo "=== Testing Strategy: airgapped ==="
assert_common_setup "airgapped" "$box_name" "$target_image"
assert_network_offline "$box_name"
assert_common_teardown "$box_name"
echo "=== Strategy airgapped OK ==="
