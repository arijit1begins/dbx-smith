#!/usr/bin/env bash
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
export PATH="${PREFIX:-$HOME/.local}/bin:$PATH"

start_time=$(date +%s)
exit_code=0

# Execute strategy validation script
if [[ "$VERBOSITY" == "debug" ]]; then
    # In debug mode, tee output to console for immediate rich feedback
    bash "tests/strategies/${strategy}.sh" "$box_name" "$target_image" 2>&1 | tee "$out_log" || exit_code=$?
else
    # In normal mode, capture output cleanly to file
    bash "tests/strategies/${strategy}.sh" "$box_name" "$target_image" >"$out_log" 2>&1 || exit_code=$?
fi
end_time=$(date +%s)
duration=$((end_time - start_time))

# Report back status to Master via standard exit codes and diagnostic hook triggers
if [[ $exit_code -ne 0 ]]; then
    log_error "Slave failure: [${distro_name} / ${strategy}] after ${duration}s. See log: $out_log"
    run_diagnostic_hook "$box_name" "$diag_log"
    # Ensure cleanup attempt on failure
    dbx-smith-rm --purge "$box_name" >/dev/null 2>&1 || true
    exit "$exit_code"
else
    log_success "Slave passed: [${distro_name} / ${strategy}] in ${duration}s."
    exit 0
fi
