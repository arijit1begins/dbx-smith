#!/usr/bin/env bash

strategy_isolated_net_get_flags() {
    local name="$1" image="$2" payload="$3"
    local init_hook="echo '$payload' | base64 -d | sh"

    podman network inspect "dbx-net-${name}" >/dev/null 2>&1 \
        || podman network create "dbx-net-${name}" >/dev/null

    local isolate_hook="\
mkdir -p /tmp/save_home \
&& mount --bind \"$HOME_BASE/$name\" /tmp/save_home \
&& mount -t tmpfs tmpfs /home \
&& mkdir -p \"$HOME_BASE/$name\" \
&& mount --bind /tmp/save_home \"$HOME_BASE/$name\" \
&& umount /tmp/save_home"

    DBX_FLAGS=(--name "$name" --image "$image" --home "$HOME_BASE/$name" --unshare-all --additional-flags "--network dbx-net-${name}" --init-hooks "$isolate_hook; $init_hook")
}

strategy_isolated_net_finalize() {
    local name="$1" strategy="$2" image="$3" usr_alias="$4" usr_bind="$5"

    echo "Isolated-net strategy detected. Bootstrapping container..."
    distrobox enter --no-workdir "$name" -- true
    
    write_manifest "$name" "$strategy" "$image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
