# DbxSmith

[![Unified Pipeline](https://github.com/arijit1begins/dbx-smith/actions/workflows/pipeline.yml/badge.svg)](https://github.com/arijit1begins/dbx-smith/actions/workflows/pipeline.yml)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

A professional-grade provisioning and management suite for **<a href="https://distrobox.it/" target="_blank" rel="noopener noreferrer">Distrobox</a>** and **<a href="https://podman.io/" target="_blank" rel="noopener noreferrer">Podman</a>**. Forge isolated developer environments with strategic network control, deterministic UI, and atomic teardowns.

📖 **[Full documentation →](https://arijit1begins.github.io/dbx-smith/docs/intro)**  
📰 **[Read our Blog →](https://arijit1begins.github.io/dbx-smith/blog)**  
📡 **[RSS Feed](https://arijit1begins.github.io/dbx-smith/blog/rss.xml)**

## Compatibility

- **Supported OS**: Linux (Agnostic - Fedora, Ubuntu, Arch, etc.)
- **Unsupported**: macOS, Windows (WSL2 may work but is not officially supported)
- **Dependencies**: Distrobox, Podman (or Docker)

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/arijit1begins/dbx-smith/main/install.sh | bash
```

Or with Make after cloning:

```bash
make install
```

After installation, follow the on-screen instructions to source the runtime in your `~/.bashrc` or `~/.zshrc`.

## Uninstallation

```bash
dbx-smith-uninstall
```
