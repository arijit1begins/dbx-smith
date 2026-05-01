#!/usr/bin/env bash
# test.sh - Master test runner for dbx-smith

set -euo pipefail

echo "========================================"
echo " Running DbxSmith Test Suite"
echo "========================================"

# Run unit tests first (fast)
for test_file in tests/*_unit_*.sh; do
    if [ -x "$test_file" ] || [ -f "$test_file" ]; then
        bash "$test_file"
    fi
done

echo ""
echo "========================================"
echo " Unit Tests Passed!"
echo "========================================"

if [[ "${1:-}" == "--full" ]] || [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    echo "Running Full Integration Matrix..."
    bash tests/04_matrix_runner.sh
else
    echo "Skipping integration tests. Use './test.sh --full' to run the matrix (or run in CI)."
fi

