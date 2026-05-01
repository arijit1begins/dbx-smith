#!/usr/bin/env bash
# tests/01_unit_ui_payload.sh - Fast unit test for UI payload logic

set -euo pipefail

echo "Running UI Payload Unit Test..."

# Create a mock environment
export TARGET_DIR=$(mktemp -d)
trap 'rm -rf "$TARGET_DIR"' EXIT

# Simulated inputs
name="testbox"
color="#3a4b5c"

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

# Execute the payload
COLOR="$color" NAME="$name" eval "$script_payload"

ENV_FILE="$TARGET_DIR/etc/profile.d/dbx-smith-env.sh"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: Env file not created."
    exit 1
fi

# Validation
if grep -Fq 'printf "\\033' "$ENV_FILE"; then
    echo "❌ Error: Literal \\033 found in printf! Escape sequence broken."
    exit 1
fi

if ! grep -Fq 'printf "\033]11;#3a4b5c\007"' "$ENV_FILE"; then
    echo "❌ Error: printf missing or malformed."
    exit 1
fi

if grep -Fq '\[\033' "$ENV_FILE"; then
    # this is expected, so we check for the double backslash version
    if grep -Fq '\\[\033' "$ENV_FILE"; then
        echo "❌ Error: Literal \\[ found! Escape sequence broken."
        exit 1
    fi
fi

if ! grep -Fq '\[\033]11;#3a4b5c\007\]' "$ENV_FILE"; then
    echo "❌ Error: Bash PS1 missing OSC 11 or malformed."
    exit 1
fi

if ! grep -Fq '%{\033]11;#3a4b5c\007%}' "$ENV_FILE"; then
    echo "❌ Error: Zsh PS1 missing OSC 11 or malformed."
    exit 1
fi

echo "✅ UI Payload Test Passed!"

