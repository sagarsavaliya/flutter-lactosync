# Stack Standard — MySQL

For the **DBMS Architect** (schema design). This is the producer's rulebook: how to design
a relational schema that is correct from day one and scales from zero to large. The
Laravel Engineer implements the schema this agent designs — it does not design here.

The deliverable is a **schema spec** in `briefs/specs/`, not migration code.

---

## What a schema spec must contain

For the Laravel Engineer to build with zero guessing, each table in the spec states:

- Table name, purpose (one line).
- Every column: name, type, nullability, default, and meaning.
- Primary key.
- Foreign keys and the relationship they model (and on-delete behaviour).
- Indexes, and *why* each exists (which query it serves).
- Unique constraints and check constraints.
- For SaaS/multi-tenant projects: the tenancy column and how isolation is enforced.

---

## Design principles

- **Normalise to 3NF by default.** Each fact lives in exactly one place. Denormalise only
  with a written reason (a proven read-heavy hotspot) — and note it in the spec.
- **Model the domain, not the screens.** The schema reflects the business's real entities
  and relationships, taken from the BA's requirement doc — not whatever a single UI form
  happens to show.
- **Design for scale up front** where it's cheap to: correct keys, correct indexes,
  correct types. These are painful to change later; getting them right on day one is the
  whole point of having an architect.

---

## Naming

- Tables: `snake_case`, plural — `invoices`, `subscription_plans`.
- Columns: `snake_case`, singular — `total_amount`, `created_at`.
- Primary key: `id`.
- Foreign keys: `<singular_referenced_table>_id` — `user_id`, `invoice_id`.
- Pivot tables: both names, singular, alphabetical — `invoice_product`.
- Booleans read as a state: `is_active`, `has_paid`.
- Timestamps: `created_at`, `updated_at`, `deleted_at` (if soft-deleting).

---

## Keys & relationships

- Every table has a primary key. Prefer a surrogate key (`id`); use UUID/ULID when IDs are
  exposed externally or must be unguessable — state which in the spec.
- Every foreign key is a **real, enforced** foreign key with an explicit on-delete rule
  (restrict / cascade / set null) chosen deliberately per relationship.
- Many-to-many goes through an explicit pivot table.

---

## Indexes

- Index every foreign key.
- Index columns used in `WHERE`, `JOIN`, `ORDER BY`, and `GROUP BY` for real queries.
- Use **composite indexes** in the order queries filter (leftmost-prefix rule), not a pile
  of single-column indexes that can't combine.
- Don't over-index — every index slows writes and costs storage. Each index in the spec
  names the query that justifies it.
- Add a unique index for any column/combination that must be unique (e.g. `email`,
  `(tenant_id, slug)`).

---

## Data types

- Smallest type that fits: don't use `BIGINT` for a status, `VARCHAR(255)` reflexively, or
  `TEXT` for a 20-char code.
- Money: `DECIMAL`, never `FLOAT`/`DOUBLE`. Never store currency as a float.
- Dates/times: proper `DATE`/`DATETIME`/`TIMESTAMP`; store UTC; be explicit about which.
- Enumerated states: a small `VARCHAR` with a check constraint, or a lookup table when the
  set grows or carries attributes. Avoid native `ENUM` (painful to alter).
- Use `NOT NULL` unless a null genuinely means something distinct from empty — and say
  what it means.

---

## Scale & integrity

- Decide and document the tenancy/isolation model for multi-tenant SaaS before any table
  is designed.
- Foreign keys, unique constraints, and check constraints enforce integrity *in the
  database* — not only in application code.
- For tables expected to grow large, note the access patterns and any archival/partition
  strategy in the spec so the implementer and DevOps plan for it.

---

## Do NOT

- Write Laravel migrations or any application code — the spec is the deliverable; Laravel
  implements it.
- Design around a single screen instead of the domain.
- Store money as float, skip foreign keys "for speed", or add indexes with no named query.
- Leave a relationship's on-delete behaviour unspecified.
