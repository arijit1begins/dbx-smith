#!/usr/bin/env bash
# shellcheck shell=bash

strategy_airgapped_get_flags() {
    local image name payload
    name="$1" image="$2" payload="$3"
    local init_hook
    init_hook="echo '$payload' | base64 -d | sh"

    local isolate_hook
    isolate_hook="\
mkdir -p /tmp/save_home \
&& mount --bind \"$HOME_BASE/$name\" /tmp/save_home \
&& mount -t tmpfs tmpfs /home \
&& mkdir -p \"$HOME_BASE/$name\" \
&& mount --bind /tmp/save_home \"$HOME_BASE/$name\" \
&& umount /tmp/save_home \
&& chown root:root /etc/sudo.conf /etc/sudoers /usr/bin/sudo /usr/sbin/sudo 2>/dev/null || true \
&& chown -R root:root /etc/sudoers.d 2>/dev/null || true \
&& chmod 0440 /etc/sudoers 2>/dev/null || true \
&& chmod 4755 /usr/bin/sudo /usr/sbin/sudo 2>/dev/null || true"

    local airgap_hook
    airgap_hook="\
if [ -f /etc/dbx_airgap_active ]; then \
    for iface in \$(ls /sys/class/net/ 2>/dev/null); do \
        if [ \"\$iface\" != \"lo\" ]; then \
            sudo ip link set \"\$iface\" down 2>/dev/null || true; \
        fi; \
    done; \
fi"

    # shellcheck disable=SC2034
    DBX_FLAGS=(--name "$name" --image "$image" --home "$HOME_BASE/$name" --unshare-all --init-hooks "$isolate_hook; $airgap_hook; $init_hook")
}

strategy_airgapped_finalize() {
    local image name strategy usr_alias usr_bind
    name="$1" strategy="$2" image="$3" usr_alias="$4" usr_bind="$5"

    echo "Airgapped strategy detected. Bootstrapping container with temporary internet access..."
    # Ensure iproute2 is installed so we can actually sever the link from the inside
    local pkg_name="iproute2"
    [[ "$image" == *fedora* ]] && pkg_name="iproute"
    
    distrobox enter --no-workdir "$name" -- bash -c "sudo $DISTRO_PKGMGR update >/dev/null 2>&1 || true; sudo $DISTRO_PKGMGR install -y $pkg_name >/dev/null 2>&1 || true"
    distrobox enter --no-workdir "$name" -- true >/dev/null 2>&1 || true
    
    echo "Severing all network bridges to fully airgap the container..."
    podman exec --user root --workdir / "$name" touch /etc/dbx_airgap_active 2>/dev/null || true
    podman exec --user root --workdir / "$name" sh -c 'for iface in $(ls /sys/class/net/ 2>/dev/null); do if [ "$iface" != "lo" ]; then ip link set "$iface" down 2>/dev/null || true; fi; done' 2>/dev/null || true
    
    # Dynamically disconnect all networks
    local networks
    networks=$(podman inspect "$name" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}')
    for net in $networks; do
        podman network disconnect --force "$net" "$name" >/dev/null 2>&1 || true
    done
    
    # Fix sudo ownership (Fedora)
    podman exec --user root --workdir / "$name" bash -c \
        'chown root:root /etc/sudo.conf /etc/sudoers /usr/bin/sudo /usr/sbin/sudo 2>/dev/null; chown -R root:root /etc/sudoers.d 2>/dev/null; chmod 0440 /etc/sudoers 2>/dev/null; chmod 4755 /usr/bin/sudo /usr/sbin/sudo 2>/dev/null' \
        2>/dev/null || true

    write_manifest "$name" "$strategy" "$image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
