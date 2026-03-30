# Coordination Rules

## Agent Ownership Matrix

Each agent owns a domain and is the single authority for decisions within it. Cross-domain changes require both owners to agree.

| Domain | Owner Agent | Consults |
|---|---|---|
| Product requirements | `@product-manager` | `@compliance-auditor` |
| Sprint & delivery | `@project-manager` | `@product-manager` |
| System architecture | `@system-architect` | all dev agents |
| UI/UX | `@ux-designer` | `@frontend-dev` |
| REST API contracts | `@api-designer` | `@backend-dev`, `@system-architect` |
| Database schema | `@db-designer` | `@backend-dev`, `@compliance-auditor` |
| Kafka event schema | `@event-designer` | `@integration-dev`, `@system-architect` |
| React frontend | `@frontend-dev` | `@ux-designer`, `@test-automator` |
| Spring backend | `@backend-dev` | `@api-designer`, `@db-designer` |
| Kafka integration | `@integration-dev` | `@event-designer`, `@backend-dev` |
| AWS / infra | `@infra-engineer` | `@security-engineer` |
| Security posture | `@security-engineer` | `@compliance-auditor`, `@infra-engineer` |
| Test strategy | `@qa-engineer` | `@product-manager` |
| Test implementation | `@test-automator` | `@qa-engineer`, `@backend-dev`, `@frontend-dev` |
| PR / code quality | `@code-reviewer` | all dev agents |
| Regulatory compliance | `@compliance-auditor` | `@security-engineer`, `@product-manager` |
| Docs & runbooks | `@tech-writer` | all agents |
| API docs | `@api-documenter` | `@api-designer`, `@backend-dev` |

---

## Definition of Done

A feature is **NOT done** until every item in this checklist is met. No exceptions.

### Code
- [ ] Implementation reviewed and approved by `@code-reviewer`
- [ ] Security review completed by `@security-engineer`
- [ ] No HIGH or CRITICAL vulnerabilities in dependency scan

### Tests — all must PASS, not just exist
- [ ] **Unit tests** pass (`make test-unit`) — coverage ≥ 80% on domain + application layers
- [ ] **Integration tests** pass (`make test-integration`) — Testcontainers (PostgreSQL, Redis)
- [ ] **E2E tests** pass (`make test-e2e`) — Playwright suite run by `@qa-engineer` against a running service
  - `@qa-engineer` is the **sole authority** to sign off E2E test results
  - E2E tests must be run against the feature branch deployed locally (`make local-up`)
  - Any skipped E2E test must have a documented reason and a follow-up ticket
  - A FAILED E2E test blocks the feature — no exceptions, no bypasses

### Compliance & Docs
- [ ] `@compliance-auditor` final sign-off
- [ ] API docs updated (`@api-documenter`)
- [ ] README / runbook updated (`@tech-writer`)
- [ ] ADR written if architectural decision was made (`@tech-writer`)

---

## Feature Development Flow

A feature moves through agents in this order:

```
@product-manager      → Define requirements & acceptance criteria
       ↓
@compliance-auditor   → Flag regulatory requirements early
       ↓
@system-architect     → Design system changes & ADR if needed
       ↓
@api-designer         → Define API contract (if new endpoint)
@db-designer          → Define schema changes (if needed)
@event-designer       → Define event schema (if async)
       ↓
@ux-designer          → Define UI/UX (if frontend involved)
       ↓
@backend-dev          → Implement services, repositories, controllers
@frontend-dev         → Implement React components, pages
@integration-dev      → Implement Kafka producers/consumers
       ↓
@test-automator       → Write unit tests, integration tests, Playwright E2E tests
       ↓
@code-reviewer        → Review all changes
@security-engineer    → Security review (auth, input validation, secrets)
       ↓
@qa-engineer          → Run Playwright E2E suite against running service
                         ✓ All tests PASS  → sign off
                         ✗ Any test FAILS  → file bug, block feature, return to dev
       ↓
@compliance-auditor   → Final compliance sign-off
       ↓
@infra-engineer       → Deployment (after human approval)
       ↓
@tech-writer          → Update docs, changelog, runbook
```

Not all features touch all agents. Skip agents whose domain is not affected.

---

## Parallel Work Rules

Agents may work in parallel only when their outputs are independent:
- `@frontend-dev` and `@backend-dev` may work in parallel once API contract is agreed
- `@test-automator` may write test stubs in parallel with implementation
- `@tech-writer` may draft docs in parallel with implementation

Agents may NOT work in parallel when there is a dependency:
- `@backend-dev` must not implement before `@api-designer` finalizes the contract
- `@db-designer` must not finalize schema before `@compliance-auditor` reviews PII fields
- `@infra-engineer` must not deploy before `@security-engineer` signs off

---

## Bug Fix Flow

```
@qa-engineer          → Reproduce, document, severity assessment
       ↓
@system-architect     → Root cause analysis (if architectural)
       ↓
@backend-dev / @frontend-dev / @integration-dev  → Fix
       ↓
@test-automator       → Add regression test
       ↓
@code-reviewer        → Review fix
       ↓
@infra-engineer       → Hotfix deploy (after human approval)
```

---

## ADR (Architecture Decision Record) Triggers

`@system-architect` must produce an ADR (recorded by `@tech-writer`) whenever:
- A new service or microservice is introduced
- A technology is added or replaced
- An existing API contract has a breaking change
- A database schema change affects existing data
- An event schema change affects existing consumers
- A security model changes (e.g., new auth flow)

---

## Escalation Paths

| Situation | Escalate to |
|---|---|
| Security vulnerability found | `@security-engineer` → human immediately |
| Compliance gap found | `@compliance-auditor` → human immediately |
| Architectural conflict | `@system-architect` arbitrates, human decides |
| Scope creep detected | `@project-manager` → human |
| Test failure blocking release | `@qa-engineer` → `@project-manager` → human |
| Data loss risk in migration | `@db-designer` → human immediately |
