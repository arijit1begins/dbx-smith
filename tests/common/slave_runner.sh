#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2317
# tests/common/slave_runner.sh - Modular Slave Execution Proxy
#
# USAGE:
#   slave_runner.sh <strategy> <distro_name> <target_image> <run_log_dir>

set -euo pipefail

# Ensure repository root is working directory
cd "$(dirname "$0")/../.."

strategy="$1"
distro_name="$2"
target_image="$3"
run_log_dir="$4"

# Source common utilities
source "tests/common/logger.sh"
source "tests/common/diagnostics.sh"

box_name="test_${distro_name}_${strategy}"
out_log="${run_log_dir}/${distro_name}_${strategy}.log"
diag_log="${run_log_dir}/diagnostics_${distro_name}_${strategy}.log"

mkdir -p "$run_log_dir"

log_debug "Invoking slave plugin for strategy: '$strategy' on distro: '$distro_name' ($target_image)"

# Prepare environment for strategy script
export VERBOSITY
export SKIP_BOOTSTRAP="${SKIP_BOOTSTRAP:-false}"
export PATH="${PREFIX:-$HOME/.local}/bin:$PATH"

# shellcheck disable=SC2329
cleanup_proxy() {
    # If the script failed, capture diagnostics and print full traces to console for CI transparency
    if [[ "${exit_code:-0}" -ne 0 && "${exit_code:-0}" -ne 130 ]]; then
        run_diagnostic_hook "$box_name" "$diag_log"
        if [[ "${CI:-false}" == "true" ]]; then
            echo -e "\n==================== [ PRIMARY LOG OUTPUT ] ====================" >&2
            cat "$out_log" >&2 || true
            echo -e "==================== [ DIAGNOSTIC CAPTURE ] ====================" >&2
            cat "$diag_log" >&2 || true
            echo -e "================================================================\n" >&2
        fi
    fi
    :
}
trap 'cleanup_proxy' EXIT

start_time=$(date +%s)
exit_code=0

# Per-slave timeout (seconds) to prevent indefinite hangs; override via SLAVE_TIMEOUT env var
SLAVE_TIMEOUT="${SLAVE_TIMEOUT:-300}"

# Execute strategy validation script
if [[ "$VERBOSITY" == "debug" ]]; then
    # In debug mode, tee output to console for immediate rich feedback
    # Note: pipefail (set at top) ensures timeout exit code propagates through the pipe
    timeout --signal=TERM --kill-after=30 "$SLAVE_TIMEOUT" \
        bash "tests/strategies/${strategy}.sh" "$box_name" "$target_image" 2>&1 \
        | tee "$out_log" || exit_code=$?
else
    # In normal mode, capture output cleanly to file
    timeout --signal=TERM --kill-after=30 "$SLAVE_TIMEOUT" \
        bash "tests/strategies/${strategy}.sh" "$box_name" "$target_image" \
        >"$out_log" 2>&1 || exit_code=$?
fi
end_time=$(date +%s)
duration=$((end_time - start_time))

# Handle direct user interruption gracefully without triggering diagnostic noise
if [[ $exit_code -eq 130 ]]; then
    log_warn "Slave execution interrupted by user (Ctrl+C)."
    exit 130
elif [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
    log_error "Slave TIMED OUT: [${distro_name} / ${strategy}] after ${SLAVE_TIMEOUT}s limit. Printing execution and diagnostic logs below:"
    exit "$exit_code"
elif [[ $exit_code -ne 0 ]]; then
    log_error "Slave failure: [${distro_name} / ${strategy}] after ${duration}s. Printing execution and diagnostic logs below:"
    exit "$exit_code"
else
    log_success "Slave passed: [${distro_name} / ${strategy}] in ${duration}s."
    exit 0
fi
