#!/usr/bin/env bash
# test_strategies.sh - Automated Integration Tests / DbxSmith
#
# DESCRIPTION:
#   Runs automated integration tests for each container strategy, ensuring that
#   networking, profiling, and lifecycle commands (spin, rm) work properly.
set -euo pipefail

# Ensure binaries are in PATH
export PATH="${PREFIX:-$HOME/.local}/bin:$PATH"

# Internal paths for validation
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith"
ALIAS_DIR="$CONFIG_DIR/aliases.d"
REG_DIR="$CONFIG_DIR/registry"

# 1. Install the suite first (respects PREFIX if set in CI)
# This ensures binaries and the config-based core are available.
make install >/dev/null

# 2. Source the runtime core
# We source from the source tree to ensure we are testing the current code changes.
# shellcheck source=src/dbx-smith.sh
source "src/dbx-smith.sh"

TEST_IMAGE="${1:-docker.io/library/alpine}"

echo "========================================"
echo " Starting Automated Strategy Tests"
echo " Target Image: $TEST_IMAGE"
echo "========================================"

strategies=("standard" "airgapped" "ghost" "isolated-net" "ghost-isolated-net" "ghost-airgapped")

for strat in "${strategies[@]}"; do
    box_name="test_${strat}"
    echo -e "\n---> Testing Strategy: ${strat} <---"
    
    # 1. Ensure clean slate
    dbx-smith-rm --purge "$box_name" >/dev/null 2>&1 || true

    # 2. Provision with an alias for validation
    echo "[*] Provisioning $box_name (alias: dbs-$strat)..."
    dbx-smith-spin "$strat" "$box_name" "$TEST_IMAGE" "dbs-$strat" >/dev/null

    # 3. Validation: Check if it exists in list
    if ! distrobox list --no-color | awk -v b="$box_name" 'NR>1 && $3==b {found=1} END {exit !found}'; then
        echo "[!] ERROR: $box_name not found in distrobox list!"
        exit 1
    fi
    echo "[*] Validation Passed: Container exists."

    # 4. Validation: Check Manifest & Alias Persistence
    if [[ ! -f "$REG_DIR/${box_name}.conf" ]]; then
        echo "[!] ERROR: Registry manifest missing for $box_name!"
        exit 1
    fi
    if [[ ! -f "$ALIAS_DIR/${box_name}.sh" ]]; then
        echo "[!] ERROR: Alias fragment missing for $box_name!"
        exit 1
    fi
    if ! grep -q "alias dbs-$strat=" "$ALIAS_DIR/${box_name}.sh"; then
        echo "[!] ERROR: Alias 'dbs-$strat' not correctly registered in $ALIAS_DIR/${box_name}.sh"
        exit 1
    fi
    echo "[*] Validation Passed: Manifest and Alias persisted."

    # 5. Validation: Ghost Identity Check
    if [[ "$strat" == ghost* ]]; then
        echo "[*] Checking Ghost Identity..."
        current_user=$(dbx-smith "$box_name" -- whoami | tr -d '\r\n')
        if [[ "$current_user" != "ghostuser" ]]; then
            echo "[!] ERROR: Expected 'ghostuser', but found '$current_user'!"
            exit 1
        fi
        echo "[*] Validation Passed: Running as ghostuser."
    fi

    # 6. Validation: Test Profile Injection
    echo "[*] Checking Profile Injection..."
    if (cd / && dbx-smith "$box_name" -- sh -c 'cat /etc/profile.d/dbx-smith-env.sh') | grep -q "export PS1="; then
        echo "[*] Validation Passed: UI Theme payload injected successfully."
    else
        echo "[!] ERROR: UI Theme payload missing!"
        exit 1
    fi

    # 7. Validation: Network Boundary Checks
    if [[ "$strat" == "airgapped" || "$strat" == "ghost-airgapped" ]]; then
        echo "[*] Testing Airgap strict isolation..."
        if (cd / && dbx-smith "$box_name" -- ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1); then
            echo "[!] ERROR: Airgapped container has internet access!"
            exit 1
        else
            echo "[*] Validation Passed: Container is strictly offline."
        fi
    fi

    if [[ "$strat" == "isolated-net" || "$strat" == "ghost-isolated-net" ]]; then
        echo "[*] Testing isolated-net bridge exists..."
        if podman network inspect "dbx-net-${box_name}" >/dev/null 2>&1; then
            echo "[*] Validation Passed: Isolated bridge network is active."
        else
            echo "[!] ERROR: Isolated bridge network not found!"
            exit 1
        fi
    fi

    # 8. Teardown
    echo "[*] Tearing down $box_name..."
    dbx-smith-rm --purge "$box_name" >/dev/null

    echo "--- Strategy ${strat} OK ---"
done

echo -e "\n========================================"
echo " Running Extra Integration Scenarios"
echo "========================================"

# 9. Duplicate Guard Check
echo "[*] Testing Duplicate Guard..."
dbx-smith-spin standard "duplicate_box" "$TEST_IMAGE" >/dev/null
if dbx-smith-spin standard "duplicate_box" "$TEST_IMAGE" >/dev/null 2>&1; then
    echo "[!] ERROR: Duplicate box creation should have failed!"
    exit 1
fi
dbx-smith-rm --purge "duplicate_box" >/dev/null
echo "[*] Validation Passed: Duplicate creation prevented."

# 10. Multi-Box Teardown Check
echo "[*] Testing Multi-Box Teardown..."
dbx-smith-spin standard "box1" "$TEST_IMAGE" >/dev/null
dbx-smith-spin standard "box2" "$TEST_IMAGE" >/dev/null
dbx-smith-rm --purge "box1" "box2" >/dev/null
if distrobox list --no-color | grep -qE "box1|box2"; then
    echo "[!] ERROR: One or more boxes remained after multi-box teardown!"
    exit 1
fi
echo "[*] Validation Passed: Multi-box teardown successful."

# 11. Uninstallation Validation
echo "[*] Testing Uninstallation..."
BIN_DIR="${PREFIX:-$HOME/.local}/bin"
dbx-smith-uninstall >/dev/null
if [[ -f "$BIN_DIR/dbx-smith-spin" || -d "$CONFIG_DIR" ]]; then
    echo "[!] ERROR: Uninstallation failed to remove binaries or config!"
    echo "    Check: $BIN_DIR/dbx-smith-spin"
    echo "    Check: $CONFIG_DIR"
    exit 1
fi
echo "[*] Validation Passed: Uninstallation successful."

echo -e "\n========================================"
echo " ✅ ALL INTEGRATION TESTS PASSED!"
echo "========================================"
