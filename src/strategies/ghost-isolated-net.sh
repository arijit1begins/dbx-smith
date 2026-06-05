#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source=src/strategies/ghost.sh
# shellcheck disable=SC1091
source "${SRC_DIR}/strategies/ghost.sh"

strategy_ghost_isolated_net_get_flags() {
    local image name payload
    name="$1" image="$2" payload="$3"
    local init_hook
    init_hook="echo '$payload' | base64 -d | sh"

    podman network inspect "dbx-net-${name}" >/dev/null 2>&1 \
        || podman network create "dbx-net-${name}" >/dev/null

    local _su_install_script
    _su_install_script="command -v su >/dev/null 2>&1 || (command -v $DISTRO_PKGMGR >/dev/null 2>&1 && $DISTRO_PKGMGR install -y $DISTRO_PKG_SU 2>/dev/null) || true"
    local su_install_hook
    su_install_hook="echo '$(printf '%s' "$_su_install_script" | base64 | tr -d '\n')' | base64 -d | bash"

    local isolate_hook
    isolate_hook="mkdir -p /tmp/save_home && mount --bind \"$HOME_BASE/$name\" /tmp/save_home && umount -l /home/$USER 2>/dev/null || true; mount -t tmpfs tmpfs /home; mount -t tmpfs tmpfs /run/host/home 2>/dev/null || true; mkdir -p /home/ghostuser; mount --bind /tmp/save_home /home/ghostuser && umount /tmp/save_home; chown ghostuser:ghostuser /home/ghostuser 2>/dev/null || true"
    
    # shellcheck disable=SC2034
    DBX_FLAGS=(--name "$name" --image "$image" --hostname ghost-shell --home "$HOME_BASE/$name" --unshare-all --additional-flags "--network dbx-net-${name}" --init-hooks "$su_install_hook; $isolate_hook; $init_hook")
}

strategy_ghost_isolated_net_finalize() {
    local image name strategy usr_alias usr_bind
    name="$1" strategy="$2" image="$3" usr_alias="$4" usr_bind="$5"

    echo "Ghost-isolated-net strategy detected. Bootstrapping container..."
    mkdir -p "$HOME_BASE/$name"
    if [[ "${SKIP_BOOTSTRAP:-false}" != "true" ]]; then
        distrobox enter --no-workdir --additional-flags "--workdir /" "$name" -- true </dev/null || true
    else
        echo "[SKIP_BOOTSTRAP] Skipping distrobox first-entry bootstrap. Starting container directly..."
        podman start "$name" >/dev/null 2>&1 || true
    fi

    _create_ghostuser "$name"

    write_manifest "$name" "$strategy" "$image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
