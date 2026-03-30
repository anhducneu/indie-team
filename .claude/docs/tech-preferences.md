# Technical Preferences

## Backend — Spring Boot

| Concern | Preferred Choice | Notes |
|---|---|---|
| Java version | Java 21 | Use virtual threads where applicable |
| Build tool | Gradle (Kotlin DSL) | `build.gradle.kts` |
| ORM | Spring Data JPA + Hibernate | Use native queries only when necessary |
| DB migrations | Liquibase | `classpath:db/changelog/db.changelog-master.yaml` |
| Validation | Jakarta Validation (Bean Validation 3) | `@Valid` on controllers |
| HTTP client | Spring WebClient (reactive) | For external API calls |
| JSON | Jackson | Configure to fail on unknown properties |
| Logging | SLF4J + Logback | JSON log format in non-local envs |
| Tracing | Micrometer + OTLP (OpenTelemetry) | Propagate `traceId` in all logs |
| API docs | Springdoc OpenAPI 3 | Auto-generate from annotations |
| Auth | Spring Security + OAuth2 Resource Server | JWT validation |
| Feature flags | AWS AppConfig (via LocalStack locally) | No hardcoded toggles |
| Caching | Spring Cache + Redis (AWS ElastiCache) | Cache read-heavy domain lookups |
| Retry | Spring Retry or Resilience4j | Circuit breaker on external calls |

## Frontend — React

| Concern | Preferred Choice | Notes |
|---|---|---|
| Build tool | Vite | Fast dev server + optimized builds |
| Language | TypeScript (strict) | `tsconfig` strict mode on |
| Routing | React Router v6 | `createBrowserRouter` API |
| Server state | TanStack Query (React Query v5) | Caching, refetch, error handling |
| Global state | Zustand | Lightweight; Redux Toolkit for complex cases |
| Forms | React Hook Form + Zod | Schema-based validation |
| UI components | shadcn/ui + Tailwind CSS | Component primitives, no opinionated design system lock-in |
| HTTP client | Axios | Interceptors for auth headers, error normalization |
| API mocking | MSW (Mock Service Worker) | For dev and tests |
| Testing | Vitest + React Testing Library | Unit/component tests |
| E2E testing | Playwright | Full user flows |
| Lint | ESLint + Prettier | Enforced in CI |
| i18n | react-i18next | Prepare for multi-language from day one |

## Database — PostgreSQL

| Concern | Preferred Choice | Notes |
|---|---|---|
| Version | PostgreSQL 16 | |
| UUID generation | `gen_random_uuid()` | Built-in, no extension needed |
| Full-text search | `pg_trgm` + GIN index | For search features |
| Connection pool | HikariCP (Spring default) | Tune pool size per service |
| Read replicas | AWS RDS read replicas | Route read-only queries |
| Backups | AWS RDS automated snapshots | 7-day retention minimum |
| Encryption | AWS RDS encryption at rest + TLS in transit | Non-negotiable |

## Messaging — Kafka

| Concern | Preferred Choice | Notes |
|---|---|---|
| Managed service | AWS MSK (local: Confluent Docker) | |
| Schema registry | Confluent Schema Registry | Avro schemas |
| Client library | `spring-kafka` | |
| Serialization | Avro (production) / JSON (prototyping) | Avro preferred for schema evolution |
| Consumer groups | `{service-name}-consumer-group` | One group per service |
| DLQ pattern | Separate DLQ topic per consumer | `{topic}.dlq` |
| Monitoring | Kafka UI (local) / AWS CloudWatch MSK metrics | |

## AWS Services

| Service | Usage |
|---|---|
| ECS Fargate | Container hosting (prefer over EC2 for simplicity) |
| RDS PostgreSQL | Managed database |
| MSK | Managed Kafka |
| S3 | File storage, event archives, static assets |
| SQS | Simple queues (when Kafka is overkill) |
| Secrets Manager | All credentials and secrets |
| Parameter Store | Non-sensitive config values |
| CloudWatch | Logs, metrics, alarms |
| X-Ray | Distributed tracing |
| WAF | Web application firewall (on API Gateway / ALB) |
| KMS | Encryption key management |
| VPC | All services in private subnets; NAT for egress |

## Infrastructure as Code

| Concern | Preferred Choice |
|---|---|
| IaC tool | AWS CDK (TypeScript) |
| State management | N/A (CDK uses CloudFormation) |
| Environments | `dev`, `staging`, `prod` stacks |
| Secrets in IaC | Never hardcoded — reference Secrets Manager ARNs |

## Local Development

| Concern | Preferred Choice |
|---|---|
| AWS simulation | LocalStack Pro (or Community for basic needs) |
| Kafka (local) | `confluentinc/cp-kafka` via Docker Compose |
| DB (local) | PostgreSQL via Docker Compose |
| Secrets (local) | LocalStack Secrets Manager |
| Dev tooling | `make` targets for common tasks |
| Hot reload | Spring DevTools (backend) + Vite HMR (frontend) |

## CI/CD

| Concern | Preferred Choice |
|---|---|
| Pipeline | GitHub Actions |
| Container registry | AWS ECR |
| Deploy strategy | Rolling update (ECS), Blue/Green for prod |
| Quality gates | Tests pass + coverage ≥ 80% + no HIGH/CRITICAL vulns |
| Security scan | OWASP Dependency-Check + Trivy (container scan) |
| Secrets in CI | GitHub Secrets → injected as env vars |

## Observability

| Concern | Preferred Choice |
|---|---|
| Logs | Structured JSON → CloudWatch Logs |
| Metrics | Micrometer → CloudWatch Metrics |
| Tracing | OpenTelemetry → AWS X-Ray |
| Alerting | CloudWatch Alarms → SNS → PagerDuty/Slack |
| Dashboards | CloudWatch Dashboards or Grafana (managed) |

**Log fields standard (every log line):**
```json
{
  "timestamp": "ISO-8601",
  "level": "INFO",
  "service": "payment-service",
  "traceId": "...",
  "spanId": "...",
  "userId": "masked-or-omitted",
  "message": "...",
  "duration_ms": 42
}
```
