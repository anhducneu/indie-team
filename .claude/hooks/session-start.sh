#!/usr/bin/env bash
# Hook: session-start
# Runs at the beginning of every Claude Code session.
# Prints active context: branch, agent roster, and compliance reminders.

set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo ".")"
cd "$REPO_ROOT"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Indie Dev Team — Fintech Agent Architecture         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Git context
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
LAST_COMMIT=$(git log -1 --format="%h %s" 2>/dev/null || echo "no commits")
echo "  Branch : $BRANCH"
echo "  Last   : $LAST_COMMIT"
echo ""

# Uncommitted work warning
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$DIRTY" -gt 0 ]; then
  echo "  ⚠️  Uncommitted changes: $DIRTY file(s)"
fi

# Active TODOs / FIXMEs in recently changed files
TODO_COUNT=$(git diff --name-only HEAD~1 2>/dev/null \
  | xargs grep -l "TODO\|FIXME\|HACK\|XXX" 2>/dev/null \
  | wc -l | tr -d ' ')
if [ "$TODO_COUNT" -gt 0 ]; then
  echo "  📋 Files with TODO/FIXME markers (recent changes): $TODO_COUNT"
fi

echo ""
echo "─────────────────────────── AGENTS ───────────────────────────"
echo "  Planning : @product-manager  @project-manager  @system-architect"
echo "  Design   : @ux-designer  @api-designer  @db-designer  @event-designer"
echo "  Dev      : @frontend-dev  @backend-dev  @integration-dev"
echo "             @infra-engineer  @security-engineer"
echo "  Quality  : @qa-engineer  @test-automator  @code-reviewer"
echo "             @compliance-auditor"
echo "  Docs     : @tech-writer  @api-documenter"
echo ""
echo "──────────────────────── COMPLIANCE ──────────────────────────"
echo "  🔒 No secrets in code, logs, or commits — ever"
echo "  🔒 No PII in logs — mask card numbers, SSN, account numbers"
echo "  🔒 Every financial operation needs an audit trail"
echo "  🔒 @compliance-auditor must sign off before production"
echo ""
echo "──────────────────────── PROTOCOL ────────────────────────────"
echo "  Ask before writing any file  |  No git ops without instruction"
echo "  Show full draft before approval  |  Multi-file: list all upfront"
echo ""
echo "  /start  /plan  /review  /deploy  /standup  /audit"
echo "══════════════════════════════════════════════════════════════"
echo ""

exit 0
