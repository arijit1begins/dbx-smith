#!/usr/bin/env bash
# tests/01_unit_ui_payload.sh - Fast unit test for UI payload logic

set -euo pipefail

echo "Running UI Payload Unit Test..."

# Create a mock environment
TARGET_DIR=$(mktemp -d)
export TARGET_DIR
trap 'rm -rf "$TARGET_DIR"' EXIT

# Simulated inputs
name="testbox"
color="#3a4b5c"

# The logic currently in dbx-smith-spin (hook-based approach)
script_payload=$(cat << 'EOF'
mkdir -p "$TARGET_DIR/etc/profile.d"
cat << 'INNER_EOF' > "$TARGET_DIR/etc/profile.d/dbx-smith-env.sh"
# DbxSmith Shell Theme — uses hooks to persist after user rc files
if [ -n "${ZSH_VERSION:-}" ]; then
    # --- Zsh: precmd hook ---
    _dbx_smith_precmd() {
        printf '\e]11;REPLACE_COLOR\a'
        if [[ "$PROMPT" != *"(REPLACE_NAME)"* ]]; then
            PROMPT=\$'%F{cyan}(REPLACE_NAME)%f %n@%m:%~ %(!.#.$) '
        fi
    }
    typeset -aU precmd_functions
    precmd_functions+=(_dbx_smith_precmd)
    _dbx_smith_pin_last() {
        precmd_functions=(${precmd_functions:#_dbx_smith_precmd} _dbx_smith_precmd)
        precmd_functions=(${precmd_functions:#_dbx_smith_pin_last})
    }
    precmd_functions+=(_dbx_smith_pin_last)
else
    _dbx_smith_prompt() {
        printf '\033]11;REPLACE_COLOR\007'
        if [[ "$PS1" != *"(REPLACE_NAME)"* ]]; then
            PS1="\[\033[36m\](REPLACE_NAME)\[\033[0m\] \u@\h:\w\$ "
        fi
    }
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_dbx_smith_prompt"
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

# Validation 1: No double-escaped backslashes in printf
if grep -Fq 'printf "\\033' "$ENV_FILE"; then
    printf "❌ Error: Literal \\\\033 found in printf! Escape sequence broken.\n"
    exit 1
fi

# Validation 2: Bash hook contains correct background color printf
if ! grep -Fq "printf '\\033]11;#3a4b5c\\007'" "$ENV_FILE"; then
    echo "❌ Error: Bash PROMPT_COMMAND hook missing OSC 11 color printf."
    exit 1
fi

# Validation 3: Bash hook prepends box name to PS1
if ! grep -Fq '(testbox)' "$ENV_FILE"; then
    echo "❌ Error: Box name '(testbox)' not found in env file."
    exit 1
fi

# Validation 4: Zsh precmd hook contains correct background color printf
if ! grep -Fq "printf '\\e]11;#3a4b5c\\a'" "$ENV_FILE"; then
    echo "❌ Error: Zsh precmd hook missing OSC 11 color printf."
    exit 1
fi

# Validation 5: Hook functions are defined
if ! grep -Fq '_dbx_smith_precmd()' "$ENV_FILE"; then
    echo "❌ Error: Zsh precmd hook function not defined."
    exit 1
fi

if ! grep -Fq '_dbx_smith_prompt()' "$ENV_FILE"; then
    echo "❌ Error: Bash PROMPT_COMMAND hook function not defined."
    exit 1
fi

# Validation 6: PROMPT_COMMAND chain contains our hook
if ! grep -q "_dbx_smith_prompt" "$ENV_FILE"; then
    echo "❌ Error: PROMPT_COMMAND hook not found in env file."
    exit 1
fi

echo "✅ UI Payload Test Passed!"
