#!/usr/bin/env bash
# tests/strategies/standard.sh - Validation plugin for 'standard' strategy

set -euo pipefail

box_name="$1"
target_image="$2"

source "$(dirname "${BASH_SOURCE[0]}")/common_asserts.sh"

echo "=== Testing Strategy: standard ==="
assert_common_setup "standard" "$box_name" "$target_image"
assert_common_teardown "$box_name"
echo "=== Strategy standard OK ==="
