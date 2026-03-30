#!/usr/bin/env bash
# Hook: PreToolUse — Write, Edit
# Scans file content for hardcoded secrets and PII patterns before any file is written.
# Receives tool input as JSON on stdin.
# Exit 1 to block the write; exit 0 to allow it.

set -euo pipefail

# Read stdin into a variable
INPUT=$(cat)

# Extract tool name and file path
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

# Only check Write and Edit tool calls
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

# Skip binary files and lock files
if [[ "$FILE_PATH" =~ \.(png|jpg|jpeg|gif|ico|pdf|zip|jar|class|lock)$ ]]; then
  exit 0
fi

# Extract the content being written
if [[ "$TOOL_NAME" == "Write" ]]; then
  CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('content',''))" 2>/dev/null || echo "")
else
  # For Edit, check new_string
  CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('new_string',''))" 2>/dev/null || echo "")
fi

VIOLATIONS=()

# ── Secret patterns ────────────────────────────────────────────────────────────
# Password assignments (not in comments or .example files)
if [[ "$FILE_PATH" != *.example ]] && [[ "$FILE_PATH" != *example* ]]; then
  if echo "$CONTENT" | grep -qiE '(password|passwd|pwd)\s*[:=]\s*["\x27][^"\x27$\{][^"\x27]{3,}'; then
    VIOLATIONS+=("Hardcoded password detected")
  fi

  if echo "$CONTENT" | grep -qiE '(api[_-]?key|apikey)\s*[:=]\s*["\x27][A-Za-z0-9+/=_-]{10,}'; then
    VIOLATIONS+=("Hardcoded API key detected")
  fi

  if echo "$CONTENT" | grep -qiE '(secret[_-]?key|client[_-]?secret)\s*[:=]\s*["\x27][^"\x27$\{]{8,}'; then
    VIOLATIONS+=("Hardcoded secret detected")
  fi

  # AWS keys
  if echo "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}'; then
    VIOLATIONS+=("AWS Access Key ID detected (AKIA...)")
  fi

  if echo "$CONTENT" | grep -qE '[A-Za-z0-9+/]{40}' && echo "$CONTENT" | grep -qiE 'aws.*secret'; then
    VIOLATIONS+=("Potential AWS Secret Access Key detected")
  fi

  # Private keys
  if echo "$CONTENT" | grep -q 'BEGIN.*PRIVATE KEY'; then
    VIOLATIONS+=("Private key material detected")
  fi

  # JWT secrets
  if echo "$CONTENT" | grep -qiE 'jwt[._-]?(secret|signing[_-]?key)\s*[:=]\s*["\x27][^"\x27$\{]{8,}'; then
    VIOLATIONS+=("Hardcoded JWT secret detected")
  fi
fi

# ── PII in log statements ──────────────────────────────────────────────────────
if echo "$CONTENT" | grep -qiE 'log\.(info|debug|warn|error|trace).*\b(cardNumber|cvv|ssn|password|token|secret|accountNumber|pan\b)'; then
  VIOLATIONS+=("PII or sensitive field name appears in a log statement")
fi

# ── SQL injection risk ─────────────────────────────────────────────────────────
if echo "$CONTENT" | grep -qE '"(SELECT|INSERT|UPDATE|DELETE).*"\s*\+'; then
  VIOLATIONS+=("Possible SQL string concatenation (SQL injection risk) — use parameterized queries")
fi

# ── dangerouslySetInnerHTML without comment ────────────────────────────────────
if echo "$CONTENT" | grep -q 'dangerouslySetInnerHTML' && ! echo "$CONTENT" | grep -q 'security-engineer'; then
  VIOLATIONS+=("dangerouslySetInnerHTML used without @security-engineer sign-off comment")
fi

# ── Report violations ─────────────────────────────────────────────────────────
if [ ${#VIOLATIONS[@]} -gt 0 ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  🚨  WRITE BLOCKED — Security/Compliance Violation           ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
  echo "  File: $FILE_PATH"
  echo ""
  for v in "${VIOLATIONS[@]}"; do
    echo "  ❌ $v"
  done
  echo ""
  echo "  Fix the issue before writing this file."
  echo "  If this is a false positive, explain why to the human first."
  echo ""
  exit 1
fi

exit 0
