#!/usr/bin/env bash
# shellcheck shell=bash

# generate_init_payload: Creates the base64 encoded payload for container initialization
# Dependencies: Requires DISTRO_* variables to be set (Dependency Injection)
generate_init_payload() {
    local name
    name="$1"
    local color
    color="$2"

    # Default values if not injected
    local zshrc
    zshrc="${DISTRO_ZSHRC:-/etc/zshrc}"
    local bashrc
    bashrc="${DISTRO_BASHRC:-/etc/bash.bashrc}"

    local script_payload
    script_payload=$(cat << EOF
mkdir -p /etc/profile.d
cat << 'INNER_EOF' > /etc/profile.d/dbx-smith-env.sh
# DbxSmith Shell Theme — uses hooks to persist after user rc files
if [ -n "\${ZSH_VERSION:-}" ]; then
    _dbx_smith_precmd() {
        printf '\e]11;${color}\a'
        if [[ "\$PROMPT" != *"(REPLACE_NAME)"* ]]; then
            PROMPT=\$'%F{cyan}(REPLACE_NAME)%f %n@%m:%~ %(!.#.\$) '
        fi
    }
    typeset -aU precmd_functions
    precmd_functions+=(_dbx_smith_precmd)
    _dbx_smith_pin_last() {
        precmd_functions=(\${precmd_functions:#_dbx_smith_precmd} _dbx_smith_precmd)
        precmd_functions=(\${precmd_functions:#_dbx_smith_pin_last})
    }
    precmd_functions+=(_dbx_smith_pin_last)
else
    _dbx_smith_prompt() {
        printf '\033]11;${color}\007'
        if [[ "\$PS1" != *"(REPLACE_NAME)"* ]]; then
            PS1="\[\033[36m\](REPLACE_NAME)\[\033[0m\] \u@\h:\w\\$ "
        fi
    }
    PROMPT_COMMAND="\${PROMPT_COMMAND:+\$PROMPT_COMMAND;}_dbx_smith_prompt"
fi
INNER_EOF

sed -i "s|REPLACE_NAME|$name|g" /etc/profile.d/dbx-smith-env.sh

# Use injected paths
if [ -d "\$(dirname "$zshrc")" ]; then
    touch "$zshrc"
    if ! grep -q "dbx-smith-env.sh" "$zshrc"; then
        echo "source /etc/profile.d/dbx-smith-env.sh" | cat - "$zshrc" > "${zshrc}.tmp"
        mv "${zshrc}.tmp" "$zshrc"
    fi
fi

if [ -f "$bashrc" ]; then
    if ! grep -q "dbx-smith-env.sh" "$bashrc"; then
        echo "source /etc/profile.d/dbx-smith-env.sh" | cat - "$bashrc" > "${bashrc}.tmp"
        mv "${bashrc}.tmp" "$bashrc"
    fi
fi

# Bootstrap empty dotfiles
awk -F: '\$3 >= 1000 && \$3 != 65534 {print \$1, \$6}' /etc/passwd | while read -r uname udir; do
    if [ -d "\$udir" ]; then
        touch "\$udir/.zshrc" "\$udir/.bashrc"
        chown "\$uname:\$uname" "\$udir/.zshrc" "\$udir/.bashrc" 2>/dev/null || true
    fi
done
EOF
)
    printf "%s" "$script_payload" | base64 | tr -d '\n'
}
