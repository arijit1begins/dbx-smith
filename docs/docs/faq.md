---
sidebar_position: 5
---

# Frequently Asked Questions (FAQ)

This section covers general usage questions, troubleshooting tips, and high-level isolation mechanics. For low-level system designs, see our [Engineering Deep-Dive](#security--isolation-mechanics) links.

---

## General Questions

### What is DbxSmith, and why do I need it over vanilla Distrobox?
Vanilla Distrobox creates containers that share your host's home directory and network by default, exposing your private host files (`~/.ssh`, source code, history) to potential malware or script errors. DbxSmith adds a **Strategic Provisioning Layer** that automatically injects filesystem over-mounting, custom NAT bridges, deterministic terminal background colors, and stateful registry management.

### Which strategy should I choose?
* Use **`standard`** for daily drivers where you need access to host files and the host network (e.g., standard Python/Node development).
* Use **`airgapped`** if you are testing untrusted scripts or managing sensitive private keys and need a physical guarantee of zero internet.
* Use **`isolated-net`** to run networked microservices without port conflicts.
* Use **`ghost`** or its hybrid variants when you want identity obfuscation (runs as a transient `ghostuser`).

For a detailed side-by-side strategy table, see [Isolation Strategies](./strategies.md).

### Does DbxSmith work on macOS or Windows?
**No.** DbxSmith is built exclusively for the Linux ecosystem. It relies on namespaces and cgroup features exposed natively by Podman and Distrobox on Linux.

### What happens if I delete a box using vanilla `distrobox rm` instead of `dbx-smith-rm`?
It is safe for your host, but it leaves orphaned files behind (such as custom home paths, registry manifests, network bridges, and shell shortcut fragments). To clean these up, simply run `dbx-smith-rm <box_name>`—our destructor is smart enough to find and sweep up orphaned resources even if the container is already gone.

### Why do my terminal background colors change when I enter a box?
This is a core security feature called **Visual Determinism**. DbxSmith hashes the container's base image name to derive a permanent, unique background color (via OSC 11 sequences). This provides a constant visual warning so you never run destructive command scripts in the wrong terminal window.

---

## Troubleshooting & Common Quirks

### I cleared my terminal, but the background color didn't reset. How does color persistence work?
DbxSmith embeds the OSC 11 escape code directly inside your shell's `PS1` (Bash) or `PROMPT` (Zsh) inside the container. This forces the terminal to repaint the color on every command prompt, preventing it from being stripped by `clear` or `reset`. Sourcing the host runtime wrapper ensures the default terminal theme is automatically restored the instant you run `exit`.

### Why do I see raw text like `\033]11;...` printed inside my prompt?
This occurs if your active host terminal or shell config fails to translate raw octal escape sequences. DbxSmith solves this by utilizing **ANSI C Quoting** (`$'\e...'`). Ensure you are using a modern terminal (like Kitty, Alacritty, or XFCE Terminal) and have sourced `~/.config/dbx-smith/dbx-smith.sh` on your host.

### Why didn't Zsh show the "New User Configuration Wizard" inside my Ghost box?
Normally, entering a clean Zsh shell without a `.zshrc` triggers Zsh's interactive setup wizard, freezing headless CI scripts. DbxSmith avoids this by automatically creating and pre-configuring empty `.zshrc` and `.bashrc` files inside the guest's home directory during the provisioning phase.

### Why should I enter via `dbx-smith <name>` instead of `distrobox enter`?
Running `distrobox enter` bypasses the DbxSmith registry wrapper. The `dbx-smith` command reads the registry state to automatically inject critical strategy flags (like `--user ghostuser --workdir /home/ghostuser` for Ghost boxes) and manages terminal background color states on exit.

---

## Security & Isolation Mechanics

### Where does the `tmpfs` RAM disk live? Does it affect my host?
The `tmpfs` RAM disk lives strictly inside the container's isolated mount namespace. It is backed entirely by your system memory and leaves absolutely no physical artifacts on your host system.

### How do you over-mount `/home` without crashing Distrobox?
Distrobox crashes if its mapped volume paths are unmounted. DbxSmith bypasses this using a Linux systems trick called **Over-mounting (The Eclipse Hack)**. By mounting a `tmpfs` RAM disk directly *on top* of the `/home` directory inside the container, we eclipse host visibility perfectly without disturbing Distrobox's initialization hooks. 

For the complete technical breakdown, step-by-step shell commands, and sequence diagrams of the Eclipse Hack, see [Engineering Internals: True Tmpfs Home Isolation](./Engineering/internals.md#4-true-tmpfs-home-isolation-the-eclipse-hack).

### Does `tmpfs` have performance benefits?
**Yes.** Because RAM-backed filesystems bypass disk I/O, file read/writes inside RAM run at memory speed, which is extremely beneficial for compilation caches and temporary tests. It also reduces wear on physical SSDs.

### If `/home` is in RAM, where do my persistent files go?
* **Persistent Strategies (`airgapped`, `isolated-net`)**: After eclipsing the home mount with RAM, DbxSmith bind-mounts your dedicated host-backed folder (`~/boxes/<name>`) back into the empty space. Your code persists on disk, but host dotfiles (like `~/.ssh`) remain hidden.
* **Ephemeral Hybrid Strategies (`ghost-airgapped`, `ghost-isolated-net`)**: The user's home lives entirely in RAM. All files are destroyed the moment the box is stopped, leaving zero trace on the host.

### Why do you modify `/etc/shadow` inside Ghost boxes?
Inside unprivileged user namespaces, unmapped UIDs (like `ghostuser`) suffer severe capability drops, preventing `pam_unix.so` from reading the guest's `/etc/shadow` file. DbxSmith automatically manages permission offsets (`chmod 644 /etc/shadow`) inside the container during bootstrapping to unblock passwordless `sudo` safely. For details, see [Shell Configuration: Ghost Identity Engine](./Engineering/shell_configuration.md#iv-the-ghost-identity-engine).

### Why did my custom multiline hook crash the container during spin?
POSIX interpreters inside base container images (like Arch or Alpine) evaluate escaped newlines literally during creation loop evaluations. To prevent bad mount errors, you must flatten all custom payload scripts into continuous, single-line strings. For details, see [Engineering Internals: Base64 Tunnelling](./Engineering/internals.md#1-zero-escape-payload-injection-base64-tunnelling).
