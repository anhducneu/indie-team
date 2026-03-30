# Rules: Kafka Events

**Applies to:** `services/**/infrastructure/messaging/**/*.java`, `schemas/kafka/**/*.avsc`

---

## Topic Naming
```
{env}.{domain}.{entity}.{event-type}
```

| Segment | Values | Example |
|---------|--------|---------|
| env | `local`, `dev`, `staging`, `prod` | `prod` |
| domain | business domain | `payments`, `accounts` |
| entity | the thing that changed | `payment`, `account` |
| event-type | past-tense action | `created`, `updated`, `failed` |

Full example: `prod.payments.payment.created`

DLQ topic: append `.dlq` — `prod.payments.payment.created.dlq`
Versioned topic: append `.v2` for breaking schema changes — `prod.payments.payment.created.v2`

## Event Envelope (required on every event)
```json
{
  "eventId": "uuid — unique per event instance",
  "eventType": "payment.created",
  "eventVersion": "1.0",
  "occurredAt": "ISO-8601 UTC timestamp",
  "correlationId": "uuid — trace across services",
  "payload": { }
}
```

## Schema Rules
- Use **Avro** in production — JSON only for prototyping
- Register all schemas in Confluent Schema Registry
- Compatibility mode: `BACKWARD` by default (new consumers can read old messages)
- Breaking changes require a new topic version (`.v2`) — never modify an existing schema destructively

### Non-breaking changes (allowed on existing topic)
- Add an optional field with a default value
- Add a new enum value (with `default` set in Avro)

### Breaking changes (require new topic version)
- Remove a field
- Rename a field
- Change a field type
- Add a required field without a default

## Producer Rules
- `enable.idempotence=true` on all producers
- Use transactional producers for exactly-once semantics on financial events
- Include `correlationId` and `traceId` in message headers
- Never publish inside a `@Transactional` block — publish after transaction commits (use outbox pattern or `@TransactionalEventListener`)

## Consumer Rules
- **All consumers must be idempotent** — the same message may be delivered more than once
- Check for duplicate processing using `eventId` before acting
- Commit offsets only after successful processing
- Route failures to DLQ after max retries — never silently drop a message
- Log failures with: `eventId`, `topic`, `partition`, `offset`, `error` — **never log payload PII**
- Consumer group naming: `{service-name}-consumer-group`

## PII in Events
- PII must never appear unmasked in event payloads
- If PII must be referenced, use an opaque identifier (e.g., `customerId`) — never name/email/card number inline
- Flag any payload field containing PII for `@compliance-auditor` review
