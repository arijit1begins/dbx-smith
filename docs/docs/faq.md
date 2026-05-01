---
sidebar_position: 5
---

# Frequently Asked Questions (FAQ)

This section covers everything from getting started with DbxSmith to deep architectural questions and edge cases regarding how we isolate your environments.

## General Questions

### What is DbxSmith, and why do I need it over vanilla Distrobox?
Out of the box, Distrobox creates containers that share your host's home directory and network. While convenient, this carries real risk: a malicious script inside the container can delete your host files (`~/.ssh`, source code, etc.) or scan your local network. 
DbxSmith adds a **Strategic Provisioning Layer** on top. It gives you true filesystem isolation, dedicated network bridges, visual terminal identity, and a stateful registry to securely manage your development sandboxes.

### Which strategy should I choose?
- Use **`standard`** for your daily driver where you *want* full access to your host's files and network (e.g., normal Node.js/Python development).
- Use **`airgapped`** if you are testing untrusted scripts, malware, or managing private keys and need a guarantee of zero internet access.
- Use **`isolated-net`** if you are building microservices and need a dedicated local IP or want to avoid port clashing with host services.
- Use **`ghost`** (or its hybrid variants) if you need to test permission-sensitive installers and need a completely clean-slate, ephemeral user identity.

### Does DbxSmith work on macOS or Windows?
**No.** DbxSmith is built exclusively for the Linux ecosystem. It relies heavily on low-level Linux kernel features (namespaces, cgroups) exposed by Podman and Distrobox. While you *can* run DbxSmith inside a Linux VM on macOS or Windows, native host-integration features will be limited strictly to the VM environment.

### I accidentally deleted my box using `distrobox rm` instead of `dbx-smith-rm`. Is that bad?
It is not catastrophic, but it leaves "orphaned" artifacts on your system. DbxSmith creates isolated home directories, network bridges, shell aliases, and registry manifests. `distrobox rm` only deletes the container itself. 
To clean up the remaining artifacts, simply run `dbx-smith-rm <box_name>`—the destructor is smart enough to clean up the missing pieces even if the container is already gone!

### Why do my terminal background colors change when I enter a box?
This is a security and productivity feature called **Visual Determinism**. DbxSmith generates a specific, permanent background color based on the hash of the container image you used. This ensures you always have a visual cue that you are inside a container, preventing you from accidentally running destructive commands on your host system.

---

## Troubleshooting & Common Quirks

### I cleared my terminal, but the background color didn't reset. How does color persistence work?
Initially, terminal background colors were set using a one-time OSC 11 command. However, commands like `clear` or `reset` would strip the color. DbxSmith now permanently embeds the OSC 11 escape sequence directly into your shell's `PS1` (Bash) or `PROMPT` (Zsh). This guarantees that the background is forcefully repainted on every single command prompt.

### Why do I see gibberish like `\033]11;...` printed in my prompt instead of colors?
If you see literal escape codes, it means your shell is refusing to evaluate raw octal ANSI sequences. 
DbxSmith uses **ANSI C Quoting** (`$'\e...'`) for Zsh prompts to force the shell to translate `\e` into the true, unprintable "Escape" byte *before* the variable is exported. If you encounter this, ensure your host is running a modern version of Zsh/Bash and that you have fully sourced `~/.config/dbx-smith/dbx-smith.sh`.

### Why didn't Zsh show the "New User Configuration Wizard" when I created a Ghost box?
When a new Linux user (like `ghostuser`) logs into Zsh for the first time without a `~/.zshrc` file, Zsh halts and displays a massive interactive configuration wizard, freezing automated pipelines. 
DbxSmith bypasses this by automatically bootstrapping empty `.zshrc` and `.bashrc` files and `chown`ing them to `ghostuser` during the `init-hooks` phase, guaranteeing a frictionless entry.

### Why does the creation output tell me to run `dbx-smith <name>` instead of `distrobox enter`?
While Distrobox is the underlying engine, running `distrobox enter` directly bypasses the DbxSmith strategy layer. 
The `dbx-smith` command reads the stateful registry (`~/.config/dbx-smith/registry/`) to determine *how* to enter the box. For example, if you provisioned a `ghost` box, running `dbx-smith` automatically injects the `--user ghostuser` flag so you enter securely. Bypassing the wrapper means you lose identity obfuscation and automatic terminal color resets.

