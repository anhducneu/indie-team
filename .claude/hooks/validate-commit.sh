#!/usr/bin/env bash
# Hook: PreToolUse — Bash (git commit)
# Validates commit messages and scans staged diff for secrets before committing.
# Receives tool input as JSON on stdin.
# Exit 1 to block the commit; exit 0 to allow it.

set -euo pipefail

INPUT=$(cat)

# Only act on git commit commands
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

VIOLATIONS=()

# ── Commit message validation ─────────────────────────────────────────────────
# Extract the commit message from the command
MSG=$(echo "$COMMAND" | sed -n 's/.*-m[[:space:]]*"\([^"]*\)".*/\1/p' \
  || echo "$COMMAND" | sed -n "s/.*-m[[:space:]]*'\([^']*\)'.*/\1/p" \
  || echo "")

if [ -n "$MSG" ]; then
  # Minimum length
  if [ ${#MSG} -lt 10 ]; then
    VIOLATIONS+=("Commit message too short (minimum 10 characters)")
  fi

  # Conventional commit format check (soft — warning only in output)
  if ! echo "$MSG" | grep -qE '^(feat|fix|chore|docs|style|refactor|test|perf|ci|build|revert)(\(.+\))?(!)?:'; then
    echo ""
    echo "  ⚠️  Commit message does not follow Conventional Commits format."
    echo "  Expected: feat|fix|chore|docs|refactor|test|perf(scope): description"
    echo "  Got: $MSG"
    echo "  (Continuing — this is a warning, not a blocker)"
    echo ""
  fi
fi

# ── Secrets in staged diff ────────────────────────────────────────────────────
STAGED_DIFF=$(git diff --cached 2>/dev/null || echo "")

if [ -n "$STAGED_DIFF" ]; then
  if echo "$STAGED_DIFF" | grep -qE 'AKIA[0-9A-Z]{16}'; then
    VIOLATIONS+=("AWS Access Key ID (AKIA...) found in staged changes")
  fi

  if echo "$STAGED_DIFF" | grep -qiE '^\+(password|passwd|pwd)\s*[:=]\s*["\x27][^"\x27$\{][^"\x27]{3,}'; then
    VIOLATIONS+=("Hardcoded password found in staged changes")
  fi

  if echo "$STAGED_DIFF" | grep -qiE '^\+(api[_-]?key|secret[_-]?key|client[_-]?secret)\s*[:=]\s*["\x27][^"\x27$\{$\(]{8,}'; then
    VIOLATIONS+=("Hardcoded API key or secret found in staged changes")
  fi

  if echo "$STAGED_DIFF" | grep -q 'BEGIN.*PRIVATE KEY'; then
    VIOLATIONS+=("Private key material found in staged changes")
  fi

  # .env file being committed
  if git diff --cached --name-only 2>/dev/null | grep -qE '^\.env$|^\.env\.[^e]'; then
    VIOLATIONS+=(".env file is staged — only .env.example should be committed")
  fi
fi

# ── Debug artifacts ───────────────────────────────────────────────────────────
if [ -n "$STAGED_DIFF" ]; then
  if echo "$STAGED_DIFF" | grep -qE '^\+.*System\.out\.println'; then
    VIOLATIONS+=("System.out.println found in staged Java code — remove before committing")
  fi
  if echo "$STAGED_DIFF" | grep -qE '^\+.*console\.(log|debug|warn)\('; then
    VIOLATIONS+=("console.log/debug/warn found in staged frontend code — remove before committing")
  fi
fi

# ── Report ────────────────────────────────────────────────────────────────────
if [ ${#VIOLATIONS[@]} -gt 0 ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  🚨  COMMIT BLOCKED — Validation Failed                      ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
  for v in "${VIOLATIONS[@]}"; do
    echo "  ❌ $v"
  done
  echo ""
  echo "  Fix the issues above before committing."
  echo ""
  exit 1
fi

exit 0
