#!/bin/bash
# .lefthook/rescue-main-commits.sh
# Catches any commit directly to main and auto-creates a PR

set -e

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  exit 0
fi

BEHIND=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
if [ "$BEHIND" = "0" ]; then
  exit 0
fi

FEATURE_BRANCH="hotfix/from-main-$(date +%Y%m%d-%H%M%S)"

echo "⚠️  Detected $BEHIND commit(s) on main. Rescuing to branch $FEATURE_BRANCH..."

# Create feature branch at current HEAD (preserves all commits)
git branch "$FEATURE_BRANCH" HEAD

# Reset main to origin/main (safe — commits are now on the feature branch)
git reset --hard origin/main

# Push feature branch
git push origin "$FEATURE_BRANCH" -u 2>&1 || {
  echo "⚠️  Push failed — check gh auth"
  exit 0
}

# Build PR body from commit messages
COMMIT_MESSAGES=$(git log --oneline origin/main.."$FEATURE_BRANCH" | head -10 | sed 's/^/- /' | tr '\n' ' ')

PR_URL=$(gh pr create \
  --title "fix: hotfix from direct main commit ($(date +%Y-%m-%d))" \
  --body "Auto-created by post-commit hook.

Commits rescued from main:
$COMMIT_MESSAGES" \
  --base main \
  --head "$FEATURE_BRANCH" 2>&1) || {
  echo "⚠️  gh pr create failed"
  exit 0
}

echo "✅ PR opened: $PR_URL"
