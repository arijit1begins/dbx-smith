# DbxSmith

![CI/CD](https://img.shields.io/github/actions/workflow/status/arijit1begins/dbx-smith/ci.yml?branch=main&label=CI%2FCD&style=flat-square)
![Release](https://img.shields.io/github/v/release/arijit1begins/dbx-smith?style=flat-square)
![License](https://img.shields.io/github/license/arijit1begins/dbx-smith?style=flat-square)
![CNCF Sandbox](https://img.shields.io/badge/CNCF-Sandbox_Pending-blue?style=flat-square)

A highly modular, professional-grade Developer Productivity Suite built on top of Distrobox and Podman. Designed with strict adherence to Linux standards, this suite provides instant, ephemeral, or persistent isolated environments directly accessible from your shell (Bash and Zsh).

## Features
- **Idempotent & Self-Healing**: Automatically repairs missing infrastructure.
- **Cross-Shell Compatible**: Native support for both Zsh (`compdef`, `bindkey`) and Bash (`complete -F`, `bind -x`).
- **Zero Configuration Drift**: Atomic teardowns wipe containers, isolated volume data, and alias fragments.
- **Deterministic UI**: Background terminal colors are derived procedurally from the image hash.
- **Manifest Registry**: Pure-shell manifest parser ensures deterministic state management.

## Installation

You can install this suite locally without `sudo` privileges. By default, it installs to `~/.local/bin` and `~/.config/dbx-smith`.

### Using the Quick Installer
```bash
curl -fsSL https://raw.githubusercontent.com/arijit1begins/dbx-smith/main/install.sh | bash
```
*(Or simply run `./install.sh` if you have cloned the repository).*

### Using Make
```bash
make install
```
After installation, follow the on-screen instructions to source the runtime core in your `~/.bashrc` or `~/.zshrc`.

## Usage

### 1. Provisioning a new box (`dbx-smith-spin`)
`dbx-smith-spin` is the CLI Factory/Provisioner. It can be run interactively by providing no arguments, or headlessly via CLI flags.

```bash
dbx-smith-spin [options] [strategy] [name] [image] [alias] [bindkey]
```

**Strategies:**
- `standard`: Frictionless, host-mirrored daily driver environment.
- `airgapped`: Zero-network vault with an isolated, private home directory. (Uses the Bridge-Destruction hack to initialize offline).
- `ghost`: Identity obfuscation running as a transient user (`ghostuser`).
- `isolated-net`: Secure sandbox with a dedicated, host-blind NAT bridge network.

**Arguments:**
- `alias`: (Optional) Automatically writes a dynamic shell alias fragment to `aliases.d`.
- `bindkey`: (Optional) Automatically binds a Zsh/Bash keyboard shortcut (e.g., `^G`).

**Example:**
```bash
dbx-smith-spin airgapped devtools docker.io/library/ubuntu:latest devbox "^V"
```

### 2. The Runtime Core (`dbx-smith.sh`)
You can jump into any provisioned box using the `dbx-smith` command provided by the runtime core. Auto-completion is fully supported out of the box!
```bash
dbx-smith devtools
```

### 3. Teardown (`dbx-smith-rm`)
Tear down the environment atomically with `dbx-smith-rm`. It prevents configuration drift by ensuring all registry manifests and UI fragments are wiped.
```bash
dbx-smith-rm --purge devtools
```

## Uninstallation
```bash
make uninstall
```
