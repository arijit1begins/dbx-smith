#!/usr/bin/env bash
# test_payload.sh - Fast unit test for the profile injection logic
set -euo pipefail

# Mock the environment to capture the payload
TARGET_DIR=$(mktemp -d)
export TARGET_DIR
trap 'rm -rf "$TARGET_DIR"' EXIT

name="testbox"
color="#3a4b5c"

mkdir -p "$TARGET_DIR/etc/profile.d"

# The logic currently in dbx-smith-spin
script_payload=$(cat << 'EOF'
mkdir -p "$TARGET_DIR/etc/profile.d"
cat << 'INNER_EOF' > "$TARGET_DIR/etc/profile.d/dbx-smith-env.sh"
printf "\033]11;REPLACE_COLOR\007"
if [ -n "${ZSH_VERSION:-}" ]; then
    export PS1="%{\033]11;REPLACE_COLOR\007%}%F{cyan}(REPLACE_NAME)%f %F{green}%n@%m%f:%F{blue}%~%f%# "
else
    export PS1="\[\033]11;REPLACE_COLOR\007\]\[\033[36m\](REPLACE_NAME)\[\033[0m\] \[\033[32m\]\u@\h\[\033[0m\]:\[\033[34m\]\w\[\033[0m\]\$ "
fi
INNER_EOF
sed -i "s|REPLACE_COLOR|${COLOR}|g" "$TARGET_DIR/etc/profile.d/dbx-smith-env.sh"
sed -i "s|REPLACE_NAME|${NAME}|g" "$TARGET_DIR/etc/profile.d/dbx-smith-env.sh"
EOF
)


# Simulate execution inside container
COLOR="$color" NAME="$name" eval "$script_payload"
