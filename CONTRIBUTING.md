# Contributing to DbxSmith

First off, thank you for considering contributing to **DbxSmith**! It's people like you that make DbxSmith a professional-grade tool for the entire community.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. (TL;DR: Be excellent to each other).

## How Can I Contribute?

### 1. Reporting Bugs
- Check the [Issues](https://github.com/arijit1begins/dbx-smith/issues) to see if the bug has already been reported.
- If not, open a new issue. Include steps to reproduce, your OS, and <a href="https://distrobox.it/" target="_blank" rel="noopener noreferrer">Distrobox</a>/<a href="https://podman.io/" target="_blank" rel="noopener noreferrer">Podman</a> versions.

### 2. Suggesting Enhancements
- Open an issue with the "enhancement" label.
- Describe the feature and why it would be useful.

### 3. Contributing Code
1. Fork the repo and create your branch from `main`.
2. Install dependencies: `make install`.
3. If you've added code that should be tested, add or update tests in `test_strategies.sh`.
4. Ensure your code passes linting: `shellcheck bin/* src/*.sh`.
5. Submit a Pull Request.

### 4. Contributing to Documentation
The documentation is built with **Docusaurus** and located in the `/docs` directory.
- **Local Preview**:
  ```bash
  cd docs
  npm install
  npm start
  ```
- **Adding Docs**: Add `.md` or `.mdx` files to `docs/docs/`.
- **Updating Sidebar**: Modify `docs/sidebars.ts` if you add new categories.

### 5. Contributing to the Blog
We love hearing about how you use DbxSmith!
- Add your post to `docs/blog/` following the `YYYY-MM-DD-title.md` format.
- Add yourself to `docs/blog/authors.yml` if you haven't already.
- Use `{/* truncate */}` in your markdown to define the post summary.

## Style Guide

### Commit Messages
We use **Semantic Release**. Please follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
- `feat:` A new feature.
- `fix:` A bug fix.
- `docs:` Documentation only changes.
- `style:` Changes that do not affect the meaning of the code.
- `refactor:` A code change that neither fixes a bug nor adds a feature.
- `test:` Adding missing tests or correcting existing tests.
- `chore:` Changes to the build process or auxiliary tools.

### Shell Scripting
- Use `#!/usr/bin/env bash`.
- Use `set -euo pipefail` for robustness.
- Quote your variables: `"$VARIABLE"`.
- Use `$(...)` instead of backticks for command substitution.

## DevOps & Release Engineering

### Version Management
We use **Semantic Versioning (SemVer)**. Versioning is automated using `semantic-release`.
- **Commits**: Follow the [Conventional Commits](https://www.conventionalcommits.org/) format. 
- **Trigger**: Every push to `main` triggers a release analysis.
- **Artifacts**: New tags and GitHub Releases are created automatically with generated changelogs.

### CI/CD Pipeline
Our workflows are located in `.github/workflows/`:
- **`ci.yml`**: Runs `shellcheck` and the `test_strategies.sh` suite on every PR.
- **`deploy-docs.yml`**: Automatically builds and deploys the Docusaurus site to GitHub Pages.
- **`release.yml`**: Handles the automated release process.

### Packaging & Installation
- **Make**: The `Makefile` is the source of truth for installation paths.
- **Installer**: `install.sh` is a standalone script that downloads the core files and sets up the environment.
- **Prerequisites**: The suite checks for `distrobox` and `podman` at runtime and installation.

## Questions?
Feel free to open a Discussion on GitHub!

⚒️ Happy Forging!
