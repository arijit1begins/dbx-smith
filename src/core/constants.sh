#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034
# Constants and Paths for DbxSmith
readonly VERSION="1.3.1"
readonly HOME_BASE="${HOME}/boxes"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dbx-smith"
readonly ALIAS_DIR="${CONFIG_DIR}/aliases.d"
readonly REG_DIR="${CONFIG_DIR}/registry"
