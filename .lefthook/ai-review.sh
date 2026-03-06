#!/usr/bin/env bash
# Lefthook AI Review Trigger
# 
# Usage:
#   .lefthook/ai-review.sh          # Auto-trigger on push
#   .lefthook/ai-review.sh --manual # Manual trigger via: lefthook run review
#
# Spawns Arachne via ACP to review the PR diff and post comments.
# Uses arcee/trinity-mini for cost-effective code review.

set -euo pipefail

# Config
LOCKFILE_DIR="/tmp/arachne-reviews"
REVIEW_PROMPT='
You are Arachne, a code reviewer. Review this diff and provide feedback on:
- Code quality and best practices
- Potential bugs or issues
- Performance considerations
- Security concerns
- Test coverage

Be constructive and concise. Format your review as markdown.
If there are no issues, say "LGTM 👍" and nothing else.
'

# Ensure lockfile dir exists
mkdir -p "$LOCKFILE_DIR"

# Get current branch and PR info
BRANCH=$(git branch --show-current)
PR_INFO=$(gh pr view "$BRANCH" --json number,title,url --jq '[.number, .title, .url] | @tsv' 2>/dev/null || true)

if [ -z "$PR_INFO" ]; then
  [ "$1" == "--manual" ] && echo "No PR found for branch: $BRANCH"
  exit 0
fi

# Parse PR info
read -r PR_NUM PR_TITLE PR_URL <<< "$PR_INFO"

# Check lockfile (prevent duplicate reviews on rapid pushes)
LOCKFILE="$LOCKFILE_DIR/pr-${PR_NUM}"
if [ -f "$LOCKFILE" ]; then
  AGE=$(($(date +%s) - $(stat -c %Y "$LOCKFILE" 2>/dev/null || stat -f %m "$LOCKFILE")))
  
  # If lockfile is less than 5 minutes old, skip
  if [ "$AGE" -lt 300 ]; then
    echo "🔒 Review already in progress (age: ${AGE}s). Use --manual to force."
    exit 0
  fi
fi

# Update lockfile
touch "$LOCKFILE"

# Get the diff
DIFF=$(git diff origin/main...HEAD 2>/dev/null || git diff HEAD~10..HEAD)
DIFF_STAT=$(git diff --stat origin/main...HEAD 2>/dev/null || git diff --stat HEAD~10..HEAD)

if [ -z "$DIFF" ]; then
  echo "No diff to review"
  exit 0
fi

echo "🔍 Arachne reviewing PR #$PR_NUM: $PR_TITLE"
echo "   URL: $PR_URL"
echo "   Files changed:"
echo "$DIFF_STAT" | head -20

# Build the review task for Arachne
REVIEW_TASK=$(cat << EOF
cd $(pwd)

# Get fresh diff
DIFF=\$(git diff origin/main...HEAD 2>/dev/null || git diff HEAD~10..HEAD)

# Run review with trinity-mini (cost-optimized)
REVIEW=\$(echo "\$DIFF" | acpx run --agent arachne --model arcee/trinity-mini --task "$REVIEW_PROMPT")

# Post to GitHub PR
if [ -n "\$REVIEW" ]; then
  gh pr review $PR_NUM --comment -b "🕸️ **Arachne Review**

\$REVIEW

---
*Reviewed by Arachne via trinity-mini | $(date -u +%Y-%m-%dT%H:%M:%SZ)*"
  
  echo "✅ Review posted to PR #$PR_NUM"
else
  echo "⚠️ Review generated but was empty"
fi
EOF
)

# Spawn via sessions_spawn (ACP runtime)
# This runs async - push completes immediately, review posts when ready
echo "🚀 Spawning Arachne (ACP/trinity-mini)..."

# Create a detached process to run the review
(
  # Run the review task
  echo "$REVIEW_TASK" | bash 2>&1 | while read line; do
    echo "[arachne-review:$PR_NUM] \$line"
  done
  
  # Clean up lockfile after completion
  rm -f "$LOCKFILE"
) &

# Get the PID
REVIEW_PID=$!

echo "   PID: $REVIEW_PID"
echo "   Lockfile: $LOCKFILE"
echo ""
echo "✨ Review running async. Push completes now."
echo "   Check PR: $PR_URL"

# Don't wait - let the push complete
exit 0
