#!/usr/bin/env bash
# tests/strategies/common_asserts.sh - Shared validation lifecycle for strategy plugins

set -euo pipefail

# Internal paths for validation
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith"
ALIAS_DIR="$CONFIG_DIR/aliases.d"
REG_DIR="$CONFIG_DIR/registry"

# Helper: execute a command inside a container with correct user context.
# Ghost strategies always use podman exec directly because distrobox enter triggers
# init hooks that mount tmpfs over /home, breaking crun chdir for subsequent entries.
# Non-ghost strategies use dbx-smith (distrobox enter) unless SKIP_BOOTSTRAP is active.
_exec_in_box() {
    local b_name="$1"; shift
    podman start "$b_name" >/dev/null 2>&1 || true
    local cur_usr
    cur_usr=$(id -un)
    local cur_home="${HOME:-/home/$cur_usr}"
    local exec_user="--user $cur_usr --workdir $cur_home/boxes/$b_name"

    if [[ -f "$REG_DIR/${b_name}.conf" ]]; then
        local strategy
        strategy=$(grep "^STRATEGY=" "$REG_DIR/${b_name}.conf" | cut -d= -f2)
        if [[ "$strategy" == ghost* ]]; then
            exec_user="--user ghostuser --workdir /home/ghostuser"
        elif [[ "$strategy" == "standard" ]]; then
            exec_user="--user $cur_usr --workdir $cur_home"
        fi
    fi

    local retries=3
    while [[ $retries -gt 0 ]]; do
        # shellcheck disable=SC2086
        if podman exec $exec_user "$b_name" "$@" </dev/null; then
            return 0
        fi
        sleep 0.5
        ((retries--))
    done
    return 1
}

assert_common_teardown() {
    local b_name="${1:-}"
    if [[ -z "$b_name" ]]; then return 0; fi

    echo "[*] Executing clean teardown for $b_name..."
    timeout 60 dbx-smith-rm --purge "$b_name" >/dev/null 2>&1 || true
    
    # Aggressively ensure low-level podman engine references and dedicated bridges are wiped
    podman rm -f "$b_name" >/dev/null 2>&1 || true
    podman rmi -f "dbx-frozen-${b_name}" >/dev/null 2>&1 || true
    podman network rm -f "dbx-net-${b_name}" >/dev/null 2>&1 || true
}

# Setup global trap removed. Teardown is handled exclusively by slave_runner.sh 
# to ensure diagnostic hooks can inspect the failure state before deletion.

assert_common_setup() {
    local strat="$1"
    local box_name="$2"
    local target_image="$3"

    echo "[*] Ensuring clean slate for $box_name (pre-phase cleanup)..."
    assert_common_teardown "$box_name"

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

    if [[ "${SKIP_BOOTSTRAP:-false}" == "true" ]]; then
        echo "[*] SKIP_BOOTSTRAP active: skipping UI Theme, Zsh Wizard, and Sudo assertions (requires distrobox bootstrap)."
    else
        echo "[*] Validating UI Theme Profile Injection..."
        local payload_content
        local exec_status=0
        # shellcheck disable=SC2015
        payload_content=$(_exec_in_box "$box_name" sh -c 'cat /etc/profile.d/dbx-smith-env.sh' 2>&1) || exec_status=$?
        if ! echo "$payload_content" | grep -qE "_dbx_smith_(precmd|prompt)\(\)"; then
            echo "[!] ERROR: UI Theme payload missing or malformed!"
            echo "Exec status: $exec_status"
            echo "Payload content was:"
            echo "$payload_content"
            exit 1
        fi

        if [[ "$strat" != ghost* ]]; then
            echo "[*] Validating Zsh Newuser Wizard Bypass..."
            if ! (_exec_in_box "$box_name" sh -c 'test -f ~/.zshrc' 2>/dev/null); then
                echo "[!] ERROR: ~/.zshrc missing! Zsh wizard not bypassed."
                exit 1
            fi
        fi

        echo "[*] Validating Passwordless Sudo Privileges..."
        if ! (_exec_in_box "$box_name" sudo -n true >/dev/null 2>&1); then
            echo "[!] ERROR: Sudo is broken or requires password!"
            exit 1
        fi
    fi
}

assert_ghost_identity() {
    local box_name="$1"
    local is_tmpfs="${2:-false}"

    echo "[*] Validating Ghost Identity execution context..."
    local current_user
    current_user=$(_exec_in_box "$box_name" whoami 2>/dev/null | tr -d '\r\n')
    if [[ "$current_user" != "ghostuser" ]]; then
        echo "[!] ERROR: Expected 'ghostuser', but found '$current_user'!"
        exit 1
    fi

    if [[ "$is_tmpfs" == "true" ]]; then
        if [[ "${SKIP_BOOTSTRAP:-false}" == "true" ]]; then
            echo "[*] SKIP_BOOTSTRAP active: skipping filesystem isolation assertions (requires init hooks via bootstrap)."
        else
            echo "[*] Validating Host Home inaccessible to Ghost identity..."
            if (_exec_in_box "$box_name" ls "/run/host/home/$USER" >/dev/null 2>&1); then
                echo "[!] ERROR: Ghost user can access host home directory! Isolation failure."
                exit 1
            fi

            echo "[*] Validating tmpfs home isolation (host user folder hidden)..."
            if (_exec_in_box "$box_name" test -f "/home/$USER/.bashrc" >/dev/null 2>&1); then
                echo "[!] ERROR: Host home directory '$USER' leaked into tmpfs!"
                exit 1
            fi
        fi
    fi
}

assert_network_offline() {
    local box_name="$1"

    if [[ "${SKIP_BOOTSTRAP:-false}" == "true" ]]; then
        echo "[*] SKIP_BOOTSTRAP active: skipping airgap assertion (requires freeze/rebuild cycle)."
        return 0
    fi

    echo "[*] Validating strict Airgap network disconnection..."
    if (_exec_in_box "$box_name" sh -c 'command -v curl >/dev/null && curl -s --connect-timeout 3 https://example.com || ping -c 1 -W 1 8.8.8.8' >/dev/null 2>&1); then
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
