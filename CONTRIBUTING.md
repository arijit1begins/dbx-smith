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

### CI/CD Workflows
Our workflows are located in `.github/workflows/` and ensure code quality and automated delivery:
- **`ci.yml` (Continuous Integration)**: 
  - Runs **ShellCheck** on all binaries and core scripts.
  - Executes **`test_strategies.sh`**, which spins up real containers to validate all isolation strategies (`standard`, `airgapped`, etc.).
  - Triggered on every Push and Pull Request.
- **`deploy-docs.yml` (Documentation Deployment)**:
  - Triggered by changes in the `/docs` directory.
  - Automatically builds the Docusaurus site and deploys it to GitHub Pages.
- **`release.yml` (Automated Release)**:
  - Triggered on every push to the `main` branch.
  - Uses `semantic-release` to analyze commits, generate changelogs, and publish new GitHub Releases.

### Commit Guidelines & Release Triggers
Since we use automated versioning, your commit prefix determines if a new version is released:
- **Triggers a Release**: `feat:` (Minor), `fix:` (Patch), `BREAKING CHANGE:` (Major).
- **Does NOT Trigger a Release**: `docs:`, `chore:`, `ci:`, `style:`, `refactor:`, `test:`.

> [!IMPORTANT]
> If you are modifying internal CI/CD YAML files or scripts that don't affect the end-user, please use the `ci:` or `chore:` prefix. Avoid using `fix:` for infrastructure changes unless they fix a bug in the shipped software itself.

### Testing Locally
Before submitting a PR, please run the following:
1. **Linting**: `shellcheck bin/* src/*.sh`
2. **Strategy Tests**: `./test_strategies.sh` (Requires `podman` and `distrobox` installed on your host).
## Questions?
Feel free to open a Discussion on GitHub!

⚒️ Happy Forging!
