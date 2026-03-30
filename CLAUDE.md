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

### Planning Agents
| Agent | Role |
|---|---|
| `@product-manager` | Requirements, user stories, acceptance criteria, compliance impact |
| `@project-manager` | Sprints, priorities, milestones, blockers, dependency tracking |
| `@system-architect` | System design, ADRs, microservice boundaries, event topology |

### Design Agents
| Agent | Role |
|---|---|
| `@ux-designer` | React component specs, user flows, accessibility (WCAG 2.1) |
| `@api-designer` | REST contracts, OpenAPI specs, versioning strategy |
| `@db-designer` | PostgreSQL schema, Flyway migrations, indexing, partitioning |
| `@event-designer` | Kafka topic design, Avro/JSON schemas, event contracts |

### Development Agents
| Agent | Role |
|---|---|
| `@frontend-dev` | React components, TypeScript, state management, unit tests |
| `@backend-dev` | Spring Boot services, JPA/repositories, business logic |
| `@integration-dev` | Kafka producers/consumers, async flows, retries, DLQ |
| `@infra-engineer` | AWS CDK/Terraform, Docker Compose, LocalStack, CI/CD |
| `@security-engineer` | Auth (OAuth2/JWT), encryption, secrets, vuln scanning |

### Quality Agents
| Agent | Role |
|---|---|
| `@qa-engineer` | Test plans, exploratory testing, **runs Playwright E2E suite**, E2E sign-off (Definition of Done gate) |
| `@test-automator` | JUnit 5, Testcontainers, Playwright test authoring, contract tests |
| `@code-reviewer` | PR reviews, standards enforcement, security flags |
| `@compliance-auditor` | PCI-DSS, GDPR, audit logging, regulatory gap analysis |

### Documentation Agents
| Agent | Role |
|---|---|
| `@tech-writer` | README, runbooks, ADRs, changelogs |
| `@api-documenter` | OpenAPI/Swagger, Postman collections, integration guides |

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

## Coding Standards

@.claude/docs/coding-standards.md

## Technical Preferences

@.claude/docs/tech-preferences.md

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
