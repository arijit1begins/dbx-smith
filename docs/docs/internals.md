---
sidebar_position: 4
---

# Engineering Internals

This document is for developers contributing to or extending DbxSmith. It covers repository structure, the reasoning behind key engineering decisions, and detailed lifecycle diagrams for the runtime entry and teardown phases.

---

## I. Repository Structure

| Path | Category | Description |
| :--- | :--- | :--- |
| `install.sh` | **Entrypoint** | Quick-start installer and shell injector. |
| `bin/` | **Executables** | CLI tools: `dbx-smith-spin`, `dbx-smith-rm`, and `dbx-smith-uninstall`. |
| `src/` | **Runtime** | `dbx-smith.sh` — shell-integrated core logic, completions, alias loader. |
| `internal/` | **Metadata** | Design docs and templates (not shipped to users). |
| `docs/` | **Docs Site** | Docusaurus source for the public documentation. |
| `Makefile` | **Distributor** | Deterministic mapping of files to host paths. |

### Distribution paths (Makefile)

| Layer | Path | Content |
| :--- | :--- | :--- |
| **Execution** | `~/.local/bin/` | `dbx-smith-spin`, `dbx-smith-rm`, `dbx-smith-uninstall` |
| **Persistence** | `~/.config/dbx-smith/` | `dbx-smith.sh`, `registry/`, `aliases.d/` |
| **Shell** | `~/.bashrc` or `~/.zshrc` | `source ~/.config/dbx-smith/dbx-smith.sh` |

---

## II. Engineering Principles

### 1. Idempotency — The Self-Healing Pattern

Every script is safe to re-run. Existence checks before `mkdir`, `|| true` guards on network ops, and `command -v` checks before installing prevent duplication on partial failures.

### 2. Loose Coupling — The Fallback Pattern

The runtime (`dbx-smith.sh`) is loosely coupled with the registry. If the registry is deleted, it falls back to inspecting `/etc/passwd` inside the container for `ghostuser`. Tools should degrade gracefully, not crash.

### 3. Visual Determinism — Deterministic UI

Terminal colors are derived from the image name via `cksum`, not randomly assigned. The same image always produces the same color — a security feature that prevents running commands in the wrong terminal window.

---

## III. The Entrypoint: `install.sh`

```mermaid
%%{init: {"themeVariables": {"fontSize": "16px"}}}%%
graph TD
    Start([Start install.sh]) --> Env[Detect PREFIX and CONFIG_DIR]
    Env --> Make[Invoke make install]
    Make --> Bin[Install bin/* to ~/.local/bin]
    Make --> Config[Install src/* to ~/.config/dbx-smith]
    Config --> ShellDetect{Detect Shell Type}
    ShellDetect --> |Zsh| Zsh[Select ~/.zshrc]
    ShellDetect --> |Bash| Bash[Select ~/.bashrc]
    ShellDetect --> |Unknown| Manual[Print Manual Source Instructions]
    Zsh --> Check{Source line present?}
    Bash --> Check
    Check --> |Yes| End([Finish])
    Check --> |No| Prompt[Prompt user for injection]
    Prompt --> |Accept| Append[Append source line to RC file]
    Prompt --> |Reject| Manual
    Append --> End
```

---

## IV. Runtime Entry Lifecycle (`dbx-smith`)

What happens every time you run `dbx-smith <box>` after provisioning.

```mermaid
%%{init: {"themeVariables": {"fontSize": "16px"}}}%%
sequenceDiagram
    participant S as Host Shell
    participant R as dbx-smith runtime
    participant C as Registry
    participant D as Distrobox
    participant B as Box Environment

    note over S,B: Shell startup (once per session)
    S->>R: 1. source dbx-smith.sh
    R->>R: 2. Source aliases.d/*.sh fragments
    R->>S: 3. Register dbx-smith function + tab completion

    note over S,B: User enters a box
    S->>R: 4. dbx-smith [box]
    R->>D: 5. Validate box exists (distrobox list)
    R->>C: 6. Read registry STRATEGY field
    C-->>R: 7. Return strategy (e.g. ghost)
    R->>D: 8. distrobox enter [--user ghostuser] [box]
    D->>B: 9. Attach to container, execute /etc/profile.d/dbx-smith-env.sh
    B-->>S: 10. Interactive shell session

    note over S,B: User exits
    S->>B: 11. exit
    B-->>R: 12. Return control to runtime
    R->>S: 13. Reset terminal background (OSC 11 to #000000)
```

---

## V. Destruction Lifecycle (`dbx-smith-rm`)

```mermaid
%%{init: {"themeVariables": {"fontSize": "16px"}}}%%
graph TD
    Start([dbx-smith-rm target]) --> Parse[Parse flags: --purge and target name]
    Parse --> Exist{Box exists?}
    Exist --> |Yes| Stop[distrobox stop --yes]
    Exist --> |No| CleanupFS[Cleanup registry and aliases]
    Stop --> Remove[distrobox rm --yes]
    Remove --> CleanupFS
    CleanupFS --> Home{~/boxes/target exists?}
    Home --> |Yes| DelHome[rm -rf ~/boxes/target]
    Home --> |No| Net{dbx-net-target exists?}
    DelHome --> Net
    Net --> |Yes| DelNet[podman network rm dbx-net-target]
    Net --> |No| Purge{--purge flag?}
    DelNet --> Purge
    Purge --> |Yes| DelVol[podman volume rm target_home]
    Purge --> |No| End([Teardown complete])
    DelVol --> End
```

---

## VI. Advanced Engineering Details

### 1. Zero-Escape Payload Injection (Base64 Tunnelling)

Passing complex scripts into `distrobox create --init-hooks` causes double shell evaluation — the host shell consumes `>>`, `$`, and `"` before they reach the container.

**Solution:** Encode the entire script as Base64 on the host. The host sees only alphanumeric characters. The container decodes and executes it fresh.

```bash
payload=$(printf "%s" "$script_content" | base64 | tr -d '\n')
hook="echo '$payload' | base64 -d | sh"
distrobox create --init-hooks "$hook" ...
```

### 2. The Two-Phase Airgap

Distrobox's first-run initializer needs internet access to install `sudo` and `mount` inside the guest. A container created with `--network none` immediately fails this step.

**Solution:** Provision with a throwaway network, bootstrap, then destroy it permanently.

```bash
podman network create dbx-tmp-<name>
distrobox create --additional-flags "--network dbx-tmp-<name>" ...
distrobox enter <name> -- true          # triggers first-run
podman network disconnect dbx-tmp-<name> <name>
podman network rm dbx-tmp-<name>        # bridge permanently deleted
```

Isolation is **event-driven** (process completion), not time-based.

### 3. Exact-Match Container Validation

Simple `grep "test"` on `distrobox list` matches `test-vault`, `test-old`, etc. — false positives that cause accidental deletions.

**Solution:** Use `awk` with field-level equality on column 3 (the NAME column):

```bash
distrobox list --no-color | awk -v name="$name" 'NR>1 && $3==name {found=1} END {exit !found}'
```

Used in `spin` (duplicate guard), `runtime` (existence check), and `rm` (target validation).
