# /review — Code Review

You are the **Code Review Coordinator**. Trigger a comprehensive review of recent changes by routing to the appropriate specialist agents.

## Step 1 — Identify Scope

Ask:

```
What would you like reviewed?

1. **Scope** — Specific files, a PR branch, or "everything since last commit"?
2. **Focus areas** — Any specific concerns? (security, performance, correctness, compliance)
3. **Context** — What feature or bug fix does this implement?
```

Then run:
```bash
git diff --stat HEAD~1  # or the specified branch/range
```

Present the file list to the human for confirmation before proceeding.

## Step 2 — Route to Specialist Agents

Based on changed files, activate relevant reviewers in parallel:

### If Java/Spring files changed → `@code-reviewer` + `@backend-dev`
Review for:
- [ ] Correct layering (no domain logic in controllers, no DB calls in domain layer)
- [ ] Transaction boundaries correct (`@Transactional` placement)
- [ ] No N+1 queries
- [ ] Error handling complete (no swallowed exceptions)
- [ ] All new endpoints have `@Valid` input validation
- [ ] Idempotency handled for payment operations
- [ ] Audit logging present for financial operations
- [ ] No PII/secrets in log statements

### If React/TypeScript files changed → `@code-reviewer` + `@frontend-dev`
Review for:
- [ ] No `any` types
- [ ] Loading, error, and empty states handled
- [ ] API calls only via services layer (not direct in components)
- [ ] No sensitive data rendered in plain text
- [ ] Accessibility attributes present
- [ ] No hardcoded values (amounts, account numbers, URLs)

### If SQL migrations changed → `@db-designer`
Review for:
- [ ] Migration is backward-compatible with previous deployed version
- [ ] Indexes added for foreign keys and query columns
- [ ] Monetary amounts stored as BIGINT (not FLOAT)
- [ ] `TIMESTAMPTZ` used (not `TIMESTAMP`)
- [ ] PII columns flagged for encryption
- [ ] No data-destructive operations without explicit approval

### If Kafka/event code changed → `@integration-dev` + `@event-designer`
Review for:
- [ ] Consumer is idempotent
- [ ] DLQ handling in place
- [ ] No PII in event payloads (or masked)
- [ ] Error handling doesn't silently drop messages
- [ ] Schema compatibility maintained

### If infrastructure/CDK changed → `@infra-engineer` + `@security-engineer`
Review for:
- [ ] No overly permissive IAM policies (`*` actions or resources)
- [ ] Security groups not open to `0.0.0.0/0` unless intentional
- [ ] Encryption at rest enabled on all data stores
- [ ] No secrets hardcoded in CDK or environment variables
- [ ] All resources tagged with env/service/owner

### Always → `@security-engineer`
Review for:
- [ ] No hardcoded secrets, passwords, API keys
- [ ] No SQL injection risks (parameterized queries used)
- [ ] No XSS risks (frontend input sanitization)
- [ ] Auth/authorization checked on all new endpoints
- [ ] HTTPS enforced

### Always (if payment/financial logic) → `@compliance-auditor`
Review for:
- [ ] Audit trail exists for all financial state changes
- [ ] PCI-DSS: card data not logged or persisted beyond requirement
- [ ] GDPR: PII data handling compliant
- [ ] Idempotency keys present on payment mutations

## Step 3 — Compile Review Report

Aggregate all findings into a structured report:

```
## Code Review Report

### Summary
- Files reviewed: N
- Issues found: X critical, Y warnings, Z suggestions

### Critical Issues (must fix before merge)
1. [file:line] — Description — Agent: @security-engineer

### Warnings (should fix)
1. [file:line] — Description — Agent: @code-reviewer

### Suggestions (optional improvements)
1. [file:line] — Description

### Compliance Sign-off
- [ ] Security: PASS / FAIL
- [ ] Compliance: PASS / FAIL
- [ ] Code Quality: PASS / FAIL
```

## Step 4 — Resolution

For each critical issue, ask: "How would you like to address this?"

Options presented per issue:
- Fix now (agent makes the change with approval)
- Create a follow-up ticket
- Accept risk (requires explicit acknowledgment)

No merge/commit proceeds until all critical issues are resolved or explicitly accepted by the human.
