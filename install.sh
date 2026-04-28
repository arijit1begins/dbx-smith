#!/usr/bin/env bash
# Quick install script for the DbxSmith Productivity Suite
#
# DESCRIPTION:
#   Downloads and installs the latest release of the DbxSmith suite.
#   It sets up the correct paths and hooks the source script into the shell profile.

set -euo pipefail

echo "Installing DbxSmith Productivity Suite..."

for cmd in curl tar; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' not found. Please install it to proceed." >&2
        exit 127
    fi
done

PREFIX="${PREFIX:-$HOME/.local}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith"

if [[ -f "Makefile" && -d "bin" && -d "src" ]]; then
    echo "Local repository detected. Installing from current directory..."
else
    echo "Fetching latest stable release..."
    LATEST_TAG=$(curl -s https://api.github.com/repos/arijit1begins/dbx-smith/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$LATEST_TAG" ]]; then
        echo "Warning: Could not detect latest release tag. Falling back to main branch..."
        DOWNLOAD_URL="https://github.com/arijit1begins/dbx-smith/archive/refs/heads/main.tar.gz"
        LATEST_TAG="main"
    else
        echo "Found release: $LATEST_TAG"
        DOWNLOAD_URL="https://github.com/arijit1begins/dbx-smith/archive/refs/tags/${LATEST_TAG}.tar.gz"
    fi

    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    
    echo "Downloading DbxSmith $LATEST_TAG..."
    curl -sL "$DOWNLOAD_URL" | tar xz -C "$TMP_DIR" --strip-components=1
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
