# Schema Spec — <feature / domain>

> Author: DBMS Architect · Source: PRD · Date: <date>
> Implemented by: Laravel Engineer (migrations + Eloquent models)

## Domain overview
<The real entities and how they relate, derived from the requirements — not from one screen.>

## Tenancy / isolation (multi-tenant SaaS only)
<The tenancy column and how isolation is enforced — decided before tables are shaped.>

## Tables
For each table:

### `<table_name>` (snake_case, plural)
**Purpose:** <one line>

| Column | Type | Null | Default | Meaning |
| ------ | ---- | ---- | ------- | ------- |
| id | BIGINT / ULID | no | — | primary key |
| <col> | <type> | <yes/no> | <…> | <meaning> |
| created_at | TIMESTAMP | no | — | |
| updated_at | TIMESTAMP | no | — | |

- **Primary key:** id
- **Foreign keys:**
  - `<col>_id` → `<table>.id`, on delete **<restrict/cascade/set null>** — models <relationship>
- **Indexes:** _(each justified by a named query)_
  - `idx_<…>` on (`col_a`, `col_b`) — serves <which query>
- **Unique constraints:** <e.g. (`tenant_id`, `slug`)>
- **Check constraints:** <e.g. status IN (...)>

## Scale notes (large tables)
<Access patterns, expected volume, archival/partition strategy for the implementer + DevOps.>
