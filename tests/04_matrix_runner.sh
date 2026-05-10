#!/usr/bin/env bash
# tests/04_matrix_runner.sh - Exhaustive Multi-Distro Integration Test Runner
#
# DESCRIPTION:
#   Iterates through a list of major distributions and runs the full integration
#   test suite against each. This ensures that DbxSmith remains compatible with
#   both Debian/Ubuntu and RHEL/Fedora ecosystems.

set -euo pipefail

# Ensure we are in the root of the repository
cd "$(dirname "$0")/.."

IMAGES=(
    "docker.io/library/ubuntu:latest"
    "registry.fedoraproject.org/fedora:latest"
    "docker.io/library/alpine:latest"
)

echo "==========================================================="
echo " Starting Multi-Distro Matrix Testing"
echo "==========================================================="

for img in "${IMAGES[@]}"; do
    echo -e "\n[MATRIX] Target Image: $img"
    echo "-----------------------------------------------------------"
    
    # Run integration tests. We use a unique prefix for box names to avoid collisions
    # if tests are interrupted.
    TEST_BOX_PREFIX="matrix_$(echo "$img" | cksum | awk '{print $1}')"
    export TEST_BOX_PREFIX
    
    # Note: 03_integration_strategies.sh currently uses hardcoded names.
    # We will modify it slightly to support the prefix if needed, or just run sequentially.
    if ./tests/03_integration_strategies.sh "$img"; then
        echo -e "\n[RESULT] ✅ Integration Tests PASSED for $img"
    else
        echo -e "\n[RESULT] ❌ Integration Tests FAILED for $img"
        exit 1
    fi
done

echo -e "\n==========================================================="
echo " ✅ ALL MATRIX TESTS PASSED!"
echo "==========================================================="
