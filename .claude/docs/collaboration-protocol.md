# Collaboration Protocol

## Core Principle

**User-driven collaboration, not autonomous execution.** Claude agents assist — humans decide and approve. This is especially critical in a fintech/banking context where changes may have compliance, security, or financial impact.

---

## Standard Workflow

Every task, regardless of size, follows this flow:

```
1. QUESTION   — Agent clarifies scope, constraints, unknowns
2. OPTIONS    — Agent presents 2-3 approaches with trade-offs
3. DECISION   — Human selects an approach (or proposes another)
4. DRAFT      — Agent produces the full draft/plan/code
5. APPROVAL   — Human reviews and explicitly approves
6. EXECUTE    — Agent writes files / runs commands
```

No step may be skipped. An agent that jumps from step 1 to step 6 has violated protocol.

---

## Approval Gates

### Gate 1 — Before Writing Any File
Agent must ask:
```
May I write this to [filepath]?

Preview:
[show first 20–30 lines or a summary of the full content]
```

The human must reply with an explicit confirmation (e.g. "yes", "go ahead", "approved") before the Write/Edit tool is used.

### Gate 2 — Before Multi-File Changesets
Agent must list the full changeset upfront:
```
I plan to modify the following files:
1. src/main/java/.../PaymentService.java  — add idempotency check
2. src/main/resources/db/migration/V5__add_idempotency_key.sql  — new migration
3. src/test/java/.../PaymentServiceTest.java  — add test coverage

May I proceed with all of these?
```

The human approves the full list, not file-by-file unless they prefer it.

### Gate 3 — Before Any Git Operation
Never commit, push, tag, or merge without explicit instruction:
```
Ready to commit. Suggested message:
  feat(payments): add idempotency key to payment processing

Shall I run git commit?
```

### Gate 4 — Before Any Deployment or Infrastructure Change
All cloud resource changes (AWS CDK deploy, Terraform apply, Docker build/push) require explicit approval with a summary of what will change:
```
This CDK deployment will:
- Create: ECS Service (payments-service)
- Modify: RDS Security Group (add inbound port 5432 from payments-service)
- No deletions

Environment: staging
Shall I proceed?
```

---

## Agent Handoff Protocol

When a task crosses agent boundaries, the handing-off agent must:

1. Summarize work completed
2. State clearly what the next agent needs to do
3. Ask the human to confirm the handoff

Example:
```
@api-designer has completed the OpenAPI spec for POST /payments.
Next step: @backend-dev should implement the PaymentController.
Shall I hand this off to @backend-dev?
```

---

## Conflict Resolution

If two agents disagree on an approach (e.g. `@system-architect` prefers event sourcing, `@backend-dev` flags performance concerns):

1. Each agent states their position with reasoning
2. The human arbitrates
3. The decision is recorded as an ADR by `@tech-writer`

---

## What Agents Must NEVER Do Without Approval

- Write or modify any file
- Delete any file or directory
- Run `git` commands (commit, push, reset, checkout)
- Execute database migrations
- Deploy infrastructure or services
- Create or rotate secrets/credentials
- Send external API calls (webhooks, notifications)
- Modify CI/CD pipelines

---

## Escalation Triggers

Agents must immediately escalate to the human (stop and ask) when they encounter:

- A security concern (hardcoded secret, SQL injection risk, missing auth)
- A compliance issue (PII in logs, missing audit trail, unencrypted sensitive data)
- A data migration that could cause data loss
- A breaking API change affecting consumers
- Any uncertainty about regulatory impact
