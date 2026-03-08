#!/bin/bash
# Arachne Review Script - Called by GitHub Actions
# Now with GDScript specialization for Word Loom + Retry logic

set -euo pipefail

ARCEE_API_KEY="${1:-}"
PR_NUMBER="${2:-}"
GH_TOKEN="${3:-}"
BASE_REF="${4:-main}"
HEAD_SHA="${5:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Retry configuration
MAX_RETRIES=3
RETRY_DELAY=2

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
JSON_PAYLOAD=$(jq -n --arg p "$JSON_PROMPT" '{model: "trinity-mini", messages: [{role: "system", content: "You are Arachne, expert code reviewer."}, {role: "user", content: $p}], temperature: 0.2, max_tokens: 2000}')

echo "Payload size: ${#JSON_PAYLOAD} bytes"

# Retry loop for API call
ATTEMPT=0
HTTP_CODE=""
REVIEW_RESPONSE=""
REVIEW_TEXT=""

while [ $ATTEMPT -lt $MAX_RETRIES ]; do
  ATTEMPT=$((ATTEMPT + 1))
  echo "Attempt $ATTEMPT/$MAX_RETRIES..."

  REVIEW_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST https://api.arcee.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $ARCEE_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" 2>&1 || true)

  HTTP_CODE=$(echo "$REVIEW_RESPONSE" | tail -n1)
  REVIEW_RESPONSE=$(echo "$REVIEW_RESPONSE" | sed '$d')

  echo "HTTP Code: $HTTP_CODE"

  # Check for rate limiting
  if [ "$HTTP_CODE" = "429" ]; then
    echo "⚠️ Rate limited (429)"
    if [ $ATTEMPT -lt $MAX_RETRIES ]; then
      DELAY=$((RETRY_DELAY * ATTEMPT))
      echo "Waiting ${DELAY}s before retry..."
      sleep $DELAY
      continue
    fi
  fi

  # Check for server errors (5xx)
  if [ "$HTTP_CODE" -ge 500 ] 2>/dev/null; then
    echo "⚠️ Server error ($HTTP_CODE)"
    if [ $ATTEMPT -lt $MAX_RETRIES ]; then
      DELAY=$((RETRY_DELAY * ATTEMPT))
      echo "Waiting ${DELAY}s before retry..."
      sleep $DELAY
      continue
    fi
  fi

  # Check for empty response despite success code
  if [ -z "$REVIEW_RESPONSE" ] && [ "$HTTP_CODE" = "200" ]; then
    echo "⚠️ Empty response (HTTP 200)"
    if [ $ATTEMPT -lt $MAX_RETRIES ]; then
      DELAY=$((RETRY_DELAY * ATTEMPT))
      echo "Waiting ${DELAY}s before retry..."
      sleep $DELAY
      continue
    fi
  fi

  # Extract review text
  if [ -n "$REVIEW_RESPONSE" ]; then
    REVIEW_TEXT=$(echo "$REVIEW_RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null || true)
    ERROR_MSG=$(echo "$REVIEW_RESPONSE" | jq -r '.error.message // empty' 2>/dev/null || true)

    # Check for API error in response body
    if [ -n "$ERROR_MSG" ] && [ "$ERROR_MSG" != "null" ]; then
      echo "API Error: $ERROR_MSG"
      if [ $ATTEMPT -lt $MAX_RETRIES ]; then
        DELAY=$((RETRY_DELAY * ATTEMPT))
        echo "Waiting ${DELAY}s before retry..."
        sleep $DELAY
        continue
      fi
    fi

    # Success - we got review text
    if [ -n "$REVIEW_TEXT" ] && [ "$REVIEW_TEXT" != "null" ]; then
      echo "✅ Review received (${#REVIEW_TEXT} chars)"
      break
    fi
  fi

  # If we got here without continuing, check if we should retry
  if [ $ATTEMPT -lt $MAX_RETRIES ]; then
    DELAY=$((RETRY_DELAY * ATTEMPT))
    echo "Waiting ${DELAY}s before retry..."
    sleep $DELAY
  fi
done

# Final check - did we get a valid review?
if [ -z "$REVIEW_TEXT" ] || [ "$REVIEW_TEXT" = "null" ]; then
  echo "❌ Failed to get review after $MAX_RETRIES attempts"
  echo "Last HTTP code: $HTTP_CODE"
  echo "Last response: $REVIEW_RESPONSE"

  # Graceful degradation - don't fail the build, just warn
  echo "status=warning" >> "$GITHUB_OUTPUT"
  {
    echo "review<<REVIEW_EOF"
    echo "⚠️ Arachne review unavailable"
    echo ""
    echo "The code review service is temporarily unavailable (HTTP $HTTP_CODE)."
    echo "This is not a code issue - please review manually or retry later."
    echo ""
    echo "Last response snippet:"
    echo "\`\`\`"
    echo "$REVIEW_RESPONSE" | head -c 500
    echo "\`\`\`"
    echo "REVIEW_EOF"
  } >> "$GITHUB_OUTPUT"

  # Post warning comment but don't fail
  export GH_TOKEN
  gh pr review "$PR_NUMBER" --comment --body "⚠️ **Arachne Review** (trinity-mini)

Review service temporarily unavailable (HTTP $HTTP_CODE after $MAX_RETRIES retries).
Please review manually.

---
*Status: warning | $(date -u +%Y-%m-%dT%H:%M:%SZ)*"

  exit 0  # Don't fail the build
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
gh pr review "$PR_NUMBER" --comment --body "$BADGE **Arachne Review** (trinity-mini$SPECIALIZATION)

$CLEAN_REVIEW

---
*Status: $STATUS | $(date -u +%Y-%m-%dT%H:%M:%SZ)*"

# Exit with error on failure
[ "$STATUS" != "failure" ] || exit 1
