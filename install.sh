#!/usr/bin/env bash
# Quick install script for the DbxSmith Productivity Suite

set -euo pipefail

echo "Installing DbxSmith Productivity Suite..."

PREFIX="${PREFIX:-$HOME/.local}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith"

if [[ -f "Makefile" && -d "bin" && -d "src" ]]; then
    echo "Local repository detected. Installing from current directory..."
else
    echo "Cloning DbxSmith repository..."
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    git clone --quiet "https://github.com/arijit1begins/dbx-smith.git" "$TMP_DIR"
    cd "$TMP_DIR"
fi

make install PREFIX="$PREFIX" CONFIG_DIR="$CONFIG_DIR"

RC_FILE=""
if [[ -n "${ZSH_VERSION:-}" || "$SHELL" == *zsh ]]; then
    RC_FILE="$HOME/.zshrc"
elif [[ -n "${BASH_VERSION:-}" || "$SHELL" == *bash ]]; then
    RC_FILE="$HOME/.bashrc"
fi

if [[ -n "$RC_FILE" && -f "$RC_FILE" ]]; then
    if ! grep -q "source $CONFIG_DIR/dbx-smith.sh" "$RC_FILE" 2>/dev/null; then
        read -p "Would you like to automatically append the source line to $RC_FILE? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "" >> "$RC_FILE"
            echo "# DbxSmith Productivity Suite Runtime Core" >> "$RC_FILE"
            echo "source $CONFIG_DIR/dbx-smith.sh" >> "$RC_FILE"
            echo "Added to $RC_FILE."
        fi
    else
        echo "Runtime core already sourced in $RC_FILE."
    fi
else
    echo "Could not detect default shell. Please manually append the source line:"
    echo "source $CONFIG_DIR/dbx-smith.sh"
fi

echo "Setup finished. Please restart your shell or run 'source $RC_FILE'."