---

## Isolation & Filesystem Mechanics

### Where does the `tmpfs` RAM disk live? Does it affect my host?

The `tmpfs` RAM disk is created **entirely inside the container's isolated mount namespace**. 
When you spin a box, DbxSmith injects `mount -t tmpfs tmpfs /home` as an `init-hook` that runs right before the container starts. This places a RAM disk over the `/home` directory *from the perspective of the container*. Your actual host system remains completely untouched and safe. We are simply putting a "blindfold" over the container's eyes so it cannot see the host's files that Distrobox mapped into it.

### Distrobox hardcodes the host's `/home` mount. How do you remove it without crashing Distrobox?

**We don't remove it; we "eclipse" it.**
Distrobox relies heavily on the `/home` path existing during its internal bootstrapping. Forcibly running `umount /home` inside an init-hook usually results in permissions errors or container crashes. 

Instead, we use a Linux concept called **Over-mounting**. When you mount an empty `tmpfs` RAM disk directly *on top* of `/home`, the host's files still technically exist underneath, but they become 100% inaccessible to any user or process inside the container. We bypass the hardcoded volume mapping perfectly without fighting the container's lifecycle.

### Does `tmpfs` have any performance benefits?

**Yes! Massive benefits for ephemeral testing.**
Because `tmpfs` is a RAM-backed filesystem, read/write operations inside it are blazingly fast compared to standard physical disk I/O. 
For **Ghost Hybrid** strategies, the entire `/home/ghostuser` directory lives exclusively in RAM. This means any caches, temporary files, or configurations written by tools during your testing session happen at RAM speed, cause zero wear to your physical SSD, and are instantly cleaned up the moment the container halts.

### If `/home` is in RAM, where does my code go? Do you still create `~/boxes/<name>`?

It depends entirely on the strategy you choose:

- **Persistent Strategies (`airgapped`, `isolated-net`)**: **Yes**. These are designed for real development. After eclipsing `/home` with RAM, DbxSmith explicitly binds `~/boxes/<name>` (which is on your physical disk) *back* into the RAM disk. Your project files survive reboots, but the host's `~/.ssh` and `.bash_history` remain securely hidden in the RAM void.
- **Ephemeral Strategies (`ghost-airgapped`, `ghost-isolated-net`)**: **No**. The `ghostuser` is designed to leave zero trace on the host. Everything happens inside the `tmpfs` RAM disk. When the box stops, the RAM evaporates and your host's filesystem is completely unaffected.

## Terminal & UI Behaviors

### Why did you have to use ANSI C Quoting (`$'\e'`) for Zsh Prompts?

If you try to embed the literal string `\033` (the octal escape code for ASCII ESC) into a Zsh `PROMPT` using standard double quotes (`""`), Zsh will literally print the text `\033` instead of rendering a color. Bash (`PS1`), on the other hand, understands `\033` naturally. 

To achieve cross-shell theme integrity, DbxSmith uses **ANSI C Quoting** (`$'\e...'`). This forces both Zsh and Bash to translate the `\e` into the true, unprintable "Escape" byte *before* the variable is exported into the container's `/etc/profile.d/dbx-smith-env.sh`, ensuring it renders flawlessly on every startup.

### The default Zsh prompt ends with `%`, but DbxSmith ends with `$`. Why?

You might notice that natively, a normal user's Zsh prompt ends with `%` (e.g., `user@host%`), while Bash ends with `$`. However, many users (especially those coming from Kali Linux or long-time Bash users) prefer the familiar `$`. 

Because DbxSmith isolated containers do not load your host's customized `~/.zshrc`, the container's Zsh defaults to `%`. To provide a seamless and familiar experience, DbxSmith injects `%(!.#.$)` into the Zsh `PROMPT`. This dynamic marker tells Zsh to print `#` if you escalate to root, and `$` for a normal user, standardizing the aesthetic across all your boxes.

## Lifecycle Management

### Can I delete multiple boxes at once?

**Yes.** The `dbx-smith-rm` tool supports atomic bulk deletion. You can pass as many box names as you like:
```bash
dbx-smith-rm box1 box2 box3 --purge
```
Because DbxSmith parses the stateful registry located at `~/.config/dbx-smith/registry/`, it knows exactly what networks, alias fragments, and isolated home directories belong to each box, ensuring it completely wipes every trace of the targets securely in a single pass.
