#!/usr/bin/env bash
# dbx-smith.sh - DbxSmith Runtime Core (Bash/Zsh Compatible)

dbx-smith() {
    local box="$1"
    [[ -z "$box" ]] && { echo "usage: dbx-smith <box_name> [args...]"; return 1; }

    # Pre-flight existence validation using awk's default whitespace tokenization ($3 is NAME)
    if ! distrobox list --no-color | awk -v b="$box" 'NR>1 && $3==b {found=1} END {exit !found}'; then
        echo "Error: Distrobox '$box' does not exist." >&2
        echo "[DEBUG] Validating against the following active distroboxes:" >&2
        distrobox list --no-color >&2
        return 1
    fi

    # Read manifest if exists to determine if it is a ghost strategy
    local REG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith/registry"
    local enter_args=()
    if [[ -f "$REG_DIR/${box}.conf" ]]; then
        if grep -q "STRATEGY=ghost" "$REG_DIR/${box}.conf"; then
            enter_args+=(--user ghostuser)
        fi
    else
        # Fallback heuristic
        if podman exec "$box" grep -q "ghostuser" /etc/passwd 2>/dev/null; then
            enter_args+=(--user ghostuser)
        fi
    fi

    distrobox enter "${enter_args[@]}" "$box" "${@:2}"
    
    # Deterministic explicitly colored UI reset (black fallback)
    printf '\033]11;#000000\007'
}

_dbx_comp_lazy() {
    local CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dbx-smith"
    local CACHE_FILE="$CACHE_DIR/comp.db"
    
    if ! command -v distrobox >/dev/null 2>&1; then
        return 0
    fi

    mkdir -p "$CACHE_DIR"
    # Basic cache invalidation (e.g., if cache is older than 5 mins, though simple here)
    if [[ ! -f "$CACHE_FILE" ]] || [[ -n $(find "$CACHE_FILE" -mmin +5 2>/dev/null) ]]; then
        distrobox list --no-color | awk 'NR>1 {print $3}' > "$CACHE_FILE" 2>/dev/null || true
    fi

    local boxes=()
    if [[ -f "$CACHE_FILE" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && boxes+=("$line")
        done < "$CACHE_FILE"
    fi

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        compadd -a boxes
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        local cur="${COMP_WORDS[COMP_CWORD]}"
        COMPREPLY=( $(compgen -W "${boxes[*]}" -- "$cur") )
    fi
}

if [[ -n "${ZSH_VERSION:-}" ]]; then
    compdef _dbx_comp_lazy dbx-smith
elif [[ -n "${BASH_VERSION:-}" ]]; then
    complete -F _dbx_comp_lazy dbx-smith
fi

alias dbl="distrobox list"
alias db-stop-all="distrobox stop --all"

# Loose Coupling - Safe Read Guard for aliases
_DBX_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith"
_DBX_ALIAS_DIR="$_DBX_CONFIG_HOME/aliases.d"

if [[ -d "$_DBX_ALIAS_DIR" ]]; then
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        for fragment in "$_DBX_ALIAS_DIR"/*.sh(N); do
            [[ -r "$fragment" && -s "$fragment" ]] && source "$fragment"
        done
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        for fragment in "$_DBX_ALIAS_DIR"/*.sh; do
            [[ -r "$fragment" && -s "$fragment" ]] && source "$fragment"
        done
    fi
fi
