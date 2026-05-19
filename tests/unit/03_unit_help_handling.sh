#!/usr/bin/env bash
# tests/unit/03_unit_help_handling.sh - Fast unit test for dbx-smith help option

set -euo pipefail

echo "Running Help Handling Unit Test..."

# Resolve repository root and source dbx-smith.sh
REPO_ROOT=$(dirname "$(dirname "$(dirname "$(readlink -f "$0")")")")
source "$REPO_ROOT/src/dbx-smith.sh"

# Test --help option
output_long=$(dbx-smith --help)
echo "Output of 'dbx-smith --help':"
echo "$output_long"

if [[ ! "$output_long" == *"usage: dbx-smith <box_name|list|dash> [args...]"* ]]; then
    echo "❌ Error: usage message not found in '--help' output."
    exit 1
fi

if [[ ! "$output_long" == *"list"* ]] || [[ ! "$output_long" == *"dash"* ]] || [[ ! "$output_long" == *"<box_name>"* ]]; then
    echo "❌ Error: Subcommands list not found in '--help' output."
    exit 1
fi

# Test -h option
output_short=$(dbx-smith -h)
echo "Output of 'dbx-smith -h':"
echo "$output_short"

if [[ ! "$output_short" == *"usage: dbx-smith <box_name|list|dash> [args...]"* ]]; then
    echo "❌ Error: usage message not found in '-h' output."
    exit 1
fi

echo "✅ Help Handling Test Passed!"
