#!/bin/bash
# scripts/d33-local.sh - Local bug hunter (D33 equivalent)
# Runs static analysis and common bug pattern detection

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🐛 Bug Hunter D33 (Local Mode)"
echo "================================"

ISSUES_FOUND=0

# Check for console.log statements that shouldn't be in production
echo ""
echo "🔍 Checking for stray console.log statements..."
LOGS=$(find "$PROJECT_ROOT" -type d -name node_modules -prune -o -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" \) -print 2>/dev/null | xargs grep -l "console.log" 2>/dev/null | grep -v node_modules | head -5 || true)
if [ -n "$LOGS" ]; then
    echo "$LOGS"
    echo "⚠️  Found console.log statements (mark with // debug to allow)"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "✅ No stray console.log found"
fi

# Check for .only in tests
echo ""
echo "🔍 Checking for .only in tests..."
ONLY_TESTS=$(find "$PROJECT_ROOT" -type d -name node_modules -prune -o -type f \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" \) -print 2>/dev/null | xargs grep -l "\.only(" 2>/dev/null | grep -v node_modules | head -5 || true)
if [ -n "$ONLY_TESTS" ]; then
    echo "$ONLY_TESTS"
    echo "❌ Found .only() in tests - will skip other tests in CI!"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "✅ No .only() found in tests"
fi

# Check for TODO/FIXME without issue reference
echo ""
echo "🔍 Checking for TODO/FIXME without issue refs..."
TODOS=$(find "$PROJECT_ROOT/src" "$PROJECT_ROOT/landing/src" -type f \( -name "*.ts" -o -name "*.tsx" \) 2>/dev/null | xargs grep -n "TODO:\|FIXME:" 2>/dev/null | grep -v "TODO: #\|FIXME: #\|node_modules" | head -3 || true)
if [ -n "$TODOS" ]; then
    echo "$TODOS"
    echo "⚠️  Found TODO/FIXME without issue reference (format: TODO: #123)"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "✅ All TODOs have issue references"
fi

# Check TypeScript compilation
echo ""
echo "🔍 Running TypeScript check..."
cd "$PROJECT_ROOT/landing"
if ! npx tsc --noEmit 2>/dev/null | head -20; then
    echo "❌ TypeScript errors found"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "✅ TypeScript compiles cleanly"
fi

# Summary
echo ""
echo "================================"
if [ $ISSUES_FOUND -eq 0 ]; then
    echo "✅ D33 found no issues - ready to push!"
    exit 0
else
    echo "❌ D33 found $ISSUES_FOUND issue(s)"
    echo ""
    echo "Fix these or push with: SKIP_LOCAL_CHECKS=1 git push"
    exit 1
fi
