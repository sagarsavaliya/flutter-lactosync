# Schema Spec — Dynamic Milk Types, Container Types, and Products Migration

> Author: DBMS Architect · Source: Sprint 6 Story S6-02 · Date: 2026-06-04
> Implemented by: Laravel Engineer (migrations + Eloquent models)

## Domain overview

The products table currently stores `milk_type` and `container_type` as hardcoded VARCHAR
strings (e.g. `"gir_cow"`, `"glass_bottle"`). This prevents farm owners from managing
their own types without a code deployment. The goal is to make both dimensions dynamic:

- System-wide **defaults** (seeded by the platform) are visible to all farms.
- Each farm can add its own **custom** entries — private to that farm.
- A farm that does not use a system default can **hide** it (a per-farm visibility flag),
  without deleting the global record.
- System default records are **immutable** — a farm cannot delete them. Only the platform
  can (via seeder/migration).
- A milk type or container type that is **referenced by an active product** cannot be
  deleted — the database enforces this with `RESTRICT`.
- Historical order logs and invoice lines are safe because they already snapshot
  `product_name` as a string — no migration is needed for those tables.

The products table migration adds two nullable FK columns, populates them from the
existing string values via a data migration, and leaves the old VARCHAR columns in place
(nullable) for rollback safety. The old columns will be dropped in a future sprint once
production is confirmed stable.

---

## Tenancy / isolation (multi-tenant SaaS)

Both new lookup tables use a **dual-ownership model**:

- A row with `farm_id IS NULL` is a **system default** — visible to all farms, owned by
  the platform.
- A row with a non-null `farm_id` is a **farm-specific custom entry** — visible only to
  that farm.

Queries for a given farm must therefore use:

```sql
WHERE farm_id IS NULL OR farm_id = ?
```

A separate **visibility table** per lookup type stores per-farm hide decisions for system
defaults, so the global record is never touched.

The `products` table already carries `farm_id` and isolation is unchanged — the new FK
columns simply point to the lookup tables, whose rows are already scoped correctly by the
pattern above.

---

## Tables

### `milk_types`

**Purpose:** Master list of milk types — system-wide defaults (farm_id NULL) and per-farm
custom entries (farm_id set); drives the milk_type dimension of products.

| Column      | Type             | Null | Default           | Meaning |
| ----------- | ---------------- | ---- | ----------------- | ------- |
| id          | BIGINT UNSIGNED  | no   | —                 | Surrogate primary key; auto-increment |
| farm_id     | BIGINT UNSIGNED  | yes  | NULL              | NULL = system default visible to all farms; non-null = custom entry private to this farm |
| name        | VARCHAR(100)     | no   | —                 | Human-readable label shown in the app (e.g. "Gir Cow", "Buffalo") |
| is_active   | TINYINT(1)       | no   | 1                 | Soft-disable a custom entry without deleting it; system defaults use this column too (platform-controlled) |
| created_at  | TIMESTAMP        | no   | CURRENT_TIMESTAMP | Row creation time (UTC) |
| updated_at  | TIMESTAMP        | no   | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Last update time (UTC) |

- **Primary key:** `id`
- **Foreign keys:**
  - `farm_id` → `farms.id`, on delete **CASCADE** — if a farm is deleted, its custom
    milk type entries are deleted with it. System defaults (farm_id NULL) are unaffected.
- **Indexes:**
  - `idx_milk_types_farm_id` on (`farm_id`) — serves the per-farm lookup query
    `WHERE farm_id IS NULL OR farm_id = ?`; also satisfies the FK index requirement.
  - `idx_milk_types_is_active` on (`farm_id`, `is_active`) — serves the filtered list
    query `WHERE (farm_id IS NULL OR farm_id = ?) AND is_active = 1` used to populate
    product-creation dropdowns.
- **Unique constraints:** (`farm_id`, `name`) — a farm cannot create two custom milk
  types with the same name; system defaults are unique by name among NULLs (MySQL treats
  each NULL as distinct in unique indexes, so this is enforced at the application layer
  for system defaults by checking uniqueness in the seeder).
- **Check constraints:** none beyond the FK and unique constraint; `is_active` values
  are enforced as boolean by the application layer.
- **Delete protection for products:** `milk_type_id` on the products table references
  this table with `ON DELETE RESTRICT` — a milk type referenced by any product row
  cannot be deleted.

---

### `farm_milk_type_visibility`

**Purpose:** Per-farm hide decisions for system-default milk types; a row here means the
farm has hidden that system default — it will not appear in their product-creation
dropdown.

| Column        | Type             | Null | Default           | Meaning |
| ------------- | ---------------- | ---- | ----------------- | ------- |
| id            | BIGINT UNSIGNED  | no   | —                 | Surrogate primary key; auto-increment |
| farm_id       | BIGINT UNSIGNED  | no   | —                 | The farm that is hiding this system default |
| milk_type_id  | BIGINT UNSIGNED  | no   | —                 | The system-default milk type being hidden (must have farm_id NULL in milk_types) |
| created_at    | TIMESTAMP        | no   | CURRENT_TIMESTAMP | When the farm hid this type (UTC) |

