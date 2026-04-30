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
- Synchronize the version string in `bin/dbx-smith-spin`.
- Create a local commit: `chore(release): X.Y.Z [skip ci]`.
- Create a local Git tag: `vX.Y.Z`.

### 3. Push to Remote
When prompted, confirm the push. This will execute:
```bash
git push origin main --tags
```

## Post-Push Automation
Once the tag is pushed, the **Unified Pipeline** (`pipeline.yml`) takes over:

1. **GitHub Release**: Uses `@semantic-release/github` to create a new entry in the repository's "Releases" section, generates notes from the commits, and uploads binaries/scripts as assets.
2. **Documentation**: Builds the Docusaurus site and deploys it to GitHub Pages, ensuring the live docs match the latest release.

## Branch Protection Rules
The `main` branch should be protected with the following rules:
- **Restrict Pushes**: Only authorized roles can push.
- **Require Status Checks**: The `Continuous Integration` job must pass before code can be merged.
- **No Bypass**: No bypass is needed for workflows since they do not commit code.
