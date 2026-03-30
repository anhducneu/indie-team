# Coding Standards

## General Principles

- Clarity over cleverness — code is read more than it is written
- Explicit over implicit — no magic, no hidden side effects
- Fail fast — validate inputs at system boundaries, return errors early
- No secrets in code — all credentials via environment variables or AWS Secrets Manager
- No PII in logs — mask or omit sensitive fields (card numbers, SSN, account numbers)

---

## Java / Spring Boot

### Version & Style
- Java 21 (use records, sealed classes, pattern matching where appropriate)
- Spring Boot 3.x
- Follow Google Java Style Guide
- Use `final` for fields that don't change
- Avoid `null` — use `Optional<T>` at API boundaries, never pass null internally

### Package Structure
```
com.{org}.{service}/
  api/           ← Controllers, DTOs (request/response)
  application/   ← Use cases / application services
  domain/        ← Entities, value objects, domain services, repository interfaces
  infrastructure/
    persistence/  ← JPA entities, repositories, mappers
    messaging/    ← Kafka producers, consumers
    external/     ← External API clients
  config/        ← Spring configuration classes
```

### Naming
- Controllers: `PaymentController`, `AccountController`
- Services (application): `ProcessPaymentUseCase`, `GetAccountBalanceUseCase`
- Domain services: `PaymentDomainService`
- Repositories (interface): `PaymentRepository`
- JPA entities: `PaymentEntity` (suffix Entity to distinguish from domain model)
- DTOs: `CreatePaymentRequest`, `PaymentResponse`

### REST Controllers
- Use `@RestController` + `@RequestMapping`
- Return `ResponseEntity<T>` explicitly
- Validate all inputs with `@Valid` + Bean Validation annotations
- Use `@ExceptionHandler` in `@ControllerAdvice` for error mapping
- Never return stack traces to clients

### Error Handling
- Define domain exceptions: `PaymentNotFoundException`, `InsufficientFundsException`
- Map to HTTP status in a single `GlobalExceptionHandler`
- Return RFC 7807 Problem Details format:
```json
{
  "type": "https://api.yourbank.com/errors/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 400,
  "detail": "Account balance is below the required amount.",
  "traceId": "abc-123"
}
```

### Security
- Every endpoint requires authentication unless explicitly exempted
- Use method-level `@PreAuthorize` for authorization
- Never log JWT tokens, passwords, or card data
- Validate and sanitize all external inputs

### Transactions
- `@Transactional` on application service methods, not repositories
- Keep transactions short — no external calls (HTTP, Kafka publish) inside `@Transactional`
- Use `@Transactional(readOnly = true)` for read operations

### Testing
- Unit tests with JUnit 5 + Mockito
- Integration tests with `@SpringBootTest` + Testcontainers (PostgreSQL, Kafka)
- Test naming: `givenValidPayment_whenProcessed_thenShouldSaveAndPublishEvent`
- Aim for 80%+ coverage on domain and application layers

---

## React / TypeScript

### Version & Style
- React 18+, TypeScript (strict mode enabled)
- Follow Airbnb TypeScript Style Guide
- No `any` type — ever. Use `unknown` + type guards if needed
- Functional components only — no class components
- `const` for all component declarations

### Component Structure
```
src/
  components/       ← Reusable, stateless UI components
  pages/            ← Route-level page components
  features/         ← Feature-scoped components + logic
  hooks/            ← Custom React hooks
  services/         ← API client calls (Axios/Fetch wrappers)
  store/            ← State management (Redux Toolkit / Zustand)
  types/            ← Shared TypeScript types/interfaces
  utils/            ← Pure utility functions
```

### Naming
- Components: PascalCase — `PaymentForm`, `AccountSummaryCard`
- Hooks: camelCase with `use` prefix — `usePaymentSubmit`, `useAccountBalance`
- Files match component name: `PaymentForm.tsx`, `usePaymentSubmit.ts`

### State Management
- Local UI state: `useState` / `useReducer`
- Server state: React Query (TanStack Query)
- Global app state: Redux Toolkit (for auth, session) or Zustand (lightweight)
- No prop drilling beyond 2 levels — use context or state management

### API Calls
- All API calls go through typed service functions in `src/services/`
- Never call `fetch`/`axios` directly in components
- Handle loading, error, and empty states explicitly in every component
- Mask sensitive data before displaying (e.g., show only last 4 digits of card)

