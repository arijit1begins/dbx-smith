#!/usr/bin/env bash
# shellcheck shell=bash
# dbx-smith.sh - DbxSmith Runtime Core (Bash/Zsh Compatible)
#
# DESCRIPTION:
#   The core runtime sourced by the user's shell. It provides the `dbx-smith`
#   entrypoint function, lazy-loaded autocomplete, and dynamic sourcing of
#   container aliases and keybindings.

# --- [ Dependency Injection & Module Loading ] ---
# --- [ Dependency Injection & Module Loading ] ---
if [[ -n "${ZSH_VERSION:-}" ]]; then
    eval '_SRC_DIR=$(dirname "$(readlink -f "${(%):-%x}" 2>/dev/null || echo "$0")")'
else
    _SRC_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")")
fi

# shellcheck source=src/core/constants.sh
if [[ -f "$_SRC_DIR/core/constants.sh" ]]; then
    source "$_SRC_DIR/core/constants.sh"
else
    # Fallback if not using modular structure
    REG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith/registry"
    ALIAS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith/aliases.d"
fi

dbx-smith() {
    if [[ "$1" == "list" ]]; then
        dbx-smith-list "${@:2}"
        return $?
    elif [[ "$1" == "dash" ]]; then
        while true; do
            local box
            box=$(dbx-smith-dash --print-selected)
            [[ -z "$box" ]] && { clear; return 0; }
            
            # Reset terminal before entering container
            tput rmcup 2>/dev/null || true
            clear
            
            # Call dbx-smith recursively with the box name to enter it
            dbx-smith "$box" "${@:2}"
            
            # Clear again before returning to dashboard
            clear
        done
    fi

    local box
    box="$1"
    [[ -z "$box" ]] && { echo "usage: dbx-smith <box_name|list|dash> [args...]"; return 1; }

    # Pre-flight existence validation using pipe delimiter
    if ! distrobox list --no-color | awk -F'|' -v b="$box" 'NR>1 {
        name=$2; gsub(/^[ \t]+|[ \t]+$/, "", name);
        if (name==b) {found=1}
    } END {exit !found}'; then
        echo "Error: Distrobox '$box' does not exist." >&2
        return 1
    fi

    # Read manifest if exists to determine strategy-specific enter flags
    local enter_args=()
    if [[ -f "$REG_DIR/${box}.conf" ]]; then
        local strategy
        strategy=$(grep "^STRATEGY=" "$REG_DIR/${box}.conf" | cut -d= -f2)
        if [[ "$strategy" == ghost* ]]; then
            enter_args+=(--no-workdir --additional-flags "--user ghostuser --workdir /home/ghostuser --env HOME=/home/ghostuser")
        elif [[ "$strategy" == "airgapped" || "$strategy" == "isolated-net" ]]; then
            enter_args+=(--no-workdir)
        fi
    fi

    # Trap to ensure background reset even on SIGINT/interrupt
    trap 'if [[ -t 1 ]]; then printf "\033]111\007\033]11;#000000\007"; tput cnorm; fi' EXIT INT TERM

    distrobox enter "${enter_args[@]}" "$box" "${@:2}"
    local exit_code=$?
    
    # Explicit reset after clean exit
    if [[ -t 1 ]]; then
        printf '\033]111\007\033]11;#000000\007'
        tput cnorm
    fi
    
    trap - EXIT INT TERM
    return $exit_code
}

_dbx_comp_lazy() {
    local CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dbx-smith"
    local CACHE_FILE="$CACHE_DIR/comp.db"
    
    if ! command -v distrobox >/dev/null 2>&1; then return 0; fi

    mkdir -p "$CACHE_DIR"
    if [[ ! -f "$CACHE_FILE" ]] || [[ -n $(find "$CACHE_FILE" -mmin +5 2>/dev/null) ]]; then
        distrobox list --no-color | awk -F'|' 'NR>1 {
            name=$2; gsub(/^[ \t]+|[ \t]+$/, "", name);
            print name
        }' > "$CACHE_FILE" 2>/dev/null || true
    fi

    local boxes
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        eval 'boxes=(${(f)"$(cat "$CACHE_FILE" 2>/dev/null)"})'
        compadd -a boxes
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        mapfile -t boxes < "$CACHE_FILE"
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
if [[ -d "$ALIAS_DIR" ]]; then
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        # We use eval here so bash's parser doesn't choke on zsh's (N) nullglob syntax
        eval 'for fragment in "$ALIAS_DIR"/*.sh(N); do
            [[ -r "$fragment" && -s "$fragment" ]] && source "$fragment"
        done'
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        for fragment in "$ALIAS_DIR"/*.sh; do
            # shellcheck source=/dev/null
            [[ -r "$fragment" && -s "$fragment" ]] && source "$fragment"
        done
    fi
fi

true