- **Primary key:** `id`
- **Foreign keys:**
  - `farm_id` → `farms.id`, on delete **CASCADE** — removing a farm clears its hide preferences.
  - `milk_type_id` → `milk_types.id`, on delete **CASCADE** — if a system default is ever removed by the platform, the hide records vanish too.
- **Indexes:**
  - `idx_fmtv_farm_milk` on (`farm_id`, `milk_type_id`) UNIQUE — serves the visibility
    check query `WHERE farm_id = ? AND milk_type_id = ?`; the unique constraint
    prevents duplicate hide rows for the same (farm, type) pair.
- **Unique constraints:** (`farm_id`, `milk_type_id`) — enforced by the index above.
- **Note:** This table has no `updated_at` because hiding is a toggle — a row is
  inserted to hide and deleted to un-hide. No updates occur.

---

### `container_types`

**Purpose:** Master list of container types as material + size pairs — system-wide
defaults (farm_id NULL) and per-farm custom entries (farm_id set); drives the container
dimension of products.

| Column      | Type             | Null | Default           | Meaning |
| ----------- | ---------------- | ---- | ----------------- | ------- |
| id          | BIGINT UNSIGNED  | no   | —                 | Surrogate primary key; auto-increment |
| farm_id     | BIGINT UNSIGNED  | yes  | NULL              | NULL = system default; non-null = farm-specific custom entry |
| name        | VARCHAR(100)     | no   | —                 | Human-readable label combining material and size (e.g. "Plastic Bag 1L", "Glass Bottle 500ml") |
| is_active   | TINYINT(1)       | no   | 1                 | Soft-disable without deleting; platform-controlled for system defaults |
| created_at  | TIMESTAMP        | no   | CURRENT_TIMESTAMP | Row creation time (UTC) |
| updated_at  | TIMESTAMP        | no   | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Last update time (UTC) |

- **Primary key:** `id`
- **Foreign keys:**
  - `farm_id` → `farms.id`, on delete **CASCADE** — removing a farm removes its custom
    container types. System defaults unaffected.
- **Indexes:**
  - `idx_container_types_farm_id` on (`farm_id`) — serves per-farm lookup query; satisfies FK index requirement.
  - `idx_container_types_farm_active` on (`farm_id`, `is_active`) — serves the filtered
    dropdown query `WHERE (farm_id IS NULL OR farm_id = ?) AND is_active = 1`.
- **Unique constraints:** (`farm_id`, `name`) — same rationale as milk_types; application
  layer enforces uniqueness among system defaults.
- **Delete protection for products:** `container_type_id` on the products table references
  this table with `ON DELETE RESTRICT`.

---

### `farm_container_type_visibility`

**Purpose:** Per-farm hide decisions for system-default container types; mirrors
`farm_milk_type_visibility` for the container dimension.

| Column             | Type             | Null | Default           | Meaning |
| ------------------ | ---------------- | ---- | ----------------- | ------- |
| id                 | BIGINT UNSIGNED  | no   | —                 | Surrogate primary key; auto-increment |
| farm_id            | BIGINT UNSIGNED  | no   | —                 | The farm hiding this system default |
| container_type_id  | BIGINT UNSIGNED  | no   | —                 | The system-default container type being hidden |
| created_at         | TIMESTAMP        | no   | CURRENT_TIMESTAMP | When the farm hid this type (UTC) |

- **Primary key:** `id`
- **Foreign keys:**
  - `farm_id` → `farms.id`, on delete **CASCADE** — removing a farm clears its hide preferences.
  - `container_type_id` → `container_types.id`, on delete **CASCADE** — removing a system default clears hide records for it.
- **Indexes:**
  - `idx_fctv_farm_container` on (`farm_id`, `container_type_id`) UNIQUE — serves
    visibility check; enforces no duplicate hide row per (farm, container).
- **Unique constraints:** (`farm_id`, `container_type_id`) — enforced by the index above.
- **No `updated_at`** — same toggle pattern as `farm_milk_type_visibility`.

---

### `products` — columns to add (migration delta only)

**Purpose:** Two new FK columns are added to the existing products table to replace the
hardcoded `milk_type` and `container_type` VARCHAR columns. The old VARCHAR columns are
retained as nullable after the data migration for rollback safety; they are dropped in a
future sprint.

| Column             | Type             | Null | Default | Meaning |
| ------------------ | ---------------- | ---- | ------- | ------- |
| milk_type_id       | BIGINT UNSIGNED  | yes  | NULL    | FK to milk_types.id; nullable during migration; set NOT NULL in a future sprint once all rows are confirmed populated |
| container_type_id  | BIGINT UNSIGNED  | yes  | NULL    | FK to container_types.id; same lifecycle as milk_type_id |

**Existing columns that become nullable (alter, not drop):**

| Column         | Current type    | New nullability | Reason |
| -------------- | --------------- | --------------- | ------ |
| milk_type      | VARCHAR(…)      | NULL allowed    | Kept for rollback; zeroed out conceptually after data migration |
| container_type | VARCHAR(…)      | NULL allowed    | Same |

