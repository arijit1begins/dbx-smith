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

### Unified Pipeline
Our CI/CD orchestration is consolidated into `.github/workflows/pipeline.yml`, ensuring a streamlined and predictable release flow:
- **CI Job (Continuous Integration)**: 
  - Runs **ShellCheck** on all binaries and core scripts.
  - Executes **`test_strategies.sh`**, validating all isolation strategies in real containers.
  - Triggered on every Push and Pull Request to `main`.
- **Release Job (GitHub Release)**:
  - Triggered **ONLY** on pushed Git tags (e.g., `v1.2.3`).
  - Uses `semantic-release` (UI only) to generate professional release notes and upload binary assets.
- **Docs Job (Documentation)**:
  - Runs after a successful release to build and deploy the Docusaurus site to GitHub Pages.

### Local-First Release Strategy
We follow a **Local-First, Tag-Driven Release Strategy**. GitHub Actions **NEVER** commits back to the repository. All versioning and changelog updates are managed by the author locally.

#### Releasing a New Version:
1. Ensure you are on the `main` branch with a clean working directory.
2. Run the local release script:
   ```bash
   ./release.sh
   ```
3. This script will:
   - Calculate the next SemVer version.
   - Update `CHANGELOG.md` and `package.json`.
   - Update the version string in `bin/dbx-smith-spin`.
   - Create a local commit and a signed Git tag.
4. Push the changes and tags: `git push origin main --tags`.

### Troubleshooting CI/CD
- **ShellCheck Warnings**: The CI will fail if ShellCheck finds issues. Run `shellcheck bin/* src/*.sh` locally before pushing.

### Testing Locally
Before submitting a PR, please run the following:
1. **Linting**: `shellcheck bin/* src/*.sh`
2. **Strategy Tests**: `./test_strategies.sh` (Requires `podman` and `distrobox` installed on your host).
3. **Docs Build**: `cd docs && npm run build`

## Questions?
Feel free to open a Discussion on GitHub!

⚒️ Happy Forging!
