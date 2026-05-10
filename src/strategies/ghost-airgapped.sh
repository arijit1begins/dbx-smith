#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source=src/strategies/ghost.sh
source "${SRC_DIR}/strategies/ghost.sh"

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
    isolate_hook="umount -l /home/$USER 2>/dev/null || true; mount -t tmpfs tmpfs /home; mkdir -p /home/ghostuser; chown ghostuser:ghostuser /home/ghostuser 2>/dev/null || true"
    
    local airgap_hook
    airgap_hook="if [ -f /etc/dbx_airgap_active ]; then for iface in \$(ls /sys/class/net/ 2>/dev/null); do if [ \"\$iface\" != \"lo\" ]; then ip link set \"\$iface\" down 2>/dev/null || true; fi; done; fi"

    # shellcheck disable=SC2034
    DBX_FLAGS=(--name "$name" --image "$image" --hostname ghost-shell --home "$HOME_BASE/$name" --unshare-all --init-hooks "$su_install_hook; $isolate_hook; $airgap_hook; $init_hook")
}

strategy_ghost_airgapped_finalize() {
    local image name strategy usr_alias usr_bind
    name="$1" strategy="$2" image="$3" usr_alias="$4" usr_bind="$5"

    echo "Ghost-airgapped strategy detected. Bootstrapping container..."
    distrobox enter --no-workdir "$name" -- true >/dev/null 2>&1 || true

    _create_ghostuser "$name"

    echo "Severing network bridges..."
    podman exec --user root --workdir / "$name" touch /etc/dbx_airgap_active 2>/dev/null || true
    podman exec --user root --workdir / "$name" sh -c 'for iface in $(ls /sys/class/net/ 2>/dev/null); do if [ "$iface" != "lo" ]; then ip link set "$iface" down 2>/dev/null || true; fi; done' 2>/dev/null || true
    podman network disconnect --force podman  "$name" >/dev/null 2>&1 || true
    podman network disconnect --force podman0 "$name" >/dev/null 2>&1 || true
    
    podman exec --user root --workdir / "$name" bash -c 'chown root:root /etc/sudo.conf /etc/sudoers /usr/bin/sudo /usr/sbin/sudo 2>/dev/null; chown -R root:root /etc/sudoers.d 2>/dev/null; chmod 0440 /etc/sudoers 2>/dev/null; chmod 4755 /usr/bin/sudo /usr/sbin/sudo 2>/dev/null' 2>/dev/null || true

    write_manifest "$name" "$strategy" "$image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
