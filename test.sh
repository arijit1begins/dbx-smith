#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1090,SC2207
# test.sh - Master Orchestrator Test Runner for DbxSmith Framework
#
# Implements a decoupled, metadata-driven plugin architecture where adding distros
# or strategies simply requires adding files under tests/distros/ or tests/strategies/.

set -euo pipefail

# Ensure working directory is repository root
cd "$(dirname "$0")"

# Default configuration variables
TARGET_DISTRO="all"
TARGET_STRATEGY="all"
export VERBOSITY="info"
HALT_ON_FAILURE=false
RUN_UNIT_ONLY=false
RUN_MATRIX=true
export SKIP_BOOTSTRAP=false

# ANSI Formatting colors for Master console
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'

# Source common logger utilities
source "tests/common/logger.sh"

# Dynamically discover all pluggable distributions from metadata configurations
declare -A DISTRO_IMAGES=()
ALL_DISTROS=()

if [[ -d "tests/distros" ]]; then
    for conf_file in tests/distros/*.conf; do
        [[ -e "$conf_file" ]] || break
        unset DISTRO_NAME DISTRO_IMAGE
        source "$conf_file"
        if [[ -n "${DISTRO_NAME:-}" && -n "${DISTRO_IMAGE:-}" ]]; then
            ALL_DISTROS+=("$DISTRO_NAME")
            DISTRO_IMAGES["$DISTRO_NAME"]="$DISTRO_IMAGE"
        else
            log_warn "Malformed distro configuration file: $conf_file"
        fi
    done
fi

# Dynamically discover all pluggable strategies from validation scripts
ALL_STRATEGIES=()
if [[ -d "tests/strategies" ]]; then
    for strat_script in tests/strategies/*.sh; do
        [[ -e "$strat_script" ]] || break
        s_name=$(basename "$strat_script" .sh)
        if [[ "$s_name" != "common_asserts" ]]; then
            ALL_STRATEGIES+=("$s_name")
        fi
    done
fi

print_usage() {
    echo -e "${BOLD}DbxSmith Dynamic Master Test Suite Orchestrator${RESET}\n"
    echo -e "Usage: ./test.sh [OPTIONS]\n"
    echo -e "Options:"
    echo -e "  --full                  Execute full test suite across targeted distros and strategies"
    echo -e "  --unit-only             Execute only the fast unit tests layer"
    echo -e "  -d, --distro <name>     Target specific distro exclusively (default: all)"
    echo -e "                          Discovered plugins: ${ALL_DISTROS[*]:-none}"
    echo -e "  -s, --strategy <name>   Target specific strategy exclusively (default: all)"
    echo -e "                          Discovered plugins: ${ALL_STRATEGIES[*]:-none}"
    echo -e "  -v, --verbosity <level> Output verbosity: quiet, info, debug (default: info)"
    echo -e "  --skip-bootstrap        Skip distrobox first-entry bootstrap (fast iteration mode)"
    echo -e "  --halt-on-failure       Abort entire suite execution immediately upon first slave failure"
    echo -e "  --continue-on-failure   Record failure, execute diagnostics, and continue test matrix (default)"
    echo -e "  -h, --help              Display this help message and exit\n"
    echo -e "Examples:"
    echo -e "  ./test.sh --full                    # Run full unit and matrix integration tests"
    echo -e "  ./test.sh --unit-only               # Validate only unit payload and color generators"
    echo -e "  ./test.sh -d ubuntu -s airgapped    # Test Ubuntu Airgapped exclusively"
    echo -e "  ./test.sh --full --skip-bootstrap    # Fast iteration: skip slow container bootstrap"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --full)
            RUN_UNIT_ONLY=false
            RUN_MATRIX=true
            shift
            ;;
        --unit-only)
            RUN_UNIT_ONLY=true
            RUN_MATRIX=false
            shift
            ;;
        -d|--distro)
            TARGET_DISTRO="${2:-}"
            shift 2
            ;;
        -s|--strategy)
            TARGET_STRATEGY="${2:-}"
            shift 2
            ;;
        -v|--verbosity)
            export VERBOSITY="${2:-}"
            shift 2
            ;;
        --skip-bootstrap)
            export SKIP_BOOTSTRAP=true
            shift
            ;;
        --halt-on-failure)
            HALT_ON_FAILURE=true
            shift
            ;;
        --continue-on-failure)
            HALT_ON_FAILURE=false
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Unknown option: $1${RESET}" >&2
            print_usage
            exit 1
            ;;
    esac
done

# Validate selected distro filter
if [[ "$TARGET_DISTRO" != "all" ]]; then
    valid=false
    for d in "${ALL_DISTROS[@]}"; do
        if [[ "$d" == "$TARGET_DISTRO" ]]; then valid=true; break; fi
    done
    if [[ "$valid" == "false" ]]; then
        log_error "Invalid target distro: '$TARGET_DISTRO'. Discovered plugins: ${ALL_DISTROS[*]}"
        exit 1
    fi
fi

# Validate selected strategy filter
if [[ "$TARGET_STRATEGY" != "all" ]]; then
    valid=false
    for s in "${ALL_STRATEGIES[@]}"; do
        if [[ "$s" == "$TARGET_STRATEGY" ]]; then valid=true; break; fi
    done
    if [[ "$valid" == "false" ]]; then
        log_error "Invalid target strategy: '$TARGET_STRATEGY'. Discovered plugins: ${ALL_STRATEGIES[*]}"
        exit 1
    fi
fi

# Determine target list arrays based on filters
selected_distros=()
if [[ "$TARGET_DISTRO" == "all" ]]; then
    selected_distros=("${ALL_DISTROS[@]}")
else
    selected_distros=("$TARGET_DISTRO")
fi

selected_strategies=()
if [[ "$TARGET_STRATEGY" == "all" ]]; then
    selected_strategies=("${ALL_STRATEGIES[@]}")
else
    selected_strategies=("$TARGET_STRATEGY")
fi

# Initialize Log Run Output directory
RUN_TIMESTAMP=$(date -u +'%Y%m%d_%H%M%S')
RUN_LOG_DIR="test_runs/run_${RUN_TIMESTAMP}"
mkdir -p "$RUN_LOG_DIR"

echo -e "================================================================="
echo -e "${BOLD}${CYAN} DbxSmith Master Orchestrator Suite Initializing${RESET}"
echo -e " Run Output Directory: ${RUN_LOG_DIR}"
echo -e " Execution Mode:       $([[ "$RUN_UNIT_ONLY" == "true" ]] && echo "Unit Tests Only" || echo "Full/Matrix")"
echo -e " Distros Filter:       ${TARGET_DISTRO}"
echo -e " Strategies Filter:    ${TARGET_STRATEGY}"
echo -e " Verbosity Level:      ${VERBOSITY}"
echo -e " Skip Bootstrap:       ${SKIP_BOOTSTRAP}"
echo -e " Halt on Failure:      ${HALT_ON_FAILURE}"
echo -e "=================================================================\n"

# 1. Install Suite Core Binaries once globally before executing tasks
log_info "Ensuring latest suite code is globally installed..."
make install >"${RUN_LOG_DIR}/master_make_install.log" 2>&1 || {
    log_error "Global make install failed! Printing log contents below:"
    cat "${RUN_LOG_DIR}/master_make_install.log" >&2
    exit 1
}

# 2. Run Modular Unit Tests
log_info "Executing Unit Test Layer..."
unit_passed=0
unit_failed=0

if [[ -d "tests/unit" ]]; then
    for unit_file in tests/unit/*.sh; do
        [[ -e "$unit_file" ]] || break
        unit_name=$(basename "$unit_file")
        log_debug "Running unit test: $unit_name"
        
        unit_log="${RUN_LOG_DIR}/unit_${unit_name}.log"
        unit_code=0
        bash "$unit_file" >"$unit_log" 2>&1 || unit_code=$?
        
        if [[ $unit_code -eq 0 ]]; then
            log_success "Unit Test Passed: $unit_name"
            unit_passed=$((unit_passed + 1))
        else
            if [[ $unit_code -eq 130 ]]; then
                log_error "Execution interrupted by user (Ctrl+C). Halting suite."
                exit 130
            fi
            log_error "Unit Test Failed: $unit_name. See log: $unit_log"
            unit_failed=$((unit_failed + 1))
            if [[ "$HALT_ON_FAILURE" == "true" ]]; then
                log_error "Halt-on-failure triggered during unit test layer."
                exit 1
            fi
        fi
    done
else
    log_warn "No unit tests directory found at 'tests/unit'."
fi

if [[ "$RUN_UNIT_ONLY" == "true" ]]; then
    echo -e "\n================================================================="
    echo -e " ${BOLD}Unit Suite Summary Metrics:${RESET}"
    echo -e "   Unit Tests Passed: ${GREEN}${unit_passed}${RESET}"
    echo -e "   Unit Tests Failed: ${RED}${unit_failed}${RESET}"
    echo -e "================================================================="
    if [[ $unit_failed -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
fi

# 3. Build & Execute Integration Matrix via Modular Slave Run Proxy
log_info "Executing Slave Matrix Layer..."

declare -a REPORT_ROWS=()
total_executed=0
total_passed=0
total_failed=0

for distro in "${selected_distros[@]}"; do
    img="${DISTRO_IMAGES[$distro]}"
    for strat in "${selected_strategies[@]}"; do
        total_executed=$((total_executed + 1))
        echo -e "\n-----------------------------------------------------------------"
        log_info "Dispatching Slave: [${BOLD}${distro}${RESET} / ${BOLD}${strat}${RESET}]"
        
        start_ts=$(date +%s)
        slave_status="PASS"
        slave_code=0
        
        # Invoke slave worker proxy
        bash "tests/common/slave_runner.sh" "$strat" "$distro" "$img" "$RUN_LOG_DIR" || slave_code=$?
        
        end_ts=$(date +%s)
        duration=$((end_ts - start_ts))
        
        # Instantly break the matrix orchestration loop on SIGINT interrupt
        if [[ $slave_code -eq 130 ]]; then
            log_error "Suite execution interrupted by user (Ctrl+C). Halting orchestrator."
            exit 130
        fi
        
        out_path="${RUN_LOG_DIR}/${distro}_${strat}.log"
        diag_path="${RUN_LOG_DIR}/diagnostics_${distro}_${strat}.log"
        
        if [[ $slave_code -eq 0 ]]; then
            slave_status="PASS"
            total_passed=$((total_passed + 1))
            REPORT_ROWS+=("$(printf "%-10s|%-20s|%-6s|%-5s|%s" "$distro" "$strat" "PASS" "${duration}s" "$out_path")")
        else
            slave_status="FAIL"
            total_failed=$((total_failed + 1))
            REPORT_ROWS+=("$(printf "%-10s|%-20s|%-6s|%-5s|%s" "$distro" "$strat" "FAIL" "${duration}s" "$diag_path")")
            
            if [[ "$HALT_ON_FAILURE" == "true" ]]; then
                log_error "Halt-on-failure setting active. Terminating remaining matrix execution."
                break 2
            fi
        fi
    done
done

# 4. Consolidate Results and Render Final Unified Analysis Report
echo -e "\n================================================================="
echo -e "${BOLD}${CYAN} Consolidated Final Execution Report${RESET}"
echo -e "================================================================="
printf " %-10s | %-20s | %-6s | %-5s | %s\n" "DISTRO" "STRATEGY" "STATUS" "TIME" "PRIMARY LOG / DIAGNOSTIC"
echo "------------+----------------------+--------+-------+----------------------------------------"

for row in "${REPORT_ROWS[@]}"; do
    d=$(echo "$row" | cut -d'|' -f1)
    s=$(echo "$row" | cut -d'|' -f2)
    st=$(echo "$row" | cut -d'|' -f3)
    t=$(echo "$row" | cut -d'|' -f4)
    lp=$(echo "$row" | cut -d'|' -f5)
    
    if [[ "$st" == "PASS" ]]; then
        printf " %-10s | %-20s | ${GREEN}%-6s${RESET} | %-5s | %s\n" "$d" "$s" "$st" "$t" "$lp"
    else
        printf " %-10s | %-20s | ${RED}%-6s${RESET} | %-5s | %s\n" "$d" "$s" "$st" "$t" "$lp"
    fi
done

echo -e "================================================================="
echo -e " ${BOLD}Summary Metrics:${RESET}"
echo -e "   Total Scenarios Executed: ${total_executed}"
echo -e "   Total Passed:             ${GREEN}${total_passed}${RESET}"
echo -e "   Total Failed:             ${RED}${total_failed}${RESET}"
echo -e "   Unit Tests Passed/Failed: ${unit_passed}/${unit_failed}"
echo -e "================================================================="

# Final exit code derivation
if [[ $total_failed -gt 0 || $unit_failed -gt 0 ]]; then
    log_error "Suite finished with failures."
    exit 1
else
    log_success "Suite finished perfectly. All assertions satisfied."
    exit 0
fi
