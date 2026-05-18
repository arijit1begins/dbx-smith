---
sidebar_position: 2
---

# Shell Configuration Engineering

This document provides a deep dive into how DbxSmith manages shell environments, themes, and user identities across different isolation strategies and Linux distributions.

---

## I. The "Hook" Architecture

One of the primary engineering challenges in container orchestration is ensuring that the container's visual identity (e.g., prompt prefix and terminal background color) persists even if the user has custom dotfiles (`.bashrc`, `.zshrc`) that override standard environment variables.

### 1. Persistence via Hooks
Instead of direct `PS1` or `PROMPT` assignment, DbxSmith injects shell-specific hooks into the container's global configuration. These hooks execute dynamically before every prompt is rendered:

- **Bash**: Prepends a function to `PROMPT_COMMAND`. This ensures that even if `PS1` is redefined in `~/.bashrc`, the DbxSmith function will run immediately after and re-apply the cyan `(box-name)` prefix.
- **Zsh**: Appends to the `precmd_functions` array. This is the idiomatic Zsh way to run logic before a prompt, ensuring the `(box-name)` prefix survives Zsh theme engines like Oh-My-Zsh or Powerlevel10k.

### 2. Terminal Background Injection (OSC 11)
DbxSmith uses the `OSC 11` escape sequence (`\e]11;#RRGGBB\a`) to set the terminal emulator's background color.
- **Inside the box**: The hook sends the sequence based on the image's deterministic hash.
- **On exit**: The host runtime (`dbx-smith.sh`) sends `\e]111\a` (OSC 111 - Reset to Default) to restore the terminal's native colors, with a black fallback for maximum compatibility.

---

## II. Strategy & Distro Matrix

The following matrix outlines the specific engineering actions taken by DbxSmith during the provisioning phase, mapped by strategy and distribution family.

| Strategy | Action Layer | Debian / Ubuntu / Kali | Fedora / RHEL / CentOS | Arch Linux / Alpine |
| :--- | :--- | :--- | :--- | :--- |
| **All Strategies** | **Global Config** | Inject to `/etc/bash.bashrc` & `/etc/zsh/zshrc` | Inject to `/etc/bashrc` & `/etc/zshrc` | Inject to `/etc/bashrc` & `/etc/zshrc` |
| | **Visuals** | OSC 11 Background + `PROMPT_COMMAND` / `precmd` hooks | OSC 11 Background + `PROMPT_COMMAND` / `precmd` hooks | OSC 11 Background + `PROMPT_COMMAND` / `precmd` hooks |
| | **Bypass** | `touch ~/.zshrc` to skip Zsh newuser-wizard | `touch ~/.zshrc` to skip Zsh newuser-wizard | `touch ~/.zshrc` to skip Zsh newuser-wizard |
| **Standard** | **Identity** | Host User (inherited) | Host User (inherited) | Host User (inherited) |
| | **Isolation** | None (Host mirrored) | None (Host mirrored) | None (Host mirrored) |
| **Airgapped** | **Network** | `dbx-tmp` bridge -> `podman network rm` | `dbx-tmp` bridge -> `podman network rm` | `dbx-tmp` bridge -> `podman network rm` |
| | **Home** | `mount -t tmpfs` eclipse over `/home` | `mount -t tmpfs` eclipse over `/home` | `mount -t tmpfs` eclipse over `/home` |
| **Ghost** | **Identity** | Post-bootstrap `podman exec` → `useradd -m ghostuser` + `sudo` fixes | Post-bootstrap `podman exec` → `useradd -m ghostuser` + `wheel` | Post-bootstrap `podman exec` → `useradd -m ghostuser` + `wheel` |
| | **Access** | `dbx-smith` enters via `--user ghostuser --workdir /home/ghostuser` | `dbx-smith` enters via `--user ghostuser --workdir /home/ghostuser` | `dbx-smith` enters via `--user ghostuser --workdir /home/ghostuser` |
| **Isolated-Net** | **Network** | Dedicated NAT bridge (`dbx-net-<name>`) | Dedicated NAT bridge (`dbx-net-<name>`) | Dedicated NAT bridge (`dbx-net-<name>`) |
| | **Home** | `tmpfs` isolation of `/home` | `tmpfs` isolation of `/home` | `tmpfs` isolation of `/home` |

---

## III. Cross-Distribution Compatibility

DbxSmith is engineered to work across the major Linux families by detecting and targeting their unique configuration paths during the `init-hook` phase.

