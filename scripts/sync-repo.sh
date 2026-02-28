#!/bin/bash
# sync-repo.sh - Keep the local environment in sync with origin

echo "🔄 Syncing with origin..."

# 1. Fetch all changes and prune deleted remote branches
git fetch origin --prune

# 2. Update main
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "📥 Updating main while on $CURRENT_BRANCH..."
    git fetch origin main:main
else
    echo "📥 Pulling latest changes for main..."
    git pull origin main --rebase
fi

# 3. Clean up merged branches
echo "🧹 Cleaning up merged branches..."
# This deletes local branches that have been merged into origin/main
git branch --merged origin/main | grep -v '^*' | grep -v 'main' | xargs -r git branch -d

echo "✅ Sync complete. Local main is now at $(git rev-parse --short main)."
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  You are still on branch: $CURRENT_BRANCH"
    echo "💡 Suggestion: git checkout main"
fi
