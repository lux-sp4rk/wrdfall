#!/bin/bash
# Arachne Review Script - Called by GitHub Actions
# Now with GDScript specialization for Word Loom

set -euo pipefail

ARCEE_API_KEY="${1:-}"
PR_NUMBER="${2:-}"
GH_TOKEN="${3:-}"
BASE_REF="${4:-main}"
HEAD_SHA="${5:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ -z "$ARCEE_API_KEY" ]; then
  echo "status=failure" >> "$GITHUB_OUTPUT"
  echo "review=❌ ARCEE_API_KEY not configured" >> "$GITHUB_OUTPUT"
  exit 1
fi

# Get diff - fetch enough history for merge base
git fetch origin "$BASE_REF"
git diff "origin/$BASE_REF...HEAD" > pr_diff.txt || git diff HEAD~1 > pr_diff.txt

# Check if GDScript files are present
GDSCRIPT_FILES=$(grep -E '^\+\+\+.*\.gd$' pr_diff.txt || true)
HAS_GDSCRIPT=$([ -n "$GDSCRIPT_FILES" ] && echo "true" || echo "false")

# Load GDScript reviewer prompt if available
GDSCRIPT_PROMPT=""
if [ "$HAS_GDSCRIPT" = "true" ] && [ -f "$REPO_ROOT/.agents/gd-script-review.md" ]; then
  GDSCRIPT_PROMPT=$(cat "$REPO_ROOT/.agents/gd-script-review.md")
fi

# Build base prompt
{
  echo "You are Arachne, a code reviewer. Review this git diff."
  echo ""

  # Inject GDScript-specific guidance if applicable
  if [ -n "$GDSCRIPT_PROMPT" ]; then
    echo "## Specialization: GDScript Review"
    echo "$GDSCRIPT_PROMPT"
    echo ""
    echo "---"
    echo ""
  fi

  echo "Analyze for bugs, security, performance, maintainability."
  echo "Severity: 🔴 Critical | 🟡 Warning | 🟢 Suggestion"
  echo "No issues? Reply: LGTM 👍"
  echo ""
  echo "End with exactly one of:"
  echo "STATUS: PASS"
  echo "STATUS: WARN"
  echo "STATUS: FAIL"
  echo ""
  echo "DIFF:"
  echo '```diff'
  head -c 40000 pr_diff.txt
  echo '```'
} > prompt.txt

echo "🕸️ Sending to Arachne..."
[ "$HAS_GDSCRIPT" = "true" ] && echo "📋 GDScript specialization active"
echo "API Key length: ${#ARCEE_API_KEY}"

JSON_PROMPT=$(jq -Rs . < prompt.txt)
JSON_PAYLOAD=$(jq -n --arg p "$JSON_PROMPT" '{model: "arcee/trinity-mini", messages: [{role: "system", content: "You are Arachne, expert code reviewer."}, {role: "user", content: $p}], temperature: 0.2, max_tokens: 2000}')

echo "Payload size: ${#JSON_PAYLOAD} bytes"

REVIEW_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST https://api.arcee.ai/v1/chat/completions \
  -H "Authorization: Bearer $ARCEE_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

HTTP_CODE=$(echo "$REVIEW_RESPONSE" | tail -n1)
REVIEW_RESPONSE=$(echo "$REVIEW_RESPONSE" | sed '$d')

echo "HTTP Code: $HTTP_CODE"
echo "Raw response: $REVIEW_RESPONSE"

REVIEW_TEXT=$(echo "$REVIEW_RESPONSE" | jq -r '.choices[0].message.content // empty')

if [ -z "$REVIEW_TEXT" ] || [ "$REVIEW_TEXT" = "null" ]; then
  ERROR_MSG=$(echo "$REVIEW_RESPONSE" | jq -r '.error.message // "API error"')
  echo "status=failure" >> "$GITHUB_OUTPUT"
  echo "review=❌ $ERROR_MSG" >> "$GITHUB_OUTPUT"
  exit 1
fi

# Parse status
if echo "$REVIEW_TEXT" | grep -q "STATUS: FAIL"; then
  STATUS="failure"
elif echo "$REVIEW_TEXT" | grep -q "STATUS: WARN"; then
  STATUS="warning"
else
  STATUS="success"
fi

CLEAN_REVIEW=$(echo "$REVIEW_TEXT" | grep -v "^STATUS: ")

# Build badge with specialization indicator
BADGE="❌"
[ "$STATUS" = "success" ] && BADGE="✅"
[ "$STATUS" = "warning" ] && BADGE="⚠️"

SPECIALIZATION=""
[ "$HAS_GDSCRIPT" = "true" ] && SPECIALIZATION=" + GDScript"

echo "status=$STATUS" >> "$GITHUB_OUTPUT"
{
  echo "review<<REVIEW_EOF"
  echo "$CLEAN_REVIEW"
  echo "REVIEW_EOF"
} >> "$GITHUB_OUTPUT"

# Post comment
export GH_TOKEN
gh pr review "$PR_NUMBER" --comment --body "$BADGE **Arachne Review** (arcee/trinity-mini$SPECIALIZATION)

$CLEAN_REVIEW

---
*Status: $STATUS | $(date -u +%Y-%m-%dT%H:%M:%SZ)*"

# Exit with error on failure
[ "$STATUS" != "failure" ] || exit 1
