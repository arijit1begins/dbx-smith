# DbxSmith

[![DbxSmith CI](https://github.com/arijit1begins/dbx-smith/actions/workflows/ci.yml/badge.svg)](https://github.com/arijit1begins/dbx-smith/actions/workflows/ci.yml)
[![Release](https://github.com/arijit1begins/dbx-smith/actions/workflows/release.yml/badge.svg)](https://github.com/arijit1begins/dbx-smith/actions/workflows/release.yml)
[![Deploy Docusaurus](https://github.com/arijit1begins/dbx-smith/actions/workflows/deploy-docs.yml/badge.svg)](https://github.com/arijit1begins/dbx-smith/actions/workflows/deploy-docs.yml)
![License](https://img.shields.io/badge/license-Apache_2.0-green?style=flat-square)

A professional-grade provisioning and management suite for **<a href="https://distrobox.it/" target="_blank" rel="noopener noreferrer">Distrobox</a>** and **<a href="https://podman.io/" target="_blank" rel="noopener noreferrer">Podman</a>**. Forge isolated developer environments with strategic network control, deterministic UI, and atomic teardowns.

📖 **[Full documentation →](docs/docs/intro.mdx)**

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
