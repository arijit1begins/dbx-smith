#!/usr/bin/env bash
# tests/strategies/common_asserts.sh - Shared validation lifecycle for strategy plugins

set -euo pipefail

# Internal paths for validation
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith"
ALIAS_DIR="$CONFIG_DIR/aliases.d"
REG_DIR="$CONFIG_DIR/registry"

assert_common_setup() {
    local strat="$1"
    local box_name="$2"
    local target_image="$3"

    echo "[*] Ensuring clean slate for $box_name..."
    dbx-smith-rm --purge "$box_name" >/dev/null 2>&1 || true

    echo "[*] Provisioning $box_name (alias: dbs-$strat)..."
    dbx-smith-spin "$strat" "$box_name" "$target_image" "dbs-$strat"

    echo "[*] Validating container existence in distrobox list..."
    if ! distrobox list --no-color | awk -v b="$box_name" 'NR>1 && $3==b {found=1} END {exit !found}'; then
        echo "[!] ERROR: $box_name not found in distrobox list!"
        exit 1
    fi

    echo "[*] Validating Manifest & Alias Persistence..."
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

    echo "[*] Validating UI Theme Profile Injection..."
    local payload_content
    payload_content=$(cd / && dbx-smith "$box_name" -- sh -c 'cat /etc/profile.d/dbx-smith-env.sh' 2>/dev/null || true)
    if ! echo "$payload_content" | grep -qE "_dbx_smith_(precmd|prompt)\(\)"; then
        echo "[!] ERROR: UI Theme payload missing or malformed!"
        exit 1
    fi

    echo "[*] Validating Zsh Newuser Wizard Bypass..."
    if ! (cd / && dbx-smith "$box_name" -- sh -c 'test -f ~/.zshrc' 2>/dev/null); then
        echo "[!] ERROR: ~/.zshrc missing! Zsh wizard not bypassed."
        exit 1
    fi

    echo "[*] Validating Passwordless Sudo Privileges..."
    if ! (cd / && dbx-smith "$box_name" -- sudo -n true >/dev/null 2>&1); then
        echo "[!] ERROR: Sudo is broken or requires password!"
        exit 1
    fi
}

assert_ghost_identity() {
    local box_name="$1"
    local is_tmpfs="${2:-false}"

    echo "[*] Validating Ghost Identity execution context..."
    local current_user
    current_user=$(dbx-smith "$box_name" -- whoami | tr -d '\r\n')
    if [[ "$current_user" != "ghostuser" ]]; then
        echo "[!] ERROR: Expected 'ghostuser', but found '$current_user'!"
        exit 1
    fi

    echo "[*] Validating Host Home inaccessible to Ghost identity..."
    if (cd / && dbx-smith "$box_name" -- ls "/run/host/home/$USER" >/dev/null 2>&1); then
        echo "[!] ERROR: Ghost user can access host home directory! Isolation failure."
        exit 1
    fi

    if [[ "$is_tmpfs" == "true" ]]; then
        echo "[*] Validating tmpfs home isolation (host user folder hidden)..."
        if (cd / && dbx-smith "$box_name" -- ls /home/ | grep -q "^${USER}$" 2>/dev/null); then
            echo "[!] ERROR: Host home directory '$USER' leaked into tmpfs!"
            exit 1
        fi
    fi
}

assert_network_offline() {
    local box_name="$1"

    echo "[*] Validating strict Airgap network disconnection..."
    if (cd / && dbx-smith "$box_name" -- sh -c 'command -v curl >/dev/null && curl -s --connect-timeout 3 https://example.com || ping -c 1 -W 1 8.8.8.8' >/dev/null 2>&1); then
        echo "[!] ERROR: Airgapped container has internet access!"
        exit 1
    fi
}

assert_isolated_bridge() {
    local box_name="$1"

    echo "[*] Validating dedicated Podman network bridge assignment..."
    if ! podman network inspect "dbx-net-${box_name}" >/dev/null 2>&1; then
        echo "[!] ERROR: Isolated bridge network 'dbx-net-${box_name}' not found!"
        exit 1
    fi
}

assert_common_teardown() {
    local box_name="$1"

    echo "[*] Executing clean teardown for $box_name..."
    dbx-smith-rm --purge "$box_name" >/dev/null
}
