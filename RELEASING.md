# Releasing DbxSmith

This project follows a **Local-First, Tag-Driven Release Strategy**. 

## Core Philosophy
1. **Author-Led**: Version bumps, changelog updates, and tagging happen on the author's local machine.
2. **Zero-Commit CI**: GitHub Actions **never** pushes commits to the repository. It only reacts to tags.
3. **Transparency**: The local `release.sh` script makes all changes visible to the author before they are pushed to the remote.

## Prerequisites
- `npm` and `npx` installed.
- Permissions to push to `main` and push tags.
- A clean working directory on the `main` branch.

## Release Steps

### 1. Run the Release Script
Execute the automation script from the root of the repository:
```bash
./release.sh
```

### 2. Verification
The script will perform the following:
- Analyze commits since the last tag.
- Bump the version in `package.json`.
- Update `CHANGELOG.md`.
- Synchronize the version string in `src/core/constants.sh`.
- Create a local commit: `chore(release): X.Y.Z [skip branch ci]`.
- Create a local Git tag: `vX.Y.Z`.

### 3. Push to Remote
When prompted, confirm the push. This will execute:
```bash
git push origin main --tags
```

### 4. The "Surgical Skip" Logic
The release commit uses the `[skip branch ci]` flag. 
- **What it does**: It prevents the `Continuous Integration` job from running on the `main` branch push.
- **Why?**: Since you are pushing both a commit and a tag, standard CI would run twice on the same code. By using `[skip branch ci]`, we skip the redundant branch test but **still allow the Tag trigger** to run the full release pipeline.

## Post-Push Automation
Once changes or tags are pushed to the remote repository, the **Unified Pipeline** (`pipeline.yml`) orchestrates validation and deployment with high efficiency and safety:

1. **Path-Based Optimization**: The pipeline uses a fast `detect` job to inspect modified files. 
   - **Ad-hoc Doc Pushes**: On documentation-only commits pushed to `main`, the slow container strategy tests (`ci` job) are **skipped entirely**. The pipeline immediately proceeds to the `docs` job, compiling and deploying the website in under 2 minutes (building it exactly once!).
   - **Code & Docs Pushes**: If both code and docs are modified, the pipeline runs the full container integration test suite first. The documentation will **only** deploy if the tests succeed, providing absolute safety against failed rollbacks.
2. **GitHub Release**: Triggered exclusively by Git tags (e.g. `vX.Y.Z`). It runs `softprops/action-gh-release` to generate automatic release notes from conventional commits, and uploads the production bundle (`.tar.gz`) and quick installer (`install.sh`) as release assets.
3. **Documentation Deployment**: Builds the Docusaurus website and deploys it to GitHub Pages sequentially, ensuring the live docs match the latest release state.

### Pipeline Decision & Execution Matrix
The pipeline dynamically adjusts its execution path based on the type of files modified, maximizing speed while maintaining strict release stability:

| Commit / Trigger Type | Path Outputs | `ci` Job Status | `docs` Deployment | Deployment Mode | Why? |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Doc-Only Push** (to `main`) | `docs: true`, `code: false` | **Skipped** | **Deploys immediately** | Fast Path (~2 mins) | Only documentation was modified. Bypasses container testing. |
| **Code-Only Push** (to `main`) | `docs: false`, `code: true` | **Runs** | **Skipped** | No Deploy | Only code changed. No new doc updates to publish. |
| **Code & Docs Push (CI Passes)** | `docs: true`, `code: true` | **Runs** | **Deploys** | Synchronous | Code is stable and documentation is updated sequentially. |
| **Code & Docs Push (CI Fails)** | `docs: true`, `code: true` | **Runs** | **Blocked & Skipped** | Blocked | **Safety Guard**: Prevents publishing docs for broken code. |
| **Workflow-Only Push** (to `main`) | `docs: true`, `code: false` | **Skipped** | **Deploys immediately** | Fast Path (~2 mins) | Verifies pipeline execution and doc build instantly. |
| **Pull Request** (to `main`) | Variable | **Runs** (if `code: true`) | **Skipped** | PR Validation | Validates code stability. Deploys only occur on merge/tag. |
| **Git Tag Push** (`v*.*.*`) | N/A (Tag trigger) | **Runs** | **Deploys** | Release Deploy | Builds and publishes production bundle and matching docs. |

## Branch Protection Rules
The `main` branch should be protected with the following rules:
- **Restrict Pushes**: Only authorized roles can push.
- **Require Status Checks**: The `Continuous Integration` job must pass before code can be merged.
- **No Bypass**: No bypass is needed for workflows since they do not commit code.
