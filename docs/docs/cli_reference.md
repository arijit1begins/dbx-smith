---
sidebar_position: 4
---

# CLI Reference & Usage

This document serves as the consolidated command-line interface (CLI) reference and user guide for all DbxSmith commands. 

---

## Command Overview

The DbxSmith suite is composed of five core CLI tools and an runtime integration layer:

| Command | Role | Invocation Pattern |
|:---|:---|:---|
| **`dbx-smith`** | Runtime & Entry wrapper | Sourced alias / dynamic function |
| **`dbx-smith-spin`** | Environment Provisioner | Executable binary / script |
| **`dbx-smith-dash`** | Mission Control (TUI) | Executable (via `dbx-smith dash`) |
| **`dbx-smith-list`** | Inventory Explorer | Executable (via `dbx-smith list`) |
| **`dbx-smith-rm`** | Atomic Destructor | Executable binary / script |
| **`dbx-smith-uninstall`** | Clean Uninstaller | Executable utility |

---

## `dbx-smith` — Runtime & Entry Point

The `dbx-smith` command is a highly optimized shell function loaded into your active Bash/Zsh session. It intercepts container names, reads the stateful registry, and enforces correct strategy options upon entry.

### Syntax
```bash
dbx-smith <subcommand | box_name> [additional_args...]
```

### Subcommands & Arguments
* **`list`**  
  Delegates directly to `dbx-smith-list` to print a cleanly formatted table of all containers.
* **`dash`**  
  Launches the interactive, zero-flicker TUI Dashboard (`dbx-smith-dash`).
* **`-h, --help`**  
  Displays the command syntax, subcommands, and options.
* **`<box_name>`**  
  Enters the specified box name. The wrapper automatically queries `~/.config/dbx-smith/registry/` to determine the active strategy.
  * For **Ghost** strategies: Automatically injects `--user ghostuser --workdir /home/ghostuser`.
  * For **Airgapped / Isolated-Net** strategies: Injects `--no-workdir` to prevent leaks.
* **`[additional_args...]`**  
  Any arguments specified after `<box_name>` are safely forwarded directly to the container's shell (e.g., `dbx-smith devbox ls -la`).

### Exit Codes
* `0`: Clean exit from the container shell or TUI.
* `1`: Container does not exist, missing arguments, or Distrobox engine failure.

---

## `dbx-smith-spin` — The Provisioner

The **architect** of DbxSmith. It validates image/box details, sets up host resources, compiles internal setup hooks, and provisions the Distrobox container using the selected strategy.

### Syntax
```bash
dbx-smith-spin [options] [strategy] [name] [image] [alias] [bindkey]
```

> [!TIP]
> **Interactive Wizard**: If you call `dbx-smith-spin` with no arguments, it launches an interactive command-line prompt wizard requesting each value one by one.

### Options
* `-h, --help`  
  Show the usage menu and exit.
* `-v, --version`  
  Show version information (`dbx-smith-spin v1.x.x`) and exit.

### Positional Parameters
1. **`strategy`** (Required)  
   The isolation blueprint. Must be one of:
   * `standard` — Host-mirrored daily driver.
   * `airgapped` — Zero-network vault with private persistent home.
   * `ghost` — Ephemeral identity sandbox (`ghostuser`).
   * `isolated-net` — Network sandbox with a dedicated NAT bridge.
   * `ghost-airgapped` — EPhemeral identity with zero-network isolation.
   * `ghost-isolated-net` — Ephemeral identity with NAT bridge isolation.
2. **`name`** (Required)  
   The unique name for the new box container.
3. **`image`** (Required)  
   The source OCI image path (e.g., `docker.io/library/alpine:latest` or `fedora:latest`).
4. **`alias`** (Optional)  
   A custom shortcut command name created on your host. Typing this command will instantly connect you to the box.
5. **`bindkey`** (Optional)  
   A shell keyboard shortcut (e.g., `^G` or `\eg` for Alt-G) to launch/enter the container instantly.

### Examples
Provision a secure, network-isolated Ubuntu service box:
```bash
dbx-smith-spin isolated-net db-service ubuntu:latest
```
Provision a rapid standard daily driver with a host-level shortcut alias `dev`:
```bash
dbx-smith-spin standard devbox docker.io/library/fedora:latest dev
```

