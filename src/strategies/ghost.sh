#!/usr/bin/env bash
# shellcheck shell=bash

# Helper for ghost user creation
_create_ghostuser() {
    local name
    name="$1"
    echo "Creating ghostuser identity inside '$name'..."
    podman exec --user root --workdir / "$name" bash -c '
        if ! id ghostuser >/dev/null 2>&1; then
            _shell=$(command -v zsh 2>/dev/null || command -v bash)
            useradd -m -s "$_shell" ghostuser 2>/dev/null || true
            if ! id ghostuser >/dev/null 2>&1; then
                echo "ghostuser:x:1001:1001::/home/ghostuser:$_shell" >> /etc/passwd
                grep -q "^ghostuser:" /etc/group 2>/dev/null || echo "ghostuser:x:1001:" >> /etc/group
            fi
            
            mkdir -p /home/ghostuser
            touch /home/ghostuser/.zshrc /home/ghostuser/.bashrc
            chown -R ghostuser:ghostuser /home/ghostuser 2>/dev/null || chown -R 1001:1001 /home/ghostuser
            
            usermod -aG wheel ghostuser 2>/dev/null || true
            usermod -aG sudo  ghostuser 2>/dev/null || true
            
            # Enable passwordless sudo for ghostuser
            mkdir -p /etc/sudoers.d
            echo "ghostuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dbx-smith-ghost
            chmod 0440 /etc/sudoers.d/dbx-smith-ghost
        fi
    '
}

strategy_ghost_get_flags() {
    local image name payload
    name="$1" image="$2" payload="$3"
    local init_hook
    init_hook="echo '$payload' | base64 -d | sh"

    local _su_install_script
    _su_install_script=$(cat <<SU_EOF
command -v su >/dev/null 2>&1 || \
    (command -v $DISTRO_PKGMGR >/dev/null 2>&1 && $DISTRO_PKGMGR install -y $DISTRO_PKG_SU 2>/dev/null) || true
SU_EOF
)
    local su_install_hook
    su_install_hook="echo '$(printf '%s' "$_su_install_script" | base64 | tr -d '\n')' | base64 -d | bash"

    # shellcheck disable=SC2034
    DBX_FLAGS=(--name "$name" --image "$image" --hostname ghost-shell --init-hooks "$su_install_hook; $init_hook")
}

strategy_ghost_finalize() {
    local image name strategy usr_alias usr_bind
    name="$1" strategy="$2" image="$3" usr_alias="$4" usr_bind="$5"

    echo "Ghost strategy detected. Bootstrapping container..."
    distrobox enter --no-workdir "$name" -- true >/dev/null 2>&1 || true

    _create_ghostuser "$name"

    write_manifest "$name" "$strategy" "$image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
