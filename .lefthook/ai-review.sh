#!/usr/bin/env bash
# Lefthook AI Review Trigger
# 
# Usage:
#   .lefthook/ai-review.sh          # Auto-trigger on push
#   .lefthook/ai-review.sh --manual # Manual trigger via: lefthook run review
#
# Posts PR diff review via GitHub CLI.
# Requires: gh, git, and either ARCEE_API_KEY for local review or manual fallback.

set -euo pipefail

# Config
LOCKFILE_DIR="/tmp/arachne-reviews"
REVIEW_DIR="$HOME/.openclaw/reviews"
mkdir -p "$LOCKFILE_DIR" "$REVIEW_DIR"

# Get current branch and PR info
BRANCH=$(git branch --show-current)
PR_INFO=$(gh pr view "$BRANCH" --json number,title,url --jq '[.number, .title, .url] | @tsv' 2>/dev/null || true)

if [ -z "$PR_INFO" ]; then
  [ "${1:-}" == "--manual" ] && echo "No PR found for branch: $BRANCH"
  exit 0
fi

# Parse PR info
read -r PR_NUM PR_TITLE PR_URL <<< "$PR_INFO"

# Check lockfile
LOCKFILE="$LOCKFILE_DIR/pr-${PR_NUM}"
if [ -f "$LOCKFILE" ]; then
  AGE=$(($(date +%s) - $(stat -c %Y "$LOCKFILE" 2>/dev/null || stat -f %m "$LOCKFILE" 2>/dev/null || echo "0")))
  if [ "$AGE" -lt 300 ]; then
    echo "🔒 Review already in progress (age: ${AGE}s). Use --manual to force."
    exit 0
  fi
fi

touch "$LOCKFILE"

# Get the diff
DIFF=$(git diff origin/main...HEAD 2>/dev/null || git diff HEAD~10..HEAD)
DIFF_STAT=$(git diff --stat origin/main...HEAD 2>/dev/null || git diff --stat HEAD~10..HEAD)

if [ -z "$DIFF" ]; then
  echo "No diff to review"
  rm -f "$LOCKFILE"
  exit 0
fi

echo "🔍 Arachne reviewing PR #$PR_NUM: $PR_TITLE"
echo "   Files changed:"
echo "$DIFF_STAT" | head -8

# Save files for review
REVIEW_ID="pr-${PR_NUM}-$(date +%Y%m%d-%H%M%S)"
DIFF_FILE="$REVIEW_DIR/${REVIEW_ID}.diff"
echo "$DIFF" > "$DIFF_FILE"

echo "   Diff saved: $DIFF_FILE"

# Check if we can do automated review
if [ -z "${ARCEE_API_KEY:-}" ] && [ -z "${OPENAI_API_KEY:-}" ]; then
  echo ""
  echo "⚠️  No API key found (ARCEE_API_KEY or OPENAI_API_KEY)"
  echo "   Review queued for manual processing."
  echo ""
  echo "To complete the review, run:"
  echo "   openclaw agent --agent main --message \"Review PR $PR_NUM: $(pwd)/${DIFF_FILE}\""
  rm -f "$LOCKFILE"
  exit 0
fi

# Run automated review
echo "🚀 Running automated review..."

# Create review prompt
PROMPT="You are Arachne, a code reviewer. Review this git diff and provide concise feedback:

Focus on:
- Bugs or logic errors
- Security issues  
- Performance problems
- Missing test coverage

Format as markdown bullet points. If no issues found, reply only: LGTM 👍

DIFF:
\`\`\`diff
$(cat "$DIFF_FILE" | head -500)
\`\`\`"

# Run review via OpenClaw agent (local mode with available model)
if [ -n "${ARCEE_API_KEY:-}" ]; then
  MODEL="arcee/trinity-mini"
else
  MODEL="openai/gpt-4o-mini"
fi

REVIEW_OUTPUT=$(openclaw agent --local --agent main --message "$PROMPT" --thinking low 2>&1 || echo "Review failed")

if [ -n "$REVIEW_OUTPUT" ] && [ "$REVIEW_OUTPUT" != "Review failed" ]; then
  # Post to GitHub
  gh pr review "$PR_NUM" --comment -b "🕸️ **Arachne Review** ($MODEL)

$REVIEW_OUTPUT

---
*Automated review via lefthook | $(date -u +%Y-%m-%dT%H:%M:%SZ)*"
  
  echo "✅ Review posted to PR #$PR_NUM"
else
  echo "❌ Review generation failed"
  echo "$REVIEW_OUTPUT" > "$REVIEW_DIR/${REVIEW_ID}.error.log"
fi

rm -f "$LOCKFILE" "$DIFF_FILE"
exit 0
