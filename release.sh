#!/bin/bash
set -e

# Role: Senior DevOps Architect & Automation Specialist
# Task: Local-First Release Automation for dbx-smith
# This script handles versioning, changelog updates, and tagging locally.

# 1. Verification
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" != "main" ]; then
  echo "❌ Error: Releases must be initiated from the 'main' branch."
  exit 1
fi

if [[ $(git status --short) ]]; then
  echo "❌ Error: Working directory is not clean. Commit or stash your changes first."
  exit 1
fi

echo "🚀 Starting Local-First Release Strategy..."

# 2. Version Calculation & Changelog Update
# We use standard-version to manage the semver bump and CHANGELOG.md
# It will also update version in package.json
echo "📊 Calculating next version and updating CHANGELOG.md..."
npx standard-version --skip.tag true --skip.commit true

# 3. Code-Level Version Synchronization
# Extract the new version from package.json
NEW_VERSION=$(node -e "console.log(require('./package.json').version)")
echo "🔄 Synchronizing version v$NEW_VERSION across codebase..."

# Update version in main binary
sed -i "s/readonly VERSION=\".*\"/readonly VERSION=\"$NEW_VERSION\"/" bin/dbx-smith-spin

# 4. Finalize Local Commit and Tag
echo "💾 Committing version bump and creating tag v$NEW_VERSION..."
git add package.json CHANGELOG.md bin/dbx-smith-spin
git commit -m "chore(release): $NEW_VERSION [skip ci]"
git tag -a "v$NEW_VERSION" -m "release v$NEW_VERSION"

echo "✅ Local release v$NEW_VERSION prepared successfully!"

# 5. Push to Remote
read -p "❓ Do you want to push the release to origin? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "📤 Pushing to origin..."
  git push origin main --tags
  echo "🎉 Push successful! The GitHub Action will now trigger the Release UI and Docs update."
else
  echo "⚠️  Release created locally but NOT pushed. Run 'git push origin main --tags' when ready."
fi
