# Indie Dev Team — Fintech Software Development Agent Architecture

**A full software development team managed through coordinated Claude Code agents. Each agent owns a specific domain across the entire SDLC, enforcing separation of concerns, quality, and regulatory compliance.**

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | React 18+, TypeScript, Vite |
| **Backend** | Spring Boot 3.x, Java 21 |
| **Database** | PostgreSQL 16 |
| **Messaging** | Apache Kafka |
| **Cloud** | AWS (ECS, RDS, MSK, S3, Secrets Manager, SQS) |
| **Local Cloud** | LocalStack |
| **Containers** | Docker, Docker Compose |
| **IaC** | AWS CDK (TypeScript) or Terraform |

---

## Domain Focus

**Fintech / Banking** — All agents apply regulatory awareness:
- PCI-DSS compliance for card/payment data
- GDPR / data privacy for personal data
- SOC 2 logging and audit trail requirements
- Zero-trust security posture
- No secrets in code or logs, ever

---

## Agent Roster

Each agent has a dedicated definition file in `agents/` with full role, authority, responsibilities, escalation paths, and output format.

### Planning Agents
| Agent | Definition | Role |
|---|---|---|
| `@product-manager` | [agents/product-manager.md](.claude/agents/product-manager.md) | Requirements, user stories, acceptance criteria, compliance impact |
| `@project-manager` | [agents/project-manager.md](.claude/agents/project-manager.md) | Sprints, priorities, milestones, blockers, dependency tracking |
| `@system-architect` | [agents/system-architect.md](.claude/agents/system-architect.md) | System design, ADRs, microservice boundaries, event topology |

### Design Agents
| Agent | Definition | Role |
|---|---|---|
| `@ux-designer` | [agents/ux-designer.md](.claude/agents/ux-designer.md) | React component specs, user flows, accessibility (WCAG 2.1) |
| `@api-designer` | [agents/api-designer.md](.claude/agents/api-designer.md) | REST contracts, OpenAPI specs, versioning strategy |
| `@db-designer` | [agents/db-designer.md](.claude/agents/db-designer.md) | PostgreSQL schema, Flyway migrations, indexing, partitioning |
| `@event-designer` | [agents/event-designer.md](.claude/agents/event-designer.md) | Kafka topic design, Avro/JSON schemas, event contracts |

### Development Agents
| Agent | Definition | Role |
|---|---|---|
| `@frontend-dev` | [agents/frontend-dev.md](.claude/agents/frontend-dev.md) | React components, TypeScript, state management, unit tests |
| `@backend-dev` | [agents/backend-dev.md](.claude/agents/backend-dev.md) | Spring Boot services, JPA/repositories, business logic |
| `@integration-dev` | [agents/integration-dev.md](.claude/agents/integration-dev.md) | Kafka producers/consumers, async flows, retries, DLQ |
| `@infra-engineer` | [agents/infra-engineer.md](.claude/agents/infra-engineer.md) | AWS CDK/Terraform, Docker Compose, LocalStack, CI/CD |
| `@security-engineer` | [agents/security-engineer.md](.claude/agents/security-engineer.md) | Auth (OAuth2/JWT), encryption, secrets, vuln scanning |

### Quality Agents
| Agent | Definition | Role |
|---|---|---|
| `@qa-engineer` | [agents/qa-engineer.md](.claude/agents/qa-engineer.md) | Test plans, exploratory testing, **runs Playwright E2E suite**, E2E sign-off (Definition of Done gate) |
| `@test-automator` | [agents/test-automator.md](.claude/agents/test-automator.md) | JUnit 5, Testcontainers, Playwright test authoring, contract tests |
| `@code-reviewer` | [agents/code-reviewer.md](.claude/agents/code-reviewer.md) | PR reviews, standards enforcement, security flags |
| `@compliance-auditor` | [agents/compliance-auditor.md](.claude/agents/compliance-auditor.md) | PCI-DSS, GDPR, audit logging, regulatory gap analysis |

### Documentation Agents
| Agent | Definition | Role |
|---|---|---|
| `@tech-writer` | [agents/tech-writer.md](.claude/agents/tech-writer.md) | README, runbooks, ADRs, changelogs |
| `@api-documenter` | [agents/api-documenter.md](.claude/agents/api-documenter.md) | OpenAPI/Swagger, Postman collections, integration guides |

---

## Collaboration Protocol

**Human approval is required at every gate. Agents do not act autonomously.**

Full protocol: @.claude/docs/collaboration-protocol.md

**Workflow for every task:**
```
Question → Options → Decision → Draft → Human Approval → Execute
```

**Hard rules:**
- Agents MUST ask `"May I write this to [filepath]?"` before any Write/Edit
- Agents MUST show a full draft or summary before requesting approval
- Multi-file changes require explicit approval for the **full changeset** listed upfront
- No `git commit`, `git push`, or deployments without explicit user instruction
- No secrets, credentials, or PII written to any file under any circumstances

---

## Coordination Rules

@.claude/docs/coordination-rules.md

## Path-Scoped Coding Rules

Apply the rule file that matches the files you are working with. Load only the relevant file — do not load all rules for every task.

| Files | Rules |
|---|---|
| `services/**/*.java` | @rules/java-spring.md |
| `frontend/**/*.{ts,tsx}` | @rules/react-typescript.md |
| `services/**/db/migration/*.sql` | @rules/sql-migrations.md |
| `services/**/infrastructure/messaging/**`, `schemas/kafka/**` | @rules/kafka-events.md |
| `infrastructure/**/*.ts` | @rules/cdk-infra.md |
| `**/Dockerfile`, `docker-compose*.yml` | @rules/docker.md |

Full general standards (applies when no path-scoped rule covers the file):

@.claude/docs/coding-standards.md

## Technical Preferences

@.claude/docs/tech-preferences.md

## Automated Hooks

The following hooks run automatically to enforce quality and security:

| Hook | Trigger | Purpose |
|---|---|---|
| `session-start.sh` | Session start | Print agent roster, branch context, compliance reminders |
| `validate-write.sh` | Before Write/Edit | Scan for hardcoded secrets, PII in logs, SQL injection risk |
| `validate-commit.sh` | Before `git commit` | Check commit message format, scan staged diff for secrets |
| `validate-push.sh` | Before `git push` | Branch protection, secrets scan, test gate reminder |

Hook scripts: `.claude/hooks/` | Configuration: `.claude/settings.json`

## Directory Structure

@.claude/docs/directory-structure.md

---

## Slash Commands

| Command | Description |
|---|---|
| `/start` | Onboard a new project — define name, services, domain model |
| `/plan` | Kick off a feature — from requirements to task breakdown |
| `/review` | Trigger a code review pass on staged/recent changes |
| `/deploy` | Run the release/deploy checklist |
| `/standup` | Generate a status summary across active work |
| `/audit` | Run compliance and security audit checklist |

---

> **First session on a new project?** Run `/start` to begin the guided onboarding flow.
