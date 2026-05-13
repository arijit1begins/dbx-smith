#!/usr/bin/env bash
# tests/common/diagnostics.sh - Diagnostic probing hooks for Podman failures

# Source logger if available
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/logger.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
fi

run_diagnostic_hook() {
    local box_name="$1"
    local diag_file="$2"

    log_warn "Failure detected for container '$box_name'. Triggering diagnostic hook..."
    
    # Ensure directory for diagnostic log exists
    mkdir -p "$(dirname "$diag_file")"

    {
        echo "================================================================="
        echo " DIAGNOSTIC PROBE REPORT - $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
        echo " Target Container: $box_name"
        echo "================================================================="
        
        echo -e "\n---> 1. PODMAN PS (All Containers) <---"
        podman ps -a 2>&1 || true

        echo -e "\n---> 2. TARGET CONTAINER INSPECT <---"
        podman inspect "$box_name" 2>&1 || echo "[!] Podman inspect failed or container does not exist."

        echo -e "\n---> 3. TARGET CONTAINER LOGS <---"
        podman logs "$box_name" 2>&1 || echo "[!] Podman logs failed or container does not exist."

        echo -e "\n---> 4. PODMAN NETWORKS <---"
        podman network ls 2>&1 || true

        local expected_net="dbx-net-${box_name}"
        echo -e "\n---> 5. ISOLATED NETWORK INSPECT ($expected_net) <---"
        podman network inspect "$expected_net" 2>&1 || echo "[!] Network '$expected_net' not found or inspect failed."

        echo -e "\n================================================================="
        echo " END DIAGNOSTIC REPORT"
        echo "================================================================="
    } >> "$diag_file"

    log_info "Diagnostics recorded to: $diag_file"
}
