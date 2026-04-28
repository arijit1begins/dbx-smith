#!/usr/bin/env bash
# test_strategies.sh - Automated Integration Tests / DbxSmith
#
# DESCRIPTION:
#   Runs automated integration tests for each container strategy, ensuring that
#   networking, profiling, and lifecycle commands (spin, rm) work properly.
set -euo pipefail

# Ensure binaries are in PATH
export PATH="${PREFIX:-$HOME/.local}/bin:$PATH"

make install >/dev/null

echo "========================================"
echo " Starting Automated Strategy Tests"
echo "========================================"

strategies=("standard" "airgapped" "ghost" "isolated-net")

for strat in "${strategies[@]}"; do
    box_name="test_${strat}"
    echo -e "\n---> Testing Strategy: ${strat} <---"
    
    # 1. Ensure clean slate
    dbx-smith-rm --purge "$box_name" >/dev/null 2>&1 || true

    # 2. Provision
    echo "[*] Provisioning $box_name..."
    dbx-smith-spin "$strat" "$box_name" docker.io/library/alpine >/dev/null

    # 3. Validation: Check if it exists in list
    if ! distrobox list --no-color | awk -v b="$box_name" 'NR>1 && $3==b {found=1} END {exit !found}'; then
        echo "[!] ERROR: $box_name not found in distrobox list!"
        exit 1
    fi
    echo "[*] Validation Passed: Container exists."

    # 4. Validation: Test Profile Injection
    echo "[*] Checking Profile Injection..."
    if distrobox enter "$box_name" -- sh -c 'cat /etc/profile.d/dbx-smith-env.sh' | grep -q "export PS1="; then
        echo "[*] Validation Passed: UI Theme payload injected successfully."
    else
        echo "[!] ERROR: UI Theme payload missing!"
        exit 1
    fi

    # 5. Validation: Network Boundary Checks
    if [[ "$strat" == "airgapped" ]]; then
        echo "[*] Testing Airgap strict isolation..."
        if distrobox enter "$box_name" -- ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
            echo "[!] ERROR: Airgapped container has internet access!"
            exit 1
        else
            echo "[*] Validation Passed: Container is strictly offline."
        fi
    fi

    if [[ "$strat" == "isolated-net" ]]; then
        echo "[*] Testing isolated-net bridge exists..."
        if podman network inspect "dbx-net-${box_name}" >/dev/null 2>&1; then
            echo "[*] Validation Passed: Isolated bridge network is active."
        else
            echo "[!] ERROR: Isolated bridge network not found!"
            exit 1
        fi
    fi

    # 6. Teardown
    echo "[*] Tearing down $box_name..."
    dbx-smith-rm --purge "$box_name" >/dev/null

    echo "--- Strategy ${strat} OK ---"
done

echo -e "\n========================================"
echo " All Strategies Passed!"
echo "========================================"