### 1. Global Profile Injection
To ensure every user (including `ghostuser`) gets the DbxSmith environment, the provisioner iterates through known global config locations:

```bash
# Targeted paths for Bash
/etc/bash.bashrc    # Debian, Ubuntu, Kali, Mint
/etc/bashrc         # Fedora, CentOS, RHEL, Alpine

# Targeted paths for Zsh
/etc/zsh/zshrc      # Debian, Ubuntu
/etc/zshrc          # Fedora, RHEL, Arch, Alpine
```

### 2. Bypassing the "New User" Wizard
Many distributions (especially those using Zsh) trigger an interactive configuration wizard if a user enters a shell without an existing `.zshrc`. This blocks the `distrobox enter` process.

**Engineering Solution:**
DbxSmith automatically `touch`es empty `.zshrc` and `.bashrc` files for all users in `/home/*` during the provisioning phase. This satisfies the shell's existence check and allows for a non-interactive, frictionless entry.

---

## IV. The Ghost Identity Engine

For strategies involving the `ghost` identity, DbxSmith performs the following steps inside the container before the user session begins:

1.  **Identity Creation**: Moved to a post-bootstrap `podman exec` phase. Checks for `ghostuser` existence; if missing, runs `useradd -m ghostuser` and normalizes sudo ownership across `/etc/sudoers.d` to bypass user namespace limitations.
2.  **Privilege Escalation**: Automatically adds `ghostuser` to both `sudo` (Debian/Ubuntu) and `wheel` (Fedora/RHEL/Alpine) groups. DbxSmith also injects a `NOPASSWD` entry into `/etc/sudoers.d/dbx-smith-ghost` to allow frictionless administration inside the sandbox.
3.  **Home Visibility**: Distrobox typically mounts the host home directory for compatibility. However, because the `ghostuser` UID (1001) differs from the host UID (1000), access to `/home/<host_user>` is denied by the Linux kernel, achieving "identity-based" isolation.
4.  **Runtime Mapping**: The host `dbx-smith` command detects the `ghost` strategy from the registry and automatically appends `--additional-flags "--user ghostuser --workdir /home/ghostuser"` to the `distrobox enter` command.

---

## V. Technical Breakdown by Distro Family

| Step | Debian / Ubuntu | Fedora / RHEL / Arch | Alpine |
| :--- | :--- | :--- | :--- |
| **Bash Config** | `/etc/bash.bashrc` | `/etc/bashrc` | `/etc/bashrc` |
| **Zsh Config** | `/etc/zsh/zshrc` | `/etc/zshrc` | `/etc/zshrc` |
| **Sudo Group** | `sudo` | `wheel` | `wheel` |
| **Init Hook Shell** | `/bin/sh` (Dash) | `/bin/sh` (Bash) | `/bin/sh` (Busybox) |
| **Base Tools** | `apt-get` | `dnf` / `pacman` | `apk` |

---

## VI. Terminal Compatibility & Limitations

While the shell hooks for `PS1` and `PROMPT` are universal across all standard terminal emulators, the dynamic background color feature relies on the **OSC 11** escape sequence. 

### 1. The OSC 11 Bottleneck
Not all terminal emulators implement the `OSC 11` specification. If you see the Cyan prompt prefix but the background remains unchanged, your terminal emulator is likely ignoring the sequence.

| Compatibility | Terminal Emulators |
| :--- | :--- |
| **Full Support** | Kitty, Alacritty, XFCE Terminal, VS Code Terminal, WezTerm, iTerm2 |
| **Conditional** | GNOME Terminal (Requires "Allow terminal applications to change colors" in profile settings) |
| **Limited / None** | QTerminal (Default in some Kali installs), old versions of Konsole, `tmux` (Requires explicit wrapping) |

### 2. Troubleshooting the "Static Background"
If your background does not change when entering a box:
1.  **Test the Sequence**: Run `printf '\033]11;#ff0000\007'` on your host. If the terminal does not turn red, it does not support `OSC 11`.
2.  **Check Tmux**: If running inside `tmux`, sequences are blocked by default. DbxSmith currently targets raw terminal sessions.
3.  **Switch Emulators**: For the full DbxSmith experience, we recommend using **Kitty** or **XFCE Terminal** on Kali Linux.

> [!TIP]
> On Kali Linux, you can quickly install a compatible terminal via:
> `sudo apt install kitty xfce4-terminal`
