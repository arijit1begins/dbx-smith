#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034
# Constants and Paths for DbxSmith

if [[ -z "${VERSION:-}" ]]; then
    readonly VERSION="1.4.5"
fi
if [[ -z "${HOME_BASE:-}" ]]; then
    readonly HOME_BASE="${HOME}/boxes"
fi
if [[ -z "${CONFIG_DIR:-}" ]]; then
    readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith"
fi
if [[ -z "${ALIAS_DIR:-}" ]]; then
    readonly ALIAS_DIR="${CONFIG_DIR}/aliases.d"
fi
if [[ -z "${REG_DIR:-}" ]]; then
    readonly REG_DIR="${CONFIG_DIR}/registry"
fi
