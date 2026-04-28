---
sidebar_position: 2
---

# Strategies

DbxSmith uses **Strategies** as provisioning blueprints. A strategy is a named configuration that determines how a box is isolated, what identity it runs under, and where its home directory lives. You choose a strategy once at creation time — it is recorded in the registry and applied automatically on every subsequent entry.

## Strategy Comparison

| Strategy | Network | Home Dir | User | Hostname | Post-Init |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `standard` | Host-Bridge | Host `$HOME` | Host-User | Host hostname | PS1 & Theme Injection |
| `airgapped` | **None** (post-sever) | `~/boxes/<name>` | Host-User | Host hostname | Temp-bridge → first-run bootstrap → bridge destruction |
| `ghost` | Host-Bridge | Host `$HOME` | `ghostuser` | `ghost-shell` | `ghostuser` creation + PS1 & Theme Injection |
| `isolated-net` | Dedicated NAT-Bridge | `~/boxes/<name>` | Host-User | Host hostname | NAT bridge creation + PS1 & Theme Injection |

## Prerequisites

Before running any strategy, DbxSmith requires:

- **Engine**: <a href="https://distrobox.it/" target="_blank" rel="noopener noreferrer"><code>distrobox</code></a> and <a href="https://podman.io/" target="_blank" rel="noopener noreferrer"><code>podman</code></a> — if `distrobox` is missing, the installer will offer to set it up automatically.
- **Utilities**: `cksum` (color hashing), `base64` (init-hook payload injection), `awk` / `grep` (registry parsing and container list filtering).

---

## `standard` — Host-Mirrored Daily Driver

**Scenario:** You need a different OS (e.g. Alpine for testing, Ubuntu for a project) but want seamless access to all your host files, SSH keys, and your normal username.

**What changes:**
- **Network**: Host-bridge — full internet access, host services visible inside the container.
- **Home Dir**: Shared with host — `$HOME` is identical inside and outside.
- **User / Hostname**: Your actual host username and hostname.
- **Prompt**: Gains a cyan `(<name>)` marker prefix and a deterministic background color so you always know you're inside a box.

```bash
dbx-smith-spin standard devbox docker.io/library/ubuntu:latest dev
```

---

## `airgapped` — Zero-Network Vault

**Scenario:** You are working with sensitive code, untrusted scripts, or private keys and need a guarantee that nothing can reach the outside network.

**What changes:**
- **Network**: Permanently severed after first-run bootstrap. `ping 8.8.8.8` returns "Network is unreachable". No bridge, no DNS, no external routing.
- **Home Dir**: Isolated at `~/boxes/<name>` — host `~/.ssh`, `~/.gnupg`, and `.bash_history` are invisible from inside.
- **Two-phase provisioning**: A throwaway Podman network (`dbx-tmp-<name>`) is attached during `distrobox create` so packages can be installed. Once the first-run bootstrap completes, DbxSmith runs `podman network disconnect` then `podman network rm` — the bridge is permanently deleted.

```bash
dbx-smith-spin airgapped vault docker.io/library/alpine
```

---

## `ghost` — Obfuscated Identity

**Scenario:** You need to test scripts that behave differently based on username or hostname (e.g. permission-sensitive installers, CI scripts) without creating a real Linux user on your host.

**What changes:**
- **User**: `whoami` returns `ghostuser`. Created permanently inside the container via `useradd -m ghostuser`. The runtime (`dbx-smith`) automatically enters as this user — no manual flags needed.
- **Hostname**: `hostname` returns `ghost-shell`.
- **Network**: Host-bridge — full internet access.
- **Home Dir**: Shared with host `$HOME` — the ghost user operates in your real home directory.

```bash
dbx-smith-spin ghost tester docker.io/library/fedora
```

---

## `isolated-net` — Dedicated NAT Sandbox

**Scenario:** You are developing a service that needs its own dedicated network segment — to avoid port conflicts with other boxes or host services, or to get a reproducible private IP.

**What changes:**
- **Network**: The container's network namespace is unshared from the host (`--unshare-netns`) and attached to a dedicated Podman NAT bridge (`dbx-net-<name>`). Outbound internet works via NAT; the container is off the host's default bridge.
- **Home Dir**: Isolated at `~/boxes/<name>` — host sensitive directories not accessible.
- **Bridge lifecycle**: The `dbx-net-<name>` network persists until `dbx-smith-rm` is explicitly run.

```bash
dbx-smith-spin isolated-net microservice docker.io/library/debian
```
