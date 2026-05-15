#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034
# Constants and Paths for DbxSmith
[[ -z "${VERSION:-}" ]] && readonly VERSION="1.3.1"
[[ -z "${HOME_BASE:-}" ]] && readonly HOME_BASE="${HOME}/boxes"
[[ -z "${CONFIG_DIR:-}" ]] && readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith"
[[ -z "${ALIAS_DIR:-}" ]] && readonly ALIAS_DIR="${CONFIG_DIR}/aliases.d"
[[ -z "${REG_DIR:-}" ]] && readonly REG_DIR="${CONFIG_DIR}/registry"
