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
3. If you've added code that should be tested, add or update tests in the `tests/` directory and ensure `./test.sh --full` passes.
4. Ensure your code passes linting: `shellcheck bin/* src/**/*.sh`.
5. Submit a Pull Request.

### 4. Modular Architecture & Patterns
DbxSmith follows a modular, "OOP-inspired" architecture to prevent regressions and ensure scalability:

- **Factory Pattern**: Strategies are isolated in `src/strategies/`. To add a new strategy, create a new file and implement the `get_flags` and `finalize` functions.
- **Dependency Injection**: Distribution-specific configurations are located in `src/distros/`. These are injected into the core logic based on the image name.
- **Core Modules**: Common utilities and payload generation are centralized in `src/core/`.

#### Adding a New Strategy:
1. Create `src/strategies/my-strategy.sh`.
2. Implement `strategy_my_strategy_get_flags()` and `strategy_my_strategy_finalize()`.
3. Register the strategy in the `usage()` function of `bin/dbx-smith-spin`.

#### Adding a New Distro Config:
1. Create `src/distros/my-distro.sh`.
2. Define `DISTRO_PKGMGR`, `DISTRO_PKG_SU`, etc.
3. Update `src/core/distro_factory.sh` to recognize your distro's image patterns.


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
  - Executes **`./test.sh --full`**, validating all isolation strategies across a matrix of containers.
  - **Conditional Logic**: Skips the branch push if the commit message contains `[skip branch ci]`. This avoids redundant runs when a Tag is pushed simultaneously.
  - Triggered on PRs, Tags, and non-release pushes to `main`.
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
   - Update the version string in `src/core/constants.sh`.
   - Create a local commit with `[skip branch ci]` and a signed Git tag.
4. Push the changes and tags: `git push origin main --tags`.

### Troubleshooting CI/CD
- **ShellCheck Warnings**: The CI will fail if ShellCheck finds issues. Run `shellcheck bin/* src/*.sh` locally before pushing.

### Hacking the TUI Dashboard

The DbxSmith dashboard (`bin/dbx-smith-dash`) is a pure Bash TUI. If you want to contribute to the UI, keep these architectural principles in mind:

### 1. The Rendering Engine
We do NOT use `clear` or `reset`. All drawing is done via `draw_dashboard` which:
- Uses `tput cup row col` to place the cursor.
- Overwrites lines completely to avoid trailing characters.
- Uses the Alternate Screen Buffer (`smcup`/`rmcup`) to preserve the user's terminal state.

### 2. State Management
All UI state is stored in global variables (e.g., `SELECTED_INDEX`, `TASK_ACTIVE`, `BOX_NAMES`). The `fetch_data` function should be called sparingly (only when container states actually change) to keep the UI snappy.

### 3. Asynchronous Tasks
If you are adding a new long-running command:
- Run it in the background: `cmd > "$log_pipe" 2>&1 &`.
- Use `TASK_PID=$!` to track it.
- Implement a polling loop in the UI that reads from the FIFO with a short timeout (`read -t 0.05`).
- Use `TASK_PROGRESS` and `TASK_LOGS` to update the overlay.

### 4. Testing
Always test TUI changes in multiple terminal sizes. Use `bash -x bin/dbx-smith-dash` for debugging, though note that it will heavily corrupt the TUI output—redirecting `xtrace` to a file is recommended.

### Testing Locally
Before submitting a PR, please run the following:
1. **Linting**: `shellcheck bin/* src/**/*.sh`
2. **Strategy Tests**: `./test.sh --full`
   - This executes the entire multi-distribution matrix (Alpine, Arch, Fedora, Ubuntu) across all 6 strategies.
   - **Important**: Because distributions like Arch Linux enforce extremely strict POSIX shell evaluation during bootstrap, ensure that any new shell hooks you inject are formatted as **continuous single-line strings** without escaped newlines (`\`).
   - Requires `podman` and `distrobox` installed on your host.
3. **Docs Build**: `cd docs && npm run build`

### 6. Capturing Professional Terminal Visuals

To maintain a high-fidelity and authentic look, DbxSmith documentation avoids idealized AI-generated mockups in favor of **Real Terminal Captures**. We use a pipeline that renders actual terminal output into a styled HTML frame, which is then captured as a clean `.png`.

#### How to Capture:
1.  **Generate Mockup**: Use the provided automation script to run a command and generate the HTML frame:
    ```bash
    ./docs/scripts/capture_terminal.sh "distrobox list" "Container List" "docs/static/img/my_capture.html"
    ```
2.  **Screenshot**: 
    - Open the generated `.html` file in your browser.
    - Use a screenshot tool (like `scrot`, `maim`, or your browser's Developer Tools) to capture the terminal window.
    - Save the resulting image to `docs/static/img/`.
3.  **Embed**: Use relative paths in your Markdown: `![Description](/img/my_capture.png)`.

This ensures that the documentation always reflects the **real** IDs, status messages, and formatting of the current DbxSmith version while looking crisp and professional.

## Questions?
Feel free to open a Discussion on GitHub!

⚒️ Happy Forging!
