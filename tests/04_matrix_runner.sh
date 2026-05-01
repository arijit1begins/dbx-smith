#!/usr/bin/env bash
# tests/04_matrix_runner.sh - Executes integration tests across multiple distributions

set -euo pipefail

IMAGES=(
    "docker.io/library/alpine:latest"
    "registry.fedoraproject.org/fedora:latest"
    "docker.io/library/ubuntu:latest"
)

echo "========================================"
echo " Starting DbxSmith Matrix Testing"
echo "========================================"

FAILED=0

for img in "${IMAGES[@]}"; do
    echo "----------------------------------------"
    echo " Testing Matrix Node: $img"
    echo "----------------------------------------"
    if ! bash tests/03_integration_strategies.sh "$img"; then
        echo "[!] ERROR: Strategy testing failed for $img"
        FAILED=1
    fi
done

echo "========================================"
if [ "$FAILED" -eq 0 ]; then
    echo "✅ ALL MATRIX TESTS PASSED!"
    exit 0
else
    echo "❌ MATRIX TESTS FAILED!"
    exit 1
fi
