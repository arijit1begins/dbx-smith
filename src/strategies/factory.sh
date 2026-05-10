#!/usr/bin/env bash

# Strategy Factory
strategy_factory() {
    local strategy_name="$1"
    local strategy_file="${SRC_DIR}/strategies/${strategy_name}.sh"

    if [[ -f "$strategy_file" ]]; then
        # shellcheck source=/dev/null
        source "$strategy_file"
    else
        echo "Error: Unknown strategy '$strategy_name'." >&2
        exit 1
    fi
}

# Every strategy file should implement:
# - strategy_${name}_get_flags(name, image, payload)
# - strategy_${name}_finalize(name, strategy, image, alias, bind)
