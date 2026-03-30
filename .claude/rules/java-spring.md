# Rules: Java / Spring Boot

**Applies to:** `services/**/*.java`, `services/**/build.gradle.kts`

---

## Language & Framework
- Java 21 — use records, sealed classes, and pattern matching where they improve clarity
- Spring Boot 3.x — do not downgrade APIs to deprecated Boot 2.x patterns
- Gradle Kotlin DSL (`build.gradle.kts`) — no Groovy DSL

## Package Structure (enforced)
```
com.{org}.{service}/
  api/           ← Controllers, DTOs (request/response only — no business logic)
  application/   ← Use cases (orchestrate domain, no JPA, no HTTP)
  domain/        ← Entities, value objects, domain services, repository interfaces (no Spring annotations)
  infrastructure/
    persistence/ ← JPA entities, repositories, mappers
    messaging/   ← Kafka producers, consumers
    external/    ← External HTTP clients
  config/        ← Spring @Configuration classes
```

**Violations that must be flagged:**
- Business logic in a Controller → move to application layer
- JPA annotations in domain classes → move to `infrastructure/persistence/`
- `@Autowired` on fields → use constructor injection only
- `@Transactional` on a repository → move to application service

## Naming Conventions
| Type | Pattern | Example |
|------|---------|---------|
| Controller | `{Entity}Controller` | `PaymentController` |
| Use case | `{Action}{Entity}UseCase` | `ProcessPaymentUseCase` |
| Domain service | `{Entity}DomainService` | `PaymentDomainService` |
| Repository interface | `{Entity}Repository` | `PaymentRepository` |
| JPA entity | `{Entity}Entity` | `PaymentEntity` |
| Request DTO | `{Action}{Entity}Request` | `CreatePaymentRequest` |
| Response DTO | `{Entity}Response` | `PaymentResponse` |

## REST Controllers
- `@RestController` + `@RequestMapping` — always both
- Return `ResponseEntity<T>` explicitly — never return raw objects
- `@Valid` on every `@RequestBody` — no exceptions
- Exception mapping only in `GlobalExceptionHandler` (`@ControllerAdvice`)
- Never return stack traces or internal error details to clients
- RFC 7807 Problem Details format for all error responses

## Transactions
- `@Transactional` belongs on **application service** methods, not repositories
- `@Transactional(readOnly = true)` on all read-only operations
- No HTTP calls, Kafka publishes, or email sends inside a `@Transactional` block

## Null Safety
- Never return `null` from a public method — use `Optional<T>` at API boundaries
- Never pass `null` as a method argument internally — use `Optional` or overloads

## Security
- Every endpoint requires authentication unless annotated with an explicit public exemption comment
- `@PreAuthorize` for method-level authorization
- Never log: JWT tokens, passwords, card numbers, CVV, SSN, account numbers

## Testing
- Unit tests: JUnit 5 + Mockito, no Spring context (`@ExtendWith(MockitoExtension.class)`)
- Integration tests: `@SpringBootTest` + Testcontainers — real PostgreSQL and Kafka
- Test naming: `given{Context}_when{Action}_then{Outcome}`
- Coverage target: ≥ 80% on `domain/` and `application/` layers