### Accessibility
- All interactive elements must be keyboard-navigable
- Use semantic HTML (`<button>`, `<nav>`, `<main>`, `<section>`)
- ARIA labels on icon-only buttons
- WCAG 2.1 AA compliance minimum

### Testing
- Unit tests: Vitest + React Testing Library
- E2E tests: Playwright
- Test user-visible behavior, not implementation details
- Mock API calls at the network layer (MSW — Mock Service Worker)

---

## PostgreSQL

### Naming Conventions
- Tables: `snake_case`, plural — `payments`, `accounts`, `audit_logs`
- Columns: `snake_case` — `created_at`, `account_id`, `idempotency_key`
- Indexes: `idx_{table}_{columns}` — `idx_payments_account_id`
- Foreign keys: `fk_{table}_{ref_table}` — `fk_payments_accounts`
- Primary keys: `id` (UUID preferred for distributed systems)

### Required Columns (all tables)
```sql
id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
version      BIGINT NOT NULL DEFAULT 0  -- optimistic locking
```

### Data Rules
- Use `TIMESTAMPTZ` (not `TIMESTAMP`) — always store UTC
- Store monetary amounts as `BIGINT` (cents/minor units) — never `FLOAT` or `DECIMAL` for money
- Use `TEXT` instead of `VARCHAR(n)` unless a length constraint is a business rule
- Sensitive PII fields must be encrypted at rest (application-level AES-256 or AWS RDS encryption)
- Soft deletes: add `deleted_at TIMESTAMPTZ` — never `DELETE` financial records

### Migrations
- Use Liquibase (YAML format)
- Changelog files: `services/{name}/src/main/resources/db/changelog/changes/{nnn}-{description}.yaml`
- Master changelog: `db/changelog/db.changelog-master.yaml` includes all changesets in order
- Every YAML changeset requires: `id`, `author: db-designer`, `comment`, `labels`, `changes`, and `rollback`
- Changesets must be backward-compatible with the previous deployed version
- No DDL inside application code — schema changes only via changelog files
- Every changeset must be reviewed by `@db-designer` and `@compliance-auditor`

---

## Kafka

### Topic Naming
```
{env}.{domain}.{entity}.{event-type}
```
Examples:
- `prod.payments.payment.created`
- `prod.accounts.account.balance-updated`
- `prod.notifications.alert.triggered`

### Schema
- Use JSON Schema (simple) or Avro (preferred for evolution)
- All events include a standard envelope:
```json
{
  "eventId": "uuid",
  "eventType": "payment.created",
  "eventVersion": "1.0",
  "occurredAt": "2026-03-28T10:00:00Z",
  "correlationId": "uuid",
  "payload": { ... }
}
```
- Event schemas are owned by `@event-designer` and versioned
- Breaking schema changes require a new topic version (e.g., `.v2`)

### Producers
- Always set `idempotence=true`
- Use transactional producers for exactly-once semantics when required
- Include `correlationId` and `traceId` in message headers

### Consumers
- Always implement idempotent consumers — the same message may be delivered more than once
- Use Dead Letter Queue (DLQ) pattern for failed messages
- Log failed messages with full context, excluding PII
- Commit offsets only after successful processing

---

## Docker / LocalStack

### Docker Compose (local dev)
- All services defined in `docker-compose.yml` at project root
- Use `.env` file for local config — never commit `.env` with real values
- LocalStack simulates: S3, SQS, SNS, Secrets Manager, SES
- Kafka + Zookeeper (or KRaft) via Confluent images

### Environment Parity
- Local environment must mirror AWS architecture as closely as possible via LocalStack
- Feature flags and config managed via AWS Secrets Manager locally (LocalStack) and in prod (real AWS)

---

## Security Non-Negotiables

1. No hardcoded secrets, API keys, passwords — use env vars or Secrets Manager
2. No logging of PII, card numbers, account numbers, passwords, tokens
3. All HTTP endpoints require auth (OAuth2/JWT) unless explicitly public
4. All DB queries use parameterized statements — no string concatenation in SQL
5. Input validation on every API endpoint (`@Valid`, `@NotNull`, `@Size`, etc.)
6. HTTPS everywhere — no plain HTTP in any environment including local
7. Dependency scanning in CI (OWASP Dependency-Check or Snyk)
8. Secrets rotation supported — no long-lived static credentials
