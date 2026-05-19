#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1091
source "${SRC_DIR}/strategies/ghost.sh"

# Internal helpers for airgap hooks
_get_ghost_airgap_isolate_hook() {
    printf 'umount -l /home/%s 2>/dev/null || true; mount -t tmpfs tmpfs /home; mount -t tmpfs tmpfs /run/host/home 2>/dev/null || true; mkdir -p /home/ghostuser %s; chown ghostuser:ghostuser /home/ghostuser 2>/dev/null || true' "$USER" "$HOME_BASE/${1:-}"
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
    isolate_hook=$(_get_ghost_airgap_isolate_hook "$name")
    local airgap_hook
    airgap_hook=$(_get_ghost_airgap_sever_hook)

    local extra_args=()
    if [[ "${SKIP_BOOTSTRAP:-false}" == "true" ]]; then
        extra_args+=(--unshare-all --additional-flags "--network none")
    fi

    # shellcheck disable=SC2034
    DBX_FLAGS=(--name "$name" --image "$image" --hostname ghost-shell --home "$HOME_BASE/$name" "${extra_args[@]}" --init-hooks "$su_install_hook; $isolate_hook; $airgap_hook; $init_hook")
}

strategy_ghost_airgapped_finalize() {
    local image name strategy usr_alias usr_bind
    name="$1" strategy="$2" image="$3" usr_alias="$4" usr_bind="$5"

    if [[ "${SKIP_BOOTSTRAP:-false}" == "true" ]]; then
        echo "[SKIP_BOOTSTRAP] Ghost-airgapped: skipping bootstrap, package install, and freeze/rebuild cycle."
        podman start "$name" >/dev/null 2>&1 || true
        _create_ghostuser "$name"
        write_manifest "$name" "$strategy" "$image"
        register_shortcuts "$name" "$usr_alias" "$usr_bind"
        return 0
    fi

    echo "Ghost-airgapped strategy detected. Bootstrapping container with temporary internet access..."
    local pkg_name="iproute2"
    [[ "$image" == *fedora* ]] && pkg_name="iproute"
    
    distrobox enter --no-workdir --additional-flags "--workdir /" "$name" -- bash -c "sudo $DISTRO_PKGMGR update >/dev/null 2>&1 || true; sudo $DISTRO_PKGMGR install -y $pkg_name >/dev/null 2>&1 || true" </dev/null
    distrobox enter --no-workdir --additional-flags "--workdir /" "$name" -- true </dev/null || true

    _create_ghostuser "$name"

    echo "Freezing provisioned identity and applying physical network isolation..."
    podman stop -t 2 "$name" >/dev/null 2>&1 || true
    local freeze_image="dbx-frozen-${name}"
    podman commit "$name" "$freeze_image" >/dev/null
    
    podman rm -f "$name" >/dev/null 2>&1 || true
    
    echo "Re-spawning isolated ghost container with '--network none'..."
    local isolate_hook
    isolate_hook=$(_get_ghost_airgap_isolate_hook "$name")
    local airgap_hook
    airgap_hook=$(_get_ghost_airgap_sever_hook)

    distrobox create --name "$name" --image "$freeze_image" --hostname ghost-shell --home "$HOME_BASE/$name" --unshare-all --additional-flags "--network none" --init-hooks "$isolate_hook; $airgap_hook" --yes >/dev/null
    
    # Start the rebuilt container so assertions can use podman exec
    mkdir -p "$HOME_BASE/$name"
    podman start "$name" >/dev/null 2>&1 || true
    sleep 2
    
    write_manifest "$name" "$strategy" "$freeze_image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
