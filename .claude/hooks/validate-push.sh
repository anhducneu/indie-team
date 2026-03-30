#!/usr/bin/env bash
# Hook: PreToolUse — Bash (git push)
# Pre-push checks: branch protection, secrets scan, test gate reminder.
# Receives tool input as JSON on stdin.
# Exit 1 to block the push; exit 0 to allow it.

set -euo pipefail

INPUT=$(cat)

# Only act on git push commands
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

if ! echo "$COMMAND" | grep -q 'git push'; then
  exit 0
fi

VIOLATIONS=()
WARNINGS=()

# ── Branch protection ─────────────────────────────────────────────────────────
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
PROTECTED_BRANCHES="main master"

for protected in $PROTECTED_BRANCHES; do
  if [ "$CURRENT_BRANCH" = "$protected" ]; then
    VIOLATIONS+=("Direct push to '$protected' is not allowed — open a pull request instead")
    break
  fi
done

# Force push check
if echo "$COMMAND" | grep -qE '\-\-force|-f[[:space:]]'; then
  VIOLATIONS+=("Force push detected — this can overwrite history. Explicit human approval required.")
fi

# ── Secrets scan on commits being pushed ─────────────────────────────────────
# Get commits that will be pushed (not yet on remote)
REMOTE_BRANCH="origin/$CURRENT_BRANCH"
if git rev-parse --verify "$REMOTE_BRANCH" >/dev/null 2>&1; then
  PUSH_DIFF=$(git log "$REMOTE_BRANCH..HEAD" -p 2>/dev/null || echo "")
else
  # New branch — check last 5 commits
  PUSH_DIFF=$(git log -5 -p 2>/dev/null || echo "")
fi

if [ -n "$PUSH_DIFF" ]; then
  if echo "$PUSH_DIFF" | grep -qE 'AKIA[0-9A-Z]{16}'; then
    VIOLATIONS+=("AWS Access Key ID (AKIA...) found in commits being pushed")
  fi

  if echo "$PUSH_DIFF" | grep -q 'BEGIN.*PRIVATE KEY'; then
    VIOLATIONS+=("Private key material found in commits being pushed")
  fi

  if echo "$PUSH_DIFF" | grep -qiE '(password|api[_-]?key|secret)\s*[:=]\s*["\x27][^"\x27$\{]{8,}'; then
    VIOLATIONS+=("Possible hardcoded credential found in commits being pushed")
  fi

  # .env file in commits
  if git log --name-only --format="" "$REMOTE_BRANCH..HEAD" 2>/dev/null | grep -qE '^\.env$' \
    || git log --name-only --format="" -5 2>/dev/null | grep -qE '^\.env$'; then
    VIOLATIONS+=(".env file detected in commits — only .env.example should ever be committed")
  fi
fi

# ── Test gate reminder ────────────────────────────────────────────────────────
# Check if there are any test files changed without corresponding test updates
SRC_CHANGES=$(git log --name-only --format="" "$REMOTE_BRANCH..HEAD" 2>/dev/null \
  | grep -cE 'src/main/java|frontend/src/(components|features|pages)' || echo "0")
TEST_CHANGES=$(git log --name-only --format="" "$REMOTE_BRANCH..HEAD" 2>/dev/null \
  | grep -cE 'src/test/java|\.test\.(ts|tsx|js)|\.spec\.(ts|tsx|js)|e2e/' || echo "0")

if [ "$SRC_CHANGES" -gt 0 ] && [ "$TEST_CHANGES" -eq 0 ]; then
  WARNINGS+=("Source files changed but no test files updated — confirm test coverage is sufficient")
fi

# ── Uncommitted changes ───────────────────────────────────────────────────────
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$DIRTY" -gt 0 ]; then
  WARNINGS+=("You have $DIRTY uncommitted change(s) that will NOT be included in this push")
fi

# ── Report ────────────────────────────────────────────────────────────────────
if [ ${#VIOLATIONS[@]} -gt 0 ] || [ ${#WARNINGS[@]} -gt 0 ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"

  if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo "║  🚨  PUSH BLOCKED — Validation Failed                        ║"
  else
    echo "║  ⚠️   PUSH CHECK — Warnings (not blocked)                    ║"
  fi

  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
  echo "  Branch : $CURRENT_BRANCH → origin"
  echo ""

  for v in "${VIOLATIONS[@]}"; do
    echo "  ❌ $v"
  done

  for w in "${WARNINGS[@]}"; do
    echo "  ⚠️  $w"
  done

  if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo ""
    echo "  Push blocked. Fix violations and try again."
    echo ""
    exit 1
  else
    echo ""
    echo "  No blockers — push proceeding. Review warnings above."
    echo ""
  fi
fi

echo "  ✅ Push checks passed — branch: $CURRENT_BRANCH"
exit 0