- **Foreign keys (new):**
  - `milk_type_id` → `milk_types.id`, on delete **RESTRICT** — prevents deleting a
    milk type that is still referenced by a product row.
  - `container_type_id` → `container_types.id`, on delete **RESTRICT** — same
    protection for container types.
- **Indexes (new):**
  - `idx_products_milk_type_id` on (`farm_id`, `milk_type_id`) — serves queries listing
    products for a farm filtered by milk type.
  - `idx_products_container_type_id` on (`farm_id`, `container_type_id`) — serves
    queries filtered by container type.

---

## System seed data

The Laravel Engineer must seed exactly the following rows into `milk_types` and
`container_types` with `farm_id = NULL`. These are the system defaults visible to all
farms.

### `milk_types` seed rows

| name            | is_active |
| --------------- | --------- |
| Gir Cow         | 1         |
| Cow             | 1         |
| Buffalo         | 1         |
| Kankrej Cow     | 1         |
| Mehoni Buffalo  | 1         |
| Jafrabadi Buffalo | 1       |

### `container_types` seed rows

| name               | is_active |
| ------------------ | --------- |
| Plastic Bag 500ml  | 1         |
| Plastic Bag 1L     | 1         |
| Plastic Bag 1.5L   | 1         |
| Plastic Bag 2L     | 1         |
| Glass Bottle 500ml | 1         |
| Glass Bottle 1L    | 1         |

---

## Data migration mapping (old VARCHAR → new FK)

When populating `milk_type_id` and `container_type_id` on existing product rows, use the
following exact mapping. The data migration runs in the same migration file as the column
additions, after the seed rows have been inserted.

### milk_type VARCHAR → milk_types.id

| Old `milk_type` value | Maps to seed row name |
| --------------------- | --------------------- |
| `gir_cow`             | Gir Cow               |
| `cow`                 | Cow                   |
| `buffalo`             | Buffalo               |

Any `milk_type` value not in this table should be logged as a warning and left as NULL
(the nullable column allows this); the Laravel Engineer should output a count of
unmapped rows in the migration output so it can be reviewed before the old column is
dropped.

### container_type VARCHAR → container_types.id

| Old `container_type` value | Maps to seed row name | Decision rationale |
| -------------------------- | --------------------- | ------------------ |
| `glass_bottle`             | Glass Bottle 1L       | The old column encoded only material, not size. 1L is chosen as the most common glass bottle size in the Gujarat dairy market; this is a best-effort default. Farm owners should be notified (via in-app prompt in a future sprint) to review and correct their products if 500ml glass bottles exist. |
| `plastic_bag`              | Plastic Bag 1L        | Same rationale — 1L is the most common plastic bag size; 500ml and 2L variants exist in the seed data for farms to reassign manually. |

**This is a lossy mapping by design.** The old schema did not encode size. The migration
makes a documented default choice. The old `container_type` VARCHAR column is retained
(nullable) after migration so that a rollback or an audit query can always recover what
the original string was. It must not be dropped until after the farm owners have had the
opportunity to correct any incorrectly mapped products.

---

## Enforcement rules summary

| Rule | Enforced by |
| ---- | ----------- |
| A farm cannot delete a system default | Application layer: check `farm_id IS NULL` before allowing delete; return a 403 error |
| A milk type / container type in use by an active product cannot be deleted | Database: `ON DELETE RESTRICT` on both FKs from products |
| A farm can hide a system default | `farm_milk_type_visibility` / `farm_container_type_visibility` rows; application excludes hidden types from dropdowns |
| Custom entries are private to the owning farm | Query always filters `WHERE farm_id IS NULL OR farm_id = :current_farm_id` |

---

## Scale notes

`milk_types` and `container_types` are tiny tables (single-digit to low-double-digit rows
per farm plus the system seed rows). No archival or partitioning is needed. The visibility
tables grow at most one row per (farm × system-default) pair — also negligible. The
`products` table index additions are the only write-path concern; the composite indexes
on (`farm_id`, `milk_type_id`) and (`farm_id`, `container_type_id`) are a net win because
they replace or supplement the existing scan on `farm_id` alone.

---

## Handoff

```
TO:      Laravel Engineer
STORY:   S6-02 — Dynamic milk types + container types + products migration
DO:      Create milk_types, farm_milk_type_visibility, container_types,
         farm_container_type_visibility tables; seed system defaults exactly as
         specified above; add milk_type_id and container_type_id FK columns to
         products; run the data migration mapping documented in this spec; make the
         old milk_type and container_type VARCHAR columns nullable (do NOT drop them)
AGAINST: briefs/specs/schema-s6-02-dynamic-milk-containers.md
DONE WHEN: all four new tables exist with correct FKs and indexes; seed rows match the
           spec exactly; every existing product row has milk_type_id and
           container_type_id populated (or NULL with a logged warning for unmapped
           values); ON DELETE RESTRICT is verified by attempting to delete a milk type
           referenced by a product and confirming a database error is returned;
           old VARCHAR columns are nullable and still present
```
