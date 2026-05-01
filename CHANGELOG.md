# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [1.3.0] (2026-05-01)

### Features

* **core:** implement **True Tmpfs Home Isolation** (The Eclipse Hack) to bypass hardcoded Distrobox bind mounts for maximum security.
* **core:** introduce **Hybrid Ghost Strategies** (`ghost-airgapped`, `ghost-isolated-net`) for transient identity obfuscation in airgapped environments.
* **cli:** refactor `dbx-smith-rm` to support **Atomic Bulk Deletions** of multiple boxes and their associated infrastructure in a single command.
* **ui:** resolve gibberish ANSI escape rendering in Zsh via **ANSI C Quoting** (`$'\e'`) injection.
* **ui:** enforce standard `$` prompt terminator across Zsh and Bash for familiar developer experience.
* **docs:** create comprehensive **FAQ documentation** covering architectural nuances, performance, and security mechanics.
* **docs:** overhaul **Engineering Deep Dive** and **Architecture** documentation to align with state-of-the-art isolation techniques.
* **test:** implement **Modular Test Matrix Runner** and synchronized CI pipeline for strategy validation.

# [1.2.0](https://github.com/arijit1begins/dbx-smith/compare/v1.1.0...v1.2.0) (2026-04-28)


### Features

* implement man pages for dbx-smith-spin and dbx-smith-rm with updated installation scripts and documentation headers ([971f0eb](https://github.com/arijit1begins/dbx-smith/commit/971f0ebfceb4469326c5ffa30bd289f0ad6e23be))

# [1.1.0](https://github.com/arijit1begins/dbx-smith/compare/v1.0.0...v1.1.0) (2026-04-28)


### Features

* add system dependency checks and switch from git clone to tarball-based release installation ([2aa0923](https://github.com/arijit1begins/dbx-smith/commit/2aa0923f1a66f8268eb8797d143a16a9f857131a))

# 1.0.0 (2026-04-28)


### Bug Fixes

* resolve CI failures and improve script robustness ([c2378ff](https://github.com/arijit1begins/dbx-smith/commit/c2378ffcd86ea123bce085785a7c03133c7c4745))
* sanitize directory removal paths, ensure file truncation compatibility, and force non-interactive container creation ([3256325](https://github.com/arijit1begins/dbx-smith/commit/32563253c19f0cdd55888dbd67907534b79c1042))


### Features

* add interactive zoom, pan, and fullscreen support to Mermaid diagrams using react-zoom-pan-pinch ([d683c39](https://github.com/arijit1begins/dbx-smith/commit/d683c39e03d3ad3cd9add85fdd3c20fc9dd5e9fb))
* add uninstall script and improve installation logic for local repositories ([6c7b531](https://github.com/arijit1begins/dbx-smith/commit/6c7b53186383b33771971ba0190dc15bd7fbbea8))
* automate release pipeline, fix CI failures, and sync versioning ([275357f](https://github.com/arijit1begins/dbx-smith/commit/275357f7f99526dfc66536baae03872a8d9f763c))

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-20

### Added
- **Core Provisioner**: `dbx-smith-spin` with support for `standard`, `airgapped`, `ghost`, and `isolated-net` strategies.
- **Teardown Tool**: `dbx-smith-rm` for atomic environment cleanup.
- **Runtime Core**: `dbx-smith.sh` with Bash/Zsh completion and dynamic alias loading.
- **Registry**: Filesystem-based manifest registry for state management.
- **Documentation**: Professional Docusaurus-based site with technical specs and blog.
- **CI/CD**: GitHub Actions workflows for ShellCheck, Strategy Testing, and Automated Releases.
- **Security**: Bridge-Destruction hack for true airgapped isolation.

### Changed
- Rebranded suite from generic `dbx` to **DbxSmith**.
- Refactored internal configuration path to `~/.config/dbx-smith`.
