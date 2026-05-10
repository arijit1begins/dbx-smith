#!/usr/bin/env bash
# shellcheck shell=bash

strategy_standard_get_flags() {
    local name
    name="$1"
    local image
    image="$2"
    local payload
    payload="$3"
    
    local init_hook
    init_hook="echo '$payload' | base64 -d | sh"
    # shellcheck disable=SC2034
    DBX_FLAGS=(--name "$name" --image "$image" --init-hooks "$init_hook")
}

strategy_standard_finalize() {
    local name
    name="$1"
    local strategy
    strategy="$2"
    local image
    image="$3"
    local usr_alias
    usr_alias="$4"
    local usr_bind
    usr_bind="$5"

    write_manifest "$name" "$strategy" "$image"
    register_shortcuts "$name" "$usr_alias" "$usr_bind"
}
