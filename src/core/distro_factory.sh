#!/usr/bin/env bash
# shellcheck shell=bash

distro_factory() {
    local image
    image="$1"
    if [[ "$image" == *"ubuntu"* || "$image" == *"debian"* ]]; then
        # shellcheck source=src/distros/ubuntu.sh
        source "${SRC_DIR}/distros/ubuntu.sh"
    elif [[ "$image" == *"fedora"* || "$image" == *"rhel"* || "$image" == *"centos"* || "$image" == *"rocky"* || "$image" == *"alma"* ]]; then
        # shellcheck source=src/distros/fedora.sh
        source "${SRC_DIR}/distros/fedora.sh"
    elif [[ "$image" == *"alpine"* ]]; then
        # shellcheck source=src/distros/alpine.sh
        source "${SRC_DIR}/distros/alpine.sh"
    elif [[ "$image" == *"archlinux"* || "$image" == *"arch"* ]]; then
        # shellcheck source=src/distros/arch.sh
        source "${SRC_DIR}/distros/arch.sh"
    else
        # Default fallback (Ubuntu-like)
        # shellcheck source=src/distros/ubuntu.sh
        source "${SRC_DIR}/distros/ubuntu.sh"
    fi
}
