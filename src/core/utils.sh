#!/usr/bin/env bash

# bootstrap: Ensures environment and dependencies are met
bootstrap() {
    mkdir -p "$HOME_BASE" "$ALIAS_DIR" "$REG_DIR"
    
    if ! command -v distrobox >/dev/null 2>&1; then
        echo "Error: 'distrobox' is not installed." >&2
        exit 127
    fi

    for cmd in podman cksum awk grep printf id sed base64 tr; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: Required command '$cmd' not found." >&2
            exit 127
        fi
    done
}

# get_color: Generates a deterministic color based on image name
get_color() {
    local img="$1"
    local hash
    hash=$(echo "$img" | cksum | awk '{print $1}')
    printf "#%02x%02x%02x" $(( (hash % 60) + 20 )) $(( ((hash / 100) % 60) + 20 )) $(( ((hash / 10000) % 60) + 20 ))
}

# register_shortcuts: Creates alias and bindkey fragments
register_shortcuts() {
    local name="$1"
    local usr_alias="$2"
    local usr_bind="$3"
    local fragment="$ALIAS_DIR/${name}.sh"

    true > "$fragment"
    if [[ -n "$usr_alias" ]]; then
        echo "alias ${usr_alias}=\"dbx-smith ${name}\"" >> "$fragment"
    fi

    if [[ -n "$usr_bind" ]]; then
        cat << EOF >> "$fragment"
# Dynamic Hotkey Binding
if [[ -n "\${ZSH_VERSION:-}" ]]; then
    _dbx_jump_${name}() { BUFFER="dbx-smith ${name}"; zle accept-line; }
    zle -N _dbx_jump_${name}
    bindkey '${usr_bind}' _dbx_jump_${name}
elif [[ -n "\${BASH_VERSION:-}" ]]; then
    bind -x '"${usr_bind}":"dbx-smith ${name}"'
fi
EOF
    fi

    if [[ ! -s "$fragment" ]]; then
        rm -f "$fragment"
    fi
}

# write_manifest: Records container metadata
write_manifest() {
    local name="$1" strategy="$2" image="$3"
    local manifest="$REG_DIR/${name}.conf"
    cat <<EOF > "$manifest"
NAME=$name
STRATEGY=$strategy
IMAGE=$image
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
}
