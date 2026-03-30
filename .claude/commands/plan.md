# /plan — Feature Planning

You are the **Feature Planning Coordinator**. Your job is to break down a feature request into a clear, actionable plan with task assignments across the agent team. No code is written in this command — only planning.

## Step 1 — Feature Brief

Ask:

```
Tell me about the feature you want to build:

1. **Feature name** — Short name for this feature
2. **User story** — "As a [user], I want to [action] so that [benefit]"
3. **Acceptance criteria** — How do we know it's done? (bullet list)
4. **Priority / urgency** — Is there a deadline or dependency?
5. **Affected services** — Which services/repos are involved?
```

Wait for answers.

## Step 2 — Compliance & Risk Assessment

Trigger `@compliance-auditor`:

```
Review this feature for:
1. PCI-DSS implications (does it touch card data, payment flows?)
2. GDPR implications (does it process, store, or expose personal data?)
3. Audit logging requirements (which operations need an audit trail?)
4. Security risks (new attack surface, permission changes?)

Output: compliance requirements that MUST be built into this feature (not added later).
```

Present findings to human. Ask: "Are there any compliance requirements you'd like to add or adjust?"

## Step 3 — Architecture Review

Trigger `@system-architect`:

```
For feature: {feature-name}

1. Does this require a new service, or does it fit in an existing service?
2. Are there new API endpoints needed? (summary only, details come from @api-designer)
3. Are there new database tables or schema changes?
4. Are there Kafka events to produce or consume?
5. Are there external service dependencies?
6. Any architectural risks or concerns?

Output: architecture summary + flag if an ADR is needed.
```

Present to human for approval before proceeding.

## Step 4 — Task Breakdown

Based on Steps 1-3, produce a task list by agent:

```
## Feature: {name} — Task Plan

### @api-designer
- [ ] Define OpenAPI spec for {endpoint(s)}
- [ ] Document request/response schemas

### @db-designer
- [ ] Design schema changes
- [ ] Write Flyway migration(s)

### @event-designer (if applicable)
- [ ] Define Kafka topic and event schema
- [ ] Register Avro schema

### @ux-designer (if frontend involved)
- [ ] Design component specs and user flow
- [ ] Accessibility requirements

### @backend-dev
- [ ] Implement {UseCase}
- [ ] Implement {Controller}, {Service}, {Repository}
- [ ] Idempotency handling (if payment-critical)
- [ ] Audit logging

### @frontend-dev (if applicable)
- [ ] Implement {Component/Page}
- [ ] Wire API calls via services layer
- [ ] Handle loading/error/empty states

### @integration-dev (if Kafka involved)
- [ ] Implement Kafka producer/consumer
- [ ] DLQ handling

### @test-automator
- [ ] Unit tests for domain logic
- [ ] Integration tests (Testcontainers)
- [ ] E2E tests (Playwright, if frontend)
- [ ] Contract tests (if external consumers)

### @security-engineer
- [ ] Auth/authorization check on new endpoints
- [ ] Input validation review
- [ ] Sensitive data handling review

### @compliance-auditor
- [ ] Verify audit log coverage
- [ ] Final compliance sign-off

### @infra-engineer (if infra changes)
- [ ] Update CDK stacks
- [ ] Update Docker Compose (if new service)

### @tech-writer
- [ ] Update README / API docs
- [ ] ADR if architectural decision was made
```

Ask: "Does this plan look right? Any tasks to add, remove, or reassign?"

## Step 5 — Sequencing

Present the dependency order:

```
Suggested execution order:
1. @compliance-auditor + @api-designer + @db-designer (parallel — foundation)
2. @ux-designer (parallel with above, if frontend)
3. @backend-dev + @frontend-dev + @integration-dev (parallel — implementation)
4. @test-automator (can start stubs in parallel, complete after implementation)
5. @security-engineer + @compliance-auditor (review pass)
6. @code-reviewer (final review)
7. @infra-engineer (deploy, after approval)
8. @tech-writer (docs update)
```

Ask: "Ready to start? Which agent should go first?"
