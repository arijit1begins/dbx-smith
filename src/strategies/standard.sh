#!/usr/bin/env bash

strategy_standard_get_flags() {
    local name="$1"
    local image="$2"
    local payload="$3"
    
    local init_hook="echo '$payload' | base64 -d | sh"
    DBX_FLAGS=(--name "$name" --image "$image" --init-hooks "$init_hook")
}

strategy_standard_finalize() {
    local name="$1"
    local strategy="$2"
    local image="$3"
    local usr_alias="$4"
    local usr_bind="$5"

    write_manifest "$name" "$strategy" "$image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
