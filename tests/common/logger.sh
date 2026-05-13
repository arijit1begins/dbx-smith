#!/usr/bin/env bash
# tests/common/logger.sh - Standardized Verbosity-Aware Logger utilities
#
# Supported VERBOSITY levels: quiet, info, debug (default: info)

VERBOSITY="${VERBOSITY:-info}"

# ANSI Colors
_COLOR_RESET='\033[0m'
_COLOR_INFO='\033[36m'    # Cyan
_COLOR_SUCCESS='\033[32m' # Green
_COLOR_WARN='\033[33m'    # Yellow
_COLOR_ERROR='\033[31m'   # Red
_COLOR_DEBUG='\033[90m'   # Dim/Gray

log_info() {
    if [[ "$VERBOSITY" != "quiet" ]]; then
        echo -e "${_COLOR_INFO}[INFO]${_COLOR_RESET} $1"
    fi
}

log_success() {
    if [[ "$VERBOSITY" != "quiet" ]]; then
        echo -e "${_COLOR_SUCCESS}[SUCCESS]${_COLOR_RESET} $1"
    fi
}

log_warn() {
    if [[ "$VERBOSITY" != "quiet" ]]; then
        echo -e "${_COLOR_WARN}[WARN]${_COLOR_RESET} $1" >&2
    fi
}

log_error() {
    echo -e "${_COLOR_ERROR}[ERROR]${_COLOR_RESET} $1" >&2
}

log_debug() {
    if [[ "$VERBOSITY" == "debug" ]]; then
        echo -e "${_COLOR_DEBUG}[DEBUG] $1${_COLOR_RESET}"
    fi
}
