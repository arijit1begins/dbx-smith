#!/usr/bin/env bash
# shellcheck source=src/strategies/ghost.sh
source "${SRC_DIR}/strategies/ghost.sh"

strategy_ghost_isolated_net_get_flags() {
    local name="$1" image="$2" payload="$3"
    local init_hook="echo '$payload' | base64 -d | sh"

    podman network inspect "dbx-net-${name}" >/dev/null 2>&1 \
        || podman network create "dbx-net-${name}" >/dev/null

    local _su_install_script="command -v su >/dev/null 2>&1 || (command -v $DISTRO_PKGMGR >/dev/null 2>&1 && $DISTRO_PKGMGR install -y $DISTRO_PKG_SU 2>/dev/null) || true"
    local su_install_hook="echo '$(printf '%s' "$_su_install_script" | base64 | tr -d '\n')' | base64 -d | bash"

    local isolate_hook="umount -l /home/$USER 2>/dev/null || true; mount -t tmpfs tmpfs /home; mkdir -p /home/ghostuser; chown ghostuser:ghostuser /home/ghostuser 2>/dev/null || true"
    
    DBX_FLAGS=(--name "$name" --image "$image" --hostname ghost-shell --unshare-all --additional-flags "--network dbx-net-${name}" --init-hooks "$su_install_hook; $isolate_hook; $init_hook")
}

strategy_ghost_isolated_net_finalize() {
    local name="$1" strategy="$2" image="$3" usr_alias="$4" usr_bind="$5"

    echo "Ghost-isolated-net strategy detected. Bootstrapping container..."
    distrobox enter --no-workdir "$name" -- true >/dev/null 2>&1 || true

    _create_ghostuser "$name"

    write_manifest "$name" "$strategy" "$image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
