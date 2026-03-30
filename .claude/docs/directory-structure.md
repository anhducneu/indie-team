# Directory Structure

## Monorepo Layout (recommended for fintech teams)

```
{project-root}/
├── .claude/                        ← Claude agent configuration
│   ├── docs/                       ← Agent reference docs (this directory)
│   └── commands/                   ← Slash command definitions
│
├── services/                       ← Backend microservices
│   ├── {service-name}/             ← One directory per Spring Boot service
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── java/com/{org}/{service}/
│   │   │   │   │   ├── api/              ← Controllers, DTOs
│   │   │   │   │   ├── application/      ← Use cases
│   │   │   │   │   ├── domain/           ← Entities, value objects, interfaces
│   │   │   │   │   ├── infrastructure/   ← JPA, Kafka, external clients
│   │   │   │   │   └── config/           ← Spring config
│   │   │   │   └── resources/
│   │   │   │       ├── application.yml
│   │   │   │       ├── application-local.yml
│   │   │   │       └── db/migration/     ← Flyway SQL migrations
│   │   │   └── test/
│   │   │       └── java/com/{org}/{service}/
│   │   │           ├── unit/             ← Pure unit tests
│   │   │           ├── integration/      ← Testcontainers-based tests
│   │   │           └── contract/         ← Contract tests (Pact)
│   │   ├── build.gradle.kts
│   │   └── Dockerfile
│   │
│   └── ... (more services)
│
├── frontend/                       ← React application(s)
│   ├── src/
│   │   ├── components/             ← Reusable UI components
│   │   ├── pages/                  ← Route-level pages
│   │   ├── features/               ← Feature-scoped components + logic
│   │   ├── hooks/                  ← Custom React hooks
│   │   ├── services/               ← API client functions
│   │   ├── store/                  ← Global state (Zustand / Redux Toolkit)
│   │   ├── types/                  ← Shared TypeScript interfaces
│   │   ├── utils/                  ← Pure utility functions
│   │   └── main.tsx
│   ├── public/
│   ├── e2e/                        ← Playwright E2E tests
│   ├── index.html
│   ├── vite.config.ts
│   ├── tsconfig.json
│   └── Dockerfile
│
├── infrastructure/                 ← AWS CDK stacks
│   ├── bin/
│   │   └── app.ts                  ← CDK entry point
│   ├── lib/
│   │   ├── stacks/                 ← One stack file per logical grouping
│   │   │   ├── network-stack.ts    ← VPC, subnets, security groups
│   │   │   ├── data-stack.ts       ← RDS, MSK, ElastiCache
│   │   │   └── service-stack.ts    ← ECS services, ALB, task definitions
│   │   └── constructs/             ← Reusable CDK constructs
│   ├── package.json
│   └── cdk.json
│
├── schemas/                        ← Shared event & API schemas
│   ├── kafka/                      ← Avro schema files (.avsc)
│   │   └── {domain}/
│   │       └── {entity}-{event}.avsc
│   └── openapi/                    ← OpenAPI spec files
│       └── {service}-api.yaml
│
├── docs/                           ← Project documentation
│   ├── adr/                        ← Architecture Decision Records
│   │   └── ADR-001-use-kafka-for-events.md
│   ├── runbooks/                   ← Operational runbooks
│   └── architecture/               ← Diagrams, C4 models
│
├── docker-compose.yml              ← Local development environment
├── docker-compose.override.yml     ← Local overrides (gitignored)
├── .env.example                    ← Environment variable template (no secrets)
├── Makefile                        ← Common developer tasks
├── CLAUDE.md                       ← Agent manifest (this project)
└── README.md
```

---

## Service Naming Convention

```
{domain}-service         ← e.g., payment-service, account-service, notification-service
{domain}-processor       ← Kafka consumer / batch processor
{domain}-gateway         ← API Gateway / BFF
```

---

## Flyway Migration Naming

```
V{n}__{description}.sql
```

| File | Purpose |
|---|---|
| `V1__create_initial_schema.sql` | Baseline schema |
| `V2__add_accounts_table.sql` | New table |
| `V3__add_idempotency_key_to_payments.sql` | Column addition |
| `V4__create_idx_payments_account_id.sql` | Index addition |

Rules:
- Version numbers are sequential and never reused
- Description uses underscores, lowercase
- One logical change per migration
- Rollback scripts in `db/rollback/` (manual, not auto-applied)

---

## ADR Naming

```
ADR-{nnn}-{short-title}.md
```

Examples:
- `ADR-001-monorepo-structure.md`
- `ADR-002-kafka-for-domain-events.md`
- `ADR-003-cdk-over-terraform.md`

---

## Makefile Targets (standard across all services)

```makefile
make build          # Build all services
make test           # Run all tests
make test-unit      # Run unit tests only
make test-integration # Run integration tests (requires Docker)
make lint           # Run linters
make local-up       # Start local Docker Compose environment
make local-down     # Stop local Docker Compose environment
make migrate        # Run Flyway migrations against local DB
make deploy-dev     # Deploy to dev environment (requires approval)
```
