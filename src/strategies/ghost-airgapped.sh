#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1091
source "${SRC_DIR}/strategies/ghost.sh"

# Internal helpers for airgap hooks
_get_ghost_airgap_isolate_hook() {
    printf 'umount -l /home/%s 2>/dev/null || true; mount -t tmpfs tmpfs /home; mkdir -p /home/ghostuser; chown ghostuser:ghostuser /home/ghostuser 2>/dev/null || true' "$USER"
}

_get_ghost_airgap_sever_hook() {
    printf "if [ -f /etc/dbx_airgap_active ]; then for iface in \$(ls /sys/class/net/ 2>/dev/null); do if [ \"\$iface\" != \"lo\" ]; then ip link set \"\$iface\" down 2>/dev/null || true; fi; done; fi"
}

strategy_ghost_airgapped_get_flags() {
    local image name payload
    name="$1" image="$2" payload="$3"
    
    local init_hook
    init_hook="echo '$payload' | base64 -d | sh"

    local _su_install_script
    _su_install_script="command -v su >/dev/null 2>&1 || (command -v $DISTRO_PKGMGR >/dev/null 2>&1 && $DISTRO_PKGMGR install -y $DISTRO_PKG_SU 2>/dev/null) || true"
    local su_install_hook
    su_install_hook="echo '$(printf '%s' "$_su_install_script" | base64 | tr -d '\n')' | base64 -d | bash"

    local isolate_hook
    isolate_hook=$(_get_ghost_airgap_isolate_hook)
    local airgap_hook
    airgap_hook=$(_get_ghost_airgap_sever_hook)

    # shellcheck disable=SC2034
    DBX_FLAGS=(--name "$name" --image "$image" --hostname ghost-shell --home "$HOME_BASE/$name" --unshare-all --init-hooks "$su_install_hook; $isolate_hook; $airgap_hook; $init_hook")
}

strategy_ghost_airgapped_finalize() {
    local image name strategy usr_alias usr_bind
    name="$1" strategy="$2" image="$3" usr_alias="$4" usr_bind="$5"

    echo "Ghost-airgapped strategy detected. Bootstrapping container with temporary internet access..."
    local pkg_name="iproute2"
    [[ "$image" == *fedora* ]] && pkg_name="iproute"
    
    distrobox enter --no-workdir "$name" -- bash -c "sudo $DISTRO_PKGMGR update >/dev/null 2>&1 || true; sudo $DISTRO_PKGMGR install -y $pkg_name >/dev/null 2>&1 || true"
    distrobox enter --no-workdir "$name" -- true >/dev/null 2>&1 || true

    _create_ghostuser "$name"

    echo "Freezing provisioned identity and applying physical network isolation..."
    distrobox stop "$name" --yes >/dev/null 2>&1 || true
    local freeze_image="dbx-frozen-${name}"
    podman commit "$name" "$freeze_image" >/dev/null
    
    distrobox rm "$name" --force >/dev/null 2>&1 || true
    
    echo "Re-spawning isolated ghost container with '--network none'..."
    local isolate_hook
    isolate_hook=$(_get_ghost_airgap_isolate_hook)
    local airgap_hook
    airgap_hook=$(_get_ghost_airgap_sever_hook)

    distrobox create --name "$name" --image "$freeze_image" --hostname ghost-shell --home "$HOME_BASE/$name" --unshare-all --additional-flags "--network none" --init-hooks "$isolate_hook; $airgap_hook" --yes >/dev/null
    
    write_manifest "$name" "$strategy" "$freeze_image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