---

## `dbx-smith-dash` — TUI Mission Control

The interactive, high-performance TUI dashboard. It allows you to monitor all environments, start/stop them, trigger background builds/deletions, or enter containers at the hit of a key.

### Controls Reference

| Keyboard Shortcut | Context | Description / Action |
|:---:|:---|:---|
| `↑` / `↓` | Main Menu | Move the selection cursor up or down the container list. |
| `Enter` | Main Menu | Connect / enter the selected container instantly. |
| `+` or `=` | Main Menu | Launch the **Smart Provisioning Wizard**. |
| `s` | Main Menu | Stop the selected running container. |
| `r` | Main Menu | Atomic destruction of the selected container (asynchronous). |
| `l` | Task Overlay | Toggle detail logs on/off during an active background provision/removal. |
| `q` or `Esc` | Main Menu | Exit the dashboard and restore the terminal state. |
| `Esc` | Wizard | Go back to the previous step in the Creation Wizard. |
| `[Cancel]` | Wizard | Cancel and abort the Creation Wizard entirely. |

### Smart Wizard Flow
1. **Strategy**: Choose standard, ghost, airgapped, isolated-net, or hybrids.
2. **Name**: Type a unique name.
3. **Image Source**: Enter the OCI image path.
4. **Host Alias**: Define a optional host shortcut.
5. **Hot-Key**: Define a shell bindkey (e.g. `^F`).

---

## `dbx-smith-list` — Inventory Explorer

Prints a structured, colored overview of all active Distrobox containers coupled with their custom DbxSmith metadata.

### Syntax
```bash
dbx-smith-list [options]
```

### Options
* `-h, --help`  
  Show the help dialog.

### Columns Output
* **`NAME`**: The container's name.
* **`STRATEGY`**: The assigned DbxSmith provisioning strategy (color-coded).
* **`IMAGE`**: The guest OCI image (truncated if it exceeds 24 characters).
* **`STATUS`**: Current container execution state (e.g., `Up 4 hours` in green, or `Exited`).
* **`CREATED`**: Date when DbxSmith recorded the container's registry file.

---

## `dbx-smith-rm` — The Atomic Destructor

Ensures zero-drift deletions. It tears down containers and automatically detects and sweeps up associated resources from your host filesystem.

### Syntax
```bash
dbx-smith-rm [options] <box_name> [box_name_2 ...]
```

### Options
* `-h, --help`  
  Show the help menu.
* `-a, --all`  
  Discover and select *all* containers listed in the registry or Distrobox engine for teardown. Prompts for bulk confirmation.
* `-f, --force`  
  Skip the bulk confirmation prompt (safe for automated scripts).
* `-p, --purge`  
  Performs deep system scrubbing: removes the container, wipes isolated home directories (`~/boxes/<name>`), removes host alias configurations, deletes the registry manifest, tears down isolated NAT bridges (`dbx-net-<name>`), and purges underlying Podman persistent volume states.

### Examples
Force purge multiple boxes simultaneously without prompt:
```bash
dbx-smith-rm vault-box micro-service --purge --force
```

---

## `dbx-smith-uninstall` — Uninstaller

Allows for a clean, effortless removal of the DbxSmith productivity suite from your host system.

### Syntax
```bash
dbx-smith-uninstall
```

### Actions Performed
1. Wipes all installed command executables (`dbx-smith-spin`, `dbx-smith-rm`, `dbx-smith-uninstall`) from `~/.local/bin/`.
2. Wipes DbxSmith manual files (`dbx-smith-spin.1`, `dbx-smith-rm.1`) from custom share directories.
3. Completely deletes the active configuration database directory `~/.config/dbx-smith/` (including all saved aliases and manifests).
4. Safely parses and removes the global `source .../dbx-smith.sh` loading sequence from your `~/.bashrc` or `~/.zshrc`.

> [!IMPORTANT]
> **Container Preservation**: Running `dbx-smith-uninstall` will **never** alter or delete your active containers. Your guest environments remain intact and can still be entered or removed manually using native `distrobox` and `podman` CLI commands.
