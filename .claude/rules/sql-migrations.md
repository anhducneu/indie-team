# Rules: SQL Migrations

**Applies to:** `services/**/db/changelog/**`

---

## Migration Tool: Liquibase (YAML format)

All schema changes use Liquibase YAML changelogs. No SQL migration files, no DDL inside application code.

## Changelog Structure

```
services/{name}/src/main/resources/db/
  changelog/
    db.changelog-master.yaml        ← Master file — includes all changelogs in order
    changes/
      001-create-initial-schema.yaml
      002-add-accounts-table.yaml
      003-add-idempotency-key-to-payments.yaml
      004-create-idx-payments-account-id.yaml
```

### Master Changelog (`db.changelog-master.yaml`)
```yaml
databaseChangeLog:
  - includeAll:
      path: db/changelog/changes/
      relativeToChangelogFile: true
```

## Changeset File Naming
```
{nnn}-{description}.yaml
```
- Sequence numbers are **zero-padded, sequential, and never reused**: `001`, `002`, `003`
- Description: lowercase, hyphens — `add-idempotency-key-to-payments`
- One logical change per file

## Changeset Structure (YAML)

```yaml
databaseChangeLog:
  - changeSet:
      id: 003
      author: db-designer
      comment: Add idempotency key to payments table
      labels: payments
      changes:
        - addColumn:
            tableName: payments
            columns:
              - column:
                  name: idempotency_key
                  type: TEXT
                  constraints:
                    nullable: false
                    unique: true
      rollback:
        - dropColumn:
            tableName: payments
            columnName: idempotency_key
```

| Field | Rule |
|---|---|
| `id` | Matches file sequence number |
| `author` | Always `db-designer` |
| `comment` | One-line description of the change |
| `labels` | Short feature/sprint tag |
| `rollback` | Required for all changes — use Liquibase inverse operations where possible |

## Common Liquibase Change Types

```yaml
# Create table
- createTable:
    tableName: payments
    columns:
      - column:
          name: id
          type: UUID
          defaultValueComputed: gen_random_uuid()
          constraints:
            primaryKey: true
            nullable: false

# Add column
- addColumn:
    tableName: payments
    columns:
      - column:
          name: deleted_at
          type: TIMESTAMPTZ

# Add index
- createIndex:
    indexName: idx_payments_account_id
    tableName: payments
    columns:
      - column:
          name: account_id

# Add foreign key
- addForeignKeyConstraint:
    baseTableName: payments
    baseColumnNames: account_id
    constraintName: fk_payments_accounts
    referencedTableName: accounts
    referencedColumnNames: id

# Add unique constraint
- addUniqueConstraint:
    tableName: payments
    columnNames: idempotency_key
    constraintName: uq_payments_idempotency_key
```

## Required Columns (every table)
```yaml
- column:
    name: id
    type: UUID
    defaultValueComputed: gen_random_uuid()
    constraints:
      primaryKey: true
      nullable: false
- column:
    name: created_at
    type: TIMESTAMPTZ
    defaultValueComputed: now()
    constraints:
      nullable: false
- column:
    name: updated_at
    type: TIMESTAMPTZ
    defaultValueComputed: now()
    constraints:
      nullable: false
- column:
    name: version
    type: BIGINT
    defaultValueNumeric: 0
    constraints:
      nullable: false
    remarks: optimistic locking
```

## Data Type Rules
| Data | Correct type | Never use |
|------|-------------|-----------|
| Timestamps | `TIMESTAMPTZ` | `TIMESTAMP` (loses timezone) |
| Money / amounts | `BIGINT` (minor units: cents) | `FLOAT`, `DECIMAL`, `NUMERIC` for money |
| Variable strings | `TEXT` | `VARCHAR(n)` unless n is a business rule |
| Primary keys | `UUID` with `gen_random_uuid()` | `SERIAL` (breaks distributed systems) |
| Booleans | `BOOLEAN` | `CHAR(1)`, `SMALLINT` |

## Naming Conventions
| Object | Pattern | Example |
|--------|---------|---------|
| Tables | `snake_case`, plural | `payments`, `audit_logs` |
| Columns | `snake_case` | `account_id`, `created_at` |
| Indexes | `idx_{table}_{columns}` | `idx_payments_account_id` |
| Foreign keys | `fk_{table}_{ref_table}` | `fk_payments_accounts` |
| Unique constraints | `uq_{table}_{columns}` | `uq_payments_idempotency_key` |

## Backward Compatibility (enforced)
Every changeset must be deployable without taking down the running service:
- ✅ `addColumn` with a default value
- ✅ `createTable`
- ✅ `createIndex`
- ✅ `addForeignKeyConstraint`
- ⚠️ `dropColumn` — only after confirming no running version references it (two-phase)
- ❌ `renameColumn` — breaking change, requires multi-step changesets
- ❌ `modifyDataType` — requires new column + backfill + drop old
- ❌ `dropTable` — requires `@db-designer` + human approval

## Financial Records
- Never use `delete` changes on financial records — use soft delete: `deleted_at TIMESTAMPTZ`
- Audit log tables are **append-only** — no `update` or `delete` change types ever

## PII Fields
Any column containing personal data must include a `remarks` field:
```yaml
- column:
    name: email
    type: TEXT
    remarks: "PII: encrypted at rest, GDPR-retained 7 years"
```
Flag for `@compliance-auditor` review before changeset is finalized.

## Indexes
- Add an index for every foreign key column
- Add an index for every column used in a `WHERE` clause in production queries
