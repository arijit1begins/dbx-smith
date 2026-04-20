---
sidebar_position: 3
---

# Architecture & Engineering Deep-Dive

This document provides a detailed dissection of the **DbxSmith** suite, its internal mechanics, and how different components interact to forge isolated developer environments.

## System Overview

DbxSmith operates as a wrapper and orchestration layer over **Distrobox** and **Podman**. It adds a stateful registry, strategic provisioning, and shell-level UI integration.

## Infrastructure & Boundary Map

The following diagram illustrates the boundaries between the Host system, the DbxSmith orchestration layer, and the provisioned environments.

```mermaid
graph TB
    subgraph Host ["Host OS (Linux)"]
        direction TB
        Shell[User Shell: Bash/Zsh]
        ConfigDir["~/.config/dbx-smith/"]
        Registry["/registry (JSON Manifests)"]
        Aliases["/aliases.d (Shell Fragments)"]
        
        subgraph Engine ["Container Engine"]
            Podman[Podman Runtime]
            DBX[Distrobox CLI]
        end
        
        ConfigDir --- Registry
        ConfigDir --- Aliases
    end

    subgraph DbxSmith ["DbxSmith Orchestration Layer"]
        Spin[dbx-smith-spin]
        Runtime[dbx-smith.sh]
        RM[dbx-smith-rm]
    end

    subgraph Box ["Distrobox Boundary (The Forge)"]
        direction TB
        subgraph BoxInternal ["Internal Environment"]
            ProfileD["/etc/profile.d/ (Theme Injected)"]
            BoxUser["User: hostuser or ghostuser"]
            BoxHome["$HOME: Linked or Isolated"]
        end
        
        subgraph Net ["Network Strategy"]
            Bridge[Host Bridge]
            Null[No Network]
            NAT[NAT / Private Subnet]
        end
    end

    %% Connections
    Shell --> Runtime
    Runtime -- "Reads State" --> Aliases
    Spin -- "Forges" --> Box
    Spin -- "Registers" --> Registry
    Spin -- "Invokes" --> DBX
    DBX -- "Manages" --> Podman
    RM -- "Atomic Wipe" --> Box
    RM -- "Wipes State" --> Registry
```


### High-Level Component Map

```mermaid
graph TD
    User([User]) --> Spin[dbx-smith-spin]
    User --> Runtime[dbx-smith runtime]
    User --> RM[dbx-smith-rm]

    subgraph "The Forge (Provisioning)"
        Spin --> Registry[(Manifest Registry)]
        Spin --> Strategy{Strategies}
        Strategy --> |standard| StdBox[Distrobox: Host-Linked]
        Strategy --> |airgapped| AirBox[Distrobox: Offline Vault]
        Strategy --> |ghost| GhostBox[Distrobox: Transient Identity]
        Strategy --> |isolated-net| NetBox[Distrobox: Private Network]
    end

    subgraph "The Runtime"
        Runtime --> Completion[Shell Completion]
        Runtime --> Alias[Dynamic Aliases]
        Runtime --> Registry
    end

    subgraph "The Cleanup"
        RM --> Registry
        RM --> Alias
        RM --> Containers[Podman/Distrobox]
    end
```

---

## The Provisioning Flow

When you run `dbx-smith-spin`, the following sequence occurs:

```mermaid
sequenceDiagram
    participant U as User
    participant S as dbx-smith-spin
    participant R as Registry
    participant D as Distrobox/Podman
    participant C as Container FS

    U->>S: Run spin (e.g. strategy: airgapped)
    S->>S: Validate Prerequisites (Distrobox check)
    S->>R: Write Manifest (~/.config/dbx-smith/registry/name)
    S->>D: Execute 'distrobox create' with strategic flags
    D-->>C: Create container & Home dir
    S->>S: Calculate Image CRC32
    S->>C: Inject UI Theme into /etc/profile.d/
    alt Strategy is Airgapped
        S->>D: Execute Bridge-Destruction hack
    end
    S->>S: Generate Alias Fragment
    S-->>U: Provisioning Complete
```

---

## Script Dissection

### 1. `bin/dbx-smith-spin` (The Architect)
This is the core provisioning logic.
- **Image Checksumming**: Uses `cksum` on the image name to generate a deterministic seed.
- **Theme Generation**: Converts the checksum seed into HSL values. This ensures that every time you pull `ubuntu:latest`, your "standard" boxes have consistent, distinct colors.
- **Isolation Logic**: 
  - For **Airgapped**, it uses `--additional-flags "--network=none"` during create, but since Distrobox often mounts host network files, it explicitly wipes `/etc/resolv.conf` and `/etc/hosts` fragments inside the box post-init.

### 2. `src/dbx-smith.sh` (The Pulse)
The runtime core that lives in your shell.
- **Dynamic Sourcing**: It doesn't just store aliases; it sources them from `~/.config/dbx-smith/aliases.d/`. This allows you to "hot-swap" environment access without restarting your shell.
- **The Wrapper**: `dbx-smith()` function intercepts the container name and checks the registry before calling `distrobox enter`.

### 3. `bin/dbx-smith-rm` (The Reaper)
Ensures zero-drift teardowns.
- **Atomic Deletion**: It reads the registry to find exactly what was created (aliases, home directories, containers) and wipes them in one pass.

---

## Strategic Visualizations

### Standard Strategy
*   **Visual**: Terminal colors match the host. Identical prompt appearance.
*   **Networking**: Fully transparent.
*   **Use Case**: Your daily driver. Node.js development, Go, etc., where you just need a different OS but same host files.

### Airgapped Strategy
*   **Visual**: Distinct, often muted or "alert" colors (e.g., deep red or gray background).
*   **Networking**: `ping` returns "Network is unreachable". `/etc/resolv.conf` is empty.
*   **Home Dir**: Located at `~/dbx-homes/<name>`. Your host `.ssh` and `.bash_history` are invisible.
*   **Use Case**: Analyzing untrusted scripts, managing private keys, or "focused" offline coding.

### Ghost Strategy
*   **Visual**: Usually high-contrast or unique themes to remind you that you are a "ghost".
*   **Identity**: Running `whoami` returns `ghostuser`.
*   **Use Case**: Testing permission-sensitive scripts or developing with a clean-slate user identity without creating a real Linux user on the host.

### Isolated-Net Strategy
*   **Visual**: Network-themed color accents (e.g., blue or cyan).
*   **Networking**: Isolated bridge with a private subnet. Host is reachable, but the container cannot be reached by other containers on the host bridge.
*   **Home Dir**: Usually isolated at `~/dbx-homes/<name>`.
*   **Use Case**: Developing microservices or web apps that require a dedicated, non-clashing IP address or a private network segment.

---

## Database Schema (The Registry)

DbxSmith avoids heavy databases. It uses a **Key-Value Flatfile** system:

**Path**: `~/.config/dbx-smith/registry/<box_name>`

```bash
# Example Manifest
BOX_NAME="vault"
STRATEGY="airgapped"
IMAGE="alpine:latest"
HOME_DIR="/home/user/dbx-homes/vault"
THEME_SEED="38472910"
CREATED_AT="2026-04-21T00:15:00Z"
```

---

## Summary of Interaction

| Feature | `spin` | `runtime` | `rm` |
| :--- | :---: | :---: | :---: |
| Writes Registry | ✅ | ❌ | ❌ |
| Reads Registry | ✅ | ✅ | ✅ |
| Deletes Registry | ❌ | ❌ | ✅ |
| Injects UI | ✅ | ❌ | ❌ |
| Loads Aliases | ❌ | ✅ | ❌ |
