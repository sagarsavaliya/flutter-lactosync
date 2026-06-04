# Schema Spec — Gujarat Pincode Lookup Table

> Author: DBMS Architect · Source: Sprint 6 Story S6-01 · Date: 2026-06-04
> Implemented by: Laravel Engineer (migrations + Eloquent models)

## Domain overview

A pincode is a nationally standardised 6-digit postal code assigned by India Post. Each
pincode maps to exactly one (city, district, state) triple. This is **reference data** —
it is not owned by any farm, it does not change on farm actions, and it is shared
identically across every tenant. The table exists solely to answer one query: given a
6-digit pincode entered by a farm owner in the settings form, return the corresponding
city, district, and state so the form can auto-populate those fields without manual input.

---

## Tenancy / isolation

This table is **NOT tenant-scoped**. It holds global reference data maintained by the
platform, not per-farm data. There is no `farm_id` column. All tenants read from the same
rows. Isolation is irrelevant here: a farm reading one pincode row cannot observe or
affect another farm's data in any way.

---

## Tables

### `pincodes` (snake_case, plural)

**Purpose:** Global India Post pincode reference — maps a 6-digit pincode to its city,
district, and state; seeded by platform; queried read-only by the settings form to
auto-populate location fields.

| Column      | Type         | Null | Default           | Meaning |
| ----------- | ------------ | ---- | ----------------- | ------- |
| id          | BIGINT UNSIGNED | no | —               | Surrogate primary key; auto-increment; never exposed externally |
| pincode     | CHAR(6)      | no   | —                 | Exactly 6 ASCII digits; the key the settings form searches on |
| city        | VARCHAR(100) | no   | —                 | Delivery office / locality name as per India Post (e.g. "Ahmedabad GPO") |
| district    | VARCHAR(100) | no   | —                 | Revenue district the pincode falls in (e.g. "Ahmedabad") |
| state       | VARCHAR(100) | no   | —                 | Full Indian state name (e.g. "Gujarat"); kept as a string so future states need no structural change — just new seed rows |
| created_at  | TIMESTAMP    | no   | CURRENT_TIMESTAMP | Row creation time (UTC) |
| updated_at  | TIMESTAMP    | no   | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Last update time (UTC) |

**Type rationale for `pincode`:** `CHAR(6)` is used (not `INT` or `VARCHAR`) because
pincodes are fixed-length codes, not numbers — no arithmetic is ever performed on them,
and leading zeros must be preserved (though none currently exist in the Indian system,
defensive typing is cheap here).

- **Primary key:** `id`
- **Foreign keys:** none — this is a root reference table with no outward relationships.
- **Indexes:**
  - `idx_pincodes_pincode` on (`pincode`) UNIQUE — serves the one query this table
    exists to answer: `SELECT city, district, state FROM pincodes WHERE pincode = ?`.
    The unique constraint also enforces that India Post's one-to-one mapping is never
    violated by a duplicate seed row.
- **Unique constraints:** (`pincode`) — enforced by the index above; each 6-digit code
  appears at most once.
- **Check constraints:** none required beyond the unique constraint; pincode format
  validation belongs in the application layer (form validation), not in the database.

---

## The query this table serves

```sql
SELECT city, district, state
FROM pincodes
WHERE pincode = ?
```

This is the only query. The `idx_pincodes_pincode` unique index makes it an index-only
lookup — O(log n) at worst, effectively O(1) in practice for the dataset size.

---

## Seeding strategy

- **Sprint 6:** Seed Gujarat pincodes only. Gujarat has approximately 1,500–2,000
  active pincodes. The seeder file should be named `GujPincodeSeeder` (or equivalent
  Laravel convention) and run as part of the Sprint 6 deployment.
- **Future sprints:** Additional states are added via new, state-specific seeders. No
  structural change is needed — a new seeder simply inserts rows with the corresponding
  `state` value. The schema already accommodates all 28 states and 8 UTs without
  alteration.
- **Seeder source:** India Post's pincode directory (publicly available as a CSV). The
  Laravel Engineer should document the source URL and download date in the seeder
  file's docblock for auditability.

---

## Scale notes

The complete India Post pincode database contains approximately 155,000 active pincodes.
Even if the full national dataset is loaded in a future sprint, a 155 K-row table with a
single indexed `CHAR(6)` lookup column is trivially small for MySQL 8 — no partitioning,
no archival strategy, and no read replica is needed. Gujarat alone (~2,000 rows) is
negligible. This table is append-only after seeding; writes happen only when India Post
reassigns pincodes (rare, sprint-time-only operation, not a runtime write path).

---

## Handoff

```
TO:      Laravel Engineer
STORY:   S6-01 — Pincode lookup table
DO:      Create the `pincodes` table as a migration; seed it with Gujarat pincodes;
         expose a read-only API endpoint (GET /lookup/pincode/{pincode}) that returns
         city, district, state or 404 if not found
AGAINST: briefs/specs/schema-s6-01-pincode.md
DONE WHEN: migration runs clean; GujPincodeSeeder seeds without error; the endpoint
           returns correct city/district/state for a known Gujarat pincode and 404
           for an unknown one
```
