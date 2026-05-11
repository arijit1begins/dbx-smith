#!/usr/bin/env bash
# shellcheck shell=bash

# Internal helpers for airgap hooks
_get_airgap_isolate_hook() {
    local name="$1"
    printf 'mkdir -p /tmp/save_home \
&& mount --bind "%s/%s" /tmp/save_home \
&& mount -t tmpfs tmpfs /home \
&& mkdir -p "%s/%s" \
&& mount --bind /tmp/save_home "%s/%s" \
&& umount /tmp/save_home \
&& chown root:root /etc/sudo.conf /etc/sudoers /usr/bin/sudo /usr/sbin/sudo 2>/dev/null || true \
&& chown -R root:root /etc/sudoers.d 2>/dev/null || true \
&& chmod 0440 /etc/sudoers 2>/dev/null || true \
&& chmod 4755 /usr/bin/sudo /usr/sbin/sudo 2>/dev/null || true' "$HOME_BASE" "$name" "$HOME_BASE" "$name" "$HOME_BASE" "$name"
}

_get_airgap_sever_hook() {
    printf "if [ -f /etc/dbx_airgap_active ]; then \
    for iface in \$(ls /sys/class/net/ 2>/dev/null); do \
        if [ \"\$iface\" != \"lo\" ]; then \
            sudo ip link set \"\$iface\" down 2>/dev/null || true; \
        fi; \
    done; \
fi"
}

strategy_airgapped_get_flags() {
    local image name payload
    name="$1" image="$2" payload="$3"
    
    local init_hook
    init_hook="echo '$payload' | base64 -d | sh"
    local isolate_hook
    isolate_hook=$(_get_airgap_isolate_hook "$name")
    local airgap_hook
    airgap_hook=$(_get_airgap_sever_hook)

    # shellcheck disable=SC2034
    DBX_FLAGS=(--name "$name" --image "$image" --home "$HOME_BASE/$name" --unshare-all --init-hooks "$isolate_hook; $airgap_hook; $init_hook")
}

strategy_airgapped_finalize() {
    local image name strategy usr_alias usr_bind
    name="$1" strategy="$2" image="$3" usr_alias="$4" usr_bind="$5"

    echo "Airgapped strategy detected. Bootstrapping container with temporary internet access..."
    local pkg_name="iproute2"
    [[ "$image" == *fedora* ]] && pkg_name="iproute"
    
    distrobox enter --no-workdir "$name" -- bash -c "sudo $DISTRO_PKGMGR update >/dev/null 2>&1 || true; sudo $DISTRO_PKGMGR install -y $pkg_name >/dev/null 2>&1 || true"
    distrobox enter --no-workdir "$name" -- true >/dev/null 2>&1 || true
    
    echo "Freezing provisioned state and applying physical network isolation..."
    distrobox stop "$name" --yes >/dev/null 2>&1 || true
    local freeze_image="dbx-frozen-${name}"
    podman commit "$name" "$freeze_image" >/dev/null
    
    distrobox rm "$name" --force >/dev/null 2>&1 || true
    
    echo "Re-spawning isolated container with '--network none'..."
    local isolate_hook
    isolate_hook=$(_get_airgap_isolate_hook "$name")
    local airgap_hook
    airgap_hook=$(_get_airgap_sever_hook)

    distrobox create --name "$name" --image "$freeze_image" --home "$HOME_BASE/$name" --unshare-all --additional-flags "--network none" --init-hooks "$isolate_hook; $airgap_hook" --yes >/dev/null
    
    write_manifest "$name" "$strategy" "$freeze_image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
