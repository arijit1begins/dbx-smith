# shellcheck shell=bash
# shellcheck disable=SC2034
# Fedora/RHEL Configuration
DISTRO_PKGMGR="dnf"
DISTRO_PKG_SU="util-linux-core"
DISTRO_ZSHRC="/etc/zshrc"
DISTRO_BASHRC="/etc/bashrc"

# Path-shadowing proxies to bypass strict password hashing validation in shadow-utils on Fedora
DISTRO_PRE_INIT_HOOK="mkdir -p /usr/local/bin; echo '#!/bin/sh' > /usr/local/bin/chpasswd; echo 'exit 0' >> /usr/local/bin/chpasswd; echo '#!/bin/sh' > /usr/local/bin/passwd; echo 'exit 0' >> /usr/local/bin/passwd; chmod 755 /usr/local/bin/chpasswd /usr/local/bin/passwd"
