---
sidebar_position: 2
---

# Technical Specification

DbxSmith is a modular provisioning and management suite for Distrobox/Podman environments. This document outlines the technical architecture, data structures, and runtime mechanics of the suite.

## Core Components

### 1. The Provisioner (`dbx-smith-spin`)
The provisioner is a stateless CLI tool that interprets **Strategies** to create Distrobox containers.
- **Input**: CLI flags or interactive prompts.
- **Output**: A provisioned Distrobox container and a JSON manifest in the Registry.
- **Logic**: Implements strategy-specific hooks (e.g., bridge destruction for `airgapped`).

### 2. The Registry (`~/.config/dbx-smith/registry`)
A lightweight, filesystem-based database of provisioned boxes.
- Each box has a manifest file named after its container name.
- **Schema**:
  ```bash
  STRATEGY="standard"
  IMAGE="docker.io/library/ubuntu:latest"
  ALIAS="devbox"
  BINDKEY="^G"
  CKSUM="123456789"
  ```

### 3. The Runtime Core (`dbx-smith.sh`)
A shell-agnostic runtime injected into the user's `~/.bashrc` or `~/.zshrc`.
- **Functions**:
  - `dbx-smith <name>`: Wrapper for `distrobox enter`.
  - **Dynamic Alias Loading**: Sources fragments from `~/.config/dbx-smith/aliases.d/`.
  - **Completion**: Native Bash/Zsh completion scripts.

## Provisioning Strategies

| Strategy | Network | Home Dir | User | Post-Init Hooks |
| :--- | :--- | :--- | :--- | :--- |
| `standard` | Host-Bridge | Host-Home | Host-User | None |
| `airgapped` | **None** | Isolated | Host-User | Bridge Destruction |
| `ghost` | Host-Bridge | Host-Home | `ghostuser` | Identity Obfuscation |
| `isolated-net` | NAT-Bridge | Isolated | Host-User | IP Routing Setup |

## UI & Aesthetics
- **Theme Injection**: The provisioner calculates a CRC32 checksum of the base image.
- **Color Mapping**: The checksum is mapped to an HSL color space to generate a unique background/accent color for the container's terminal profile.
- **Profile.d**: Scripts are injected into the container's `/etc/profile.d/` to set shell variables (e.g., `DBX_SMITH_THEME`).

## Security Model
- **Bridge Destruction**: In `airgapped` mode, DbxSmith severs the container's network bridge during the initialization phase, ensuring that even if the container is "restarted," it remains offline.
- **Isolated Home**: Uses `--home` to prevent containerized applications from accessing sensitive host data in `~/.ssh`, `~/.gnupg`, etc.
