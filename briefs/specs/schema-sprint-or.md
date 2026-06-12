# DB Schema Spec — Sprint OR: Owner Redesign

> **Status:** Complete
> **Author:** DBMS Architect
> **Date:** 2026-06-07
> **Sprint codename:** OR (Owner Redesign)
> **Implements:** `briefs/requirements/sprint-owner-redesign.md` §§3–8

---

## 1. Current schema (as-is)

### Table: `container_types`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK, auto-increment | |
| `farm_id` | bigint unsigned, nullable, FK → `farms.id` CASCADE DELETE | NULL = system default |
| `name` | varchar(100) | |
| `kind` | varchar(20), nullable | Added by migration `2026_06_05_100000`. Values: `glass_bottle`, `plastic_bag` |
| `size_ml` | unsigned int, nullable | Added by migration `2026_06_05_100000`. Millilitres |
| `size_key` | varchar(10), nullable | Added by migration `2026_06_05_100000`. Human key e.g. `500ml`, `1L` |
| `is_active` | tinyint(1), default 1 | |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

Indexes: `idx_container_types_farm_id (farm_id)`, `idx_container_types_farm_active (farm_id, is_active)`, `idx_container_types_kind_size (kind, size_ml)`, UNIQUE `(farm_id, name)`.

Current system defaults seeded (all `farm_id = NULL`):

| name | kind | size_ml | size_key |
|---|---|---|---|
| Glass Bottle 500ml | glass_bottle | 500 | 500ml |
| Glass Bottle 1L | glass_bottle | 1000 | 1L |
| Plastic Bag 500ml | plastic_bag | 500 | 500ml |
| Plastic Bag 1L | plastic_bag | 1000 | 1L |
| Plastic Bag 1.5L | plastic_bag | 1500 | 1.5L |
| Plastic Bag 2L | plastic_bag | 2000 | 2L |
| Plastic Bag 5L (inactive) | plastic_bag | 5000 | 5L |
| Plastic Bag 10L (inactive) | plastic_bag | 10000 | 10L |
| Glass Bottle 5L (inactive) | glass_bottle | 5000 | 5L |
| Glass Bottle 10L (inactive) | glass_bottle | 10000 | 10L |

### Table: `product_container_types` (pivot — currently active)

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK | |
| `product_id` | bigint unsigned, FK → `products.id` CASCADE DELETE | |
| `container_type_id` | bigint unsigned, FK → `container_types.id` RESTRICT DELETE | |
| `created_at` | timestamp | |

UNIQUE `(product_id, container_type_id)`.

> **Note:** This pivot currently models "which container sizes a product is available in" using the old flat container_types rows (one row per size). Sprint OR replaces this model with `product_offered_sizes`.

### Table: `milk_types`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK, auto-increment | |
| `farm_id` | bigint unsigned, nullable, FK → `farms.id` CASCADE DELETE | NULL = system default |
| `name` | varchar(100) | |
| `is_active` | tinyint(1), default 1 | |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

Indexes: `idx_milk_types_farm_id (farm_id)`, `idx_milk_types_farm_active (farm_id, is_active)`, UNIQUE `(farm_id, name)`.

Current system defaults seeded (all `farm_id = NULL`): Gir Cow, Cow, Buffalo, Kankrej Cow, Mehoni Buffalo, Jafrabadi Buffalo.

> **Note on names:** The seeder and initial migration use short names ("Gir Cow", "Cow", "Buffalo"). Sprint OR renames these to full display names ("Gir Cow Milk", "Cow Milk", "Buffalo Milk", "Special Buffalo Milk"). This is a data change, not a schema change — see §4.

### Table: `products`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK, auto-increment | |
| `farm_id` | bigint unsigned, FK → `farms.id` CASCADE DELETE | |
| `name` | varchar(255) | Currently populated but pattern inconsistent |
| `milk_type` | varchar(255), nullable | Legacy string — kept for rollback safety |
| `milk_type_id` | bigint unsigned, nullable, FK → `milk_types.id` RESTRICT DELETE | Added by `2026_06_04_110005` |
| `rate` | decimal(10,2) | Rate per litre |
| `unit` | varchar(255), default 'ltr' | |
| `container_type` | varchar(255), nullable | Legacy string — kept for rollback safety |
| `container_type_id` | bigint unsigned, nullable, FK → `container_types.id` RESTRICT DELETE | Added by `2026_06_04_110005` |
| `container_kind` | varchar(20), nullable | Added by `2026_06_05_100000` |
| `is_active` | tinyint(1), default 1 | |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |
| `deleted_at` | timestamp, nullable | SoftDeletes |

### Table: `subscription_lines`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK, auto-increment | |
| `subscription_id` | bigint unsigned, FK → `subscriptions.id` CASCADE DELETE | |
| `product_id` | bigint unsigned, FK → `products.id` RESTRICT DELETE | |
| `quantity` | decimal(8,2) | Litres per day. Supports 0.5–10.0 |
| `unit_rate` | decimal(10,2) | Rate per litre at time of subscription |
| `coupon_amount` | decimal(10,2), default 0 | |
| `effective_rate` | decimal(10,2) | `unit_rate - coupon_amount` |
| `shift` | varchar(255) | DeliveryShift enum value |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

### Table: `farms`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK, auto-increment | |
| `name` | varchar(255) | |
| `address_line` | varchar(255), nullable | |
| `city` | varchar(255), nullable | |
| `state` | varchar(255), nullable | |
| `zip` | varchar(10), nullable | |
| `subscription_plan` | varchar(255), nullable | |
| `subscription_status` | varchar(255), default 'active' | |
| `timezone` | varchar(255), default 'Asia/Kolkata' | |
| `onboarding_completed_at` | timestamp, nullable | |
| `document_settings` | json/text, nullable | |
| `morning_order_time` | time or varchar, nullable | |
| `evening_order_time` | time or varchar, nullable | |
| `upi_vpa` | varchar(255), nullable | |
| `upi_payee_name` | varchar(255), nullable | |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |
| `deleted_at` | timestamp, nullable | SoftDeletes |

---

## 2. Target schema (to-be)

### Table: `container_types` (modified)

**Columns to remove** (deferred to Step 3 — do not drop until new APK verified on all live farms):

| Column | Action |
|---|---|
| `kind` | DROP (deferred) |
| `size_ml` | DROP (deferred) |
| `size_key` | DROP (deferred) |

**Final target column set:**

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK, auto-increment | No change |
| `farm_id` | bigint unsigned, nullable, FK → `farms.id` CASCADE DELETE | No change. NULL = system default |
| `name` | varchar(100), NOT NULL | No change. e.g. "Glass Bottle", "Plastic Bag" |
| `is_active` | tinyint(1), default 1 | No change |
| `created_at` | timestamp | No change |
| `updated_at` | timestamp | No change |

**Indexes (unchanged):** `idx_container_types_farm_id (farm_id)`, `idx_container_types_farm_active (farm_id, is_active)`, UNIQUE `(farm_id, name)`.

**Uniqueness rule:** `name` must be unique per `farm_id`. MySQL's UNIQUE index on `(farm_id, name)` already enforces farm-custom uniqueness. System defaults (farm_id = NULL) uniqueness is enforced at the application layer (seeder and controller both check before insert).

**Note on system default consolidation:** The current seeder has 6 rows for Glass Bottle (500ml, 1L) and 4 rows for Plastic Bag (500ml, 1L, 1.5L, 2L), plus inactive extras. Post-migration these merge into 2 container_type rows: one "Glass Bottle" row and one "Plastic Bag" row. The 4 Can types are introduced as new rows. Details in §3 Step 2.

---

### Table: `container_type_sizes` (new)

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK, auto-increment | |
| `container_type_id` | bigint unsigned, NOT NULL, FK → `container_types.id` CASCADE DELETE | |
| `size_liters` | decimal(8,2), NOT NULL | e.g. 0.50, 1.00, 1.50, 2.00, 5.00 |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

**Constraints:**
- UNIQUE `(container_type_id, size_liters)` — prevents duplicate sizes on the same container type.
- FK CASCADE DELETE: when a container_type row is deleted, all its sizes are deleted automatically.

**Indexes:** `idx_container_type_sizes_container_id (container_type_id)` (covers FK lookup and JOIN).

---

### Table: `product_offered_sizes` (new)

The PRD §5.4 defines a new `product_offered_sizes` table. This is added in Sprint OR alongside the container_type_sizes changes.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK, auto-increment | |
| `product_id` | bigint unsigned, NOT NULL, FK → `products.id` CASCADE DELETE | |
| `size_liters` | decimal(8,2), NOT NULL | Must be a value present in `container_type_sizes` for the product's container type. Enforced at app layer. |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

**Constraints:**
- UNIQUE `(product_id, size_liters)` — a product cannot offer the same size twice.
- FK CASCADE DELETE: when a product is soft-deleted, note that soft-deletes do not trigger FK cascade. The Laravel Engineer must handle orphan cleanup when products are hard-deleted or when using soft deletes (query through the product's offered sizes, not via FK cascade alone).

**Indexes:** `idx_product_offered_sizes_product_id (product_id)`.

**Relationship to `product_container_types` (existing pivot):** The `product_container_types` table modelled the same concept with the old flat schema (one container_type row per size). Once `product_offered_sizes` is populated and the app is verified, `product_container_types` is a candidate for removal. That removal is deferred to a future sprint. Do not drop `product_container_types` in Sprint OR.

---

### Table: `products` (modified)

**Columns already present — confirmed no change needed:**
- `milk_type_id` FK — present, correct.
- `container_type_id` FK — present, correct.
- `rate` decimal(10,2) — present, correct.
- `name` varchar(255) — already present in the schema (added in original `create_products_table` migration). However, the current `name` column values are **inconsistent** (some products may have stale or empty names). The backfill in Step 2 standardises all existing `name` values.

**Columns to flag for deferred removal** (same deferred-step pattern as container_types):

| Column | Current purpose | Action |
|---|---|---|
| `milk_type` | varchar(255), nullable — legacy enum string | DROP deferred (Step 3) |
| `container_type` | varchar(255), nullable — legacy enum string | DROP deferred (Step 3) |
| `container_kind` | varchar(20), nullable — denormalised kind from container type | DROP deferred (Step 3) |

**Target column set that matters for Sprint OR:**

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK | No change |
| `farm_id` | bigint unsigned, FK → `farms.id` | No change |
| `name` | varchar(255), NOT NULL | Backfill in Step 2 as `{MilkTypeName} - ₹{rate}` |
| `milk_type_id` | bigint unsigned, nullable, FK → `milk_types.id` RESTRICT | No change |
| `rate` | decimal(10,2) | No change |
| `unit` | varchar(255), default 'ltr' | No change |
| `container_type_id` | bigint unsigned, nullable, FK → `container_types.id` RESTRICT | No change |
| `is_active` | tinyint(1), default 1 | No change |
| `created_at` | timestamp | No change |
| `updated_at` | timestamp | No change |
| `deleted_at` | timestamp, nullable | No change (SoftDeletes) |

---

### Table: `farms` (modified)

**New column:**

| Column | Type | Default | Notes |
|---|---|---|---|
| `prefill_customer_address` | tinyint(1) | 0 | Controls city/state/zip prefill in new-customer form. Safe additive column. |

All existing columns unchanged.

**OQ-02 resolution:** The `prefill_customer_address` field reads and writes via the existing owner settings endpoint. The Laravel Engineer must add this field to the settings response payload and accept it in the settings update request. No new endpoint required. Log this resolution in `briefs/DECISIONS.md`.

---

### Table: `subscription_lines` (modified — new column)

Per PRD §6.1, a `container_size` column is added:

| Column | Type | Notes |
|---|---|---|
| `container_size` | decimal(8,2), nullable | The specific container size chosen at subscription time. Nullable to allow backfill on existing rows. Operational field only — does not affect billing. |

**Existing `quantity` column — precision check:**

`quantity` is `decimal(8,2)`. The standardised quantity list (§7) runs from 0.5 to 10.0 in steps of 0.5. `decimal(8,2)` stores values up to 999999.99 with 2 decimal places. This is sufficient for all values in the quantity list. No precision change required.

---

### Table: `milk_quantities` (new)

Per PRD §7.2:

| Column | Type | Notes |
|---|---|---|
| `id` | bigint unsigned, PK, auto-increment | |
| `quantity_liters` | decimal(8,2), NOT NULL | e.g. 0.50, 1.00, …, 10.00 |
| `display_label` | varchar(20), NOT NULL | e.g. "500 ml", "1 L", "1.5 L", "10 L" |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

**Constraints:** UNIQUE `(quantity_liters)`.

No `farm_id` — this is a purely system-wide reference table. No farm customisation is required or allowed for the standard quantity list.

---

## 3. Migration strategy — live tenant safety

**Live tenant:** Farenidham Gaushala (and at least 2 other farms). All migration steps must be zero-downtime and non-destructive to live data.

---

### Step 1 — Additive only (safe to run immediately, no app downtime required)

**Migration file name:** `YYYY_MM_DD_HHMMNN_sprint_or_step1_additive.php`

**Operations:**

1. **CREATE TABLE `container_type_sizes`** with columns and constraints as specified in §2.
2. **CREATE TABLE `product_offered_sizes`** with columns and constraints as specified in §2.
3. **CREATE TABLE `milk_quantities`** with columns and constraints as specified in §2.
4. **ADD COLUMN `prefill_customer_address` tinyint(1) DEFAULT 0** to `farms`. Safe: existing rows default to 0, existing API responses unchanged.
5. **ADD COLUMN `container_size` decimal(8,2) NULLABLE** to `subscription_lines`. Safe: nullable, no existing data impacted.

**Tables touched:** `container_type_sizes` (create), `product_offered_sizes` (create), `milk_quantities` (create), `farms` (alter add column), `subscription_lines` (alter add column).

**What breaks if rolled back:** Dropping the new tables is safe. Dropping `prefill_customer_address` and `container_size` is safe as no data depends on them yet. The down() must: DROP TABLE the three new tables; DROP COLUMN `prefill_customer_address` from `farms`; DROP COLUMN `container_size` from `subscription_lines`.

**API backward compatibility:** Fully backward-compatible. No existing API response shape changes. The new columns are invisible to the current app version.

---

### Step 2 — Data backfill (safe, no destructive operations)

**Migration file name:** `YYYY_MM_DD_HHMMNN_sprint_or_step2_backfill.php`

**This step runs immediately after Step 1.** It is a separate migration file to allow independent rollback.

**Operations:**

#### 2a. Merge and seed `container_types` system defaults

The current seeded system defaults use one row per size (e.g. "Glass Bottle 500ml", "Glass Bottle 1L" are two rows). The target model uses one row per container type with multiple size rows in `container_type_sizes`.

**Merge algorithm for system defaults (farm_id IS NULL):**

Group existing `container_types` rows by the canonical name derived from their `kind`:

| kind | Canonical name | Current rows that map to it |
|---|---|---|
| `glass_bottle` | Glass Bottle | Glass Bottle 500ml, Glass Bottle 1L, Glass Bottle 5L, Glass Bottle 10L |
| `plastic_bag` | Plastic Bag | Plastic Bag 500ml, Plastic Bag 1L, Plastic Bag 1.5L, Plastic Bag 2L, Plastic Bag 5L, Plastic Bag 10L |

Steps for each group:
1. Identify the row with the smallest `id` in the group — this becomes the **canonical row** to retain.
2. UPDATE the canonical row: set `name` = canonical name (e.g. "Glass Bottle"), keep `farm_id = NULL`, keep `is_active = 1`.
3. INSERT into `container_type_sizes`: one row per distinct `size_ml` in the group where `size_ml IS NOT NULL`, converting `size_liters = size_ml / 1000`. Use `insertOrIgnore` to be idempotent.
4. UPDATE any `products.container_type_id` rows pointing to non-canonical row IDs: set `container_type_id` = canonical row ID.
5. UPDATE any `product_container_types.container_type_id` rows pointing to non-canonical row IDs: set `container_type_id` = canonical row ID.
6. DELETE (hard) the non-canonical rows. This is safe only after step 4 and 5 have re-pointed all FKs.

**New system defaults to INSERT (4 Can types):**

| name | farm_id | is_active | size_liters |
|---|---|---|---|
| 5L Can | NULL | 1 | 5.00 |
| 10L Can | NULL | 1 | 10.00 |
| 15L Can | NULL | 1 | 15.00 |
| 20L Can | NULL | 1 | 20.00 |

Insert these as new rows in `container_types`, then insert corresponding rows in `container_type_sizes`.

**Farm-custom container types:** Any `container_types` row where `farm_id IS NOT NULL` is left untouched in this step. Farm-custom types may already use the name-plus-size pattern (e.g. a farm that created "Glass Bottle 500ml" as their own custom entry). These are NOT merged automatically — the Laravel Engineer must handle farm-custom container type name updates via a separate app-level process when farms transition to the new UI. For Sprint OR, farm-custom rows remain as-is with their old names in `container_types`; their `size_ml` data is migrated into `container_type_sizes` using the same size_ml / 1000 conversion.

Algorithm for farm-custom rows:
1. Group farm-custom rows by `(farm_id, kind)` where `kind IS NOT NULL`.
2. For each group, retain the row with the smallest `id` as the canonical row; rename it to the kind's canonical name (e.g. "Glass Bottle").
3. Migrate size data and re-point FKs as above.
4. If a farm has only one row per kind (the common case), rename it in place — no merge required.

**Note:** If a farm's custom row name is already clean (e.g. they already called it "Glass Bottle"), no rename is needed.

#### 2b. Backfill `products.name`

For every `products` row where `deleted_at IS NULL`:
- JOIN `milk_types` on `milk_type_id` to get `milk_types.name`.
- Set `products.name = CONCAT(milk_types.name, ' - ₹', FORMAT(products.rate, 2))`.
- If `milk_type_id IS NULL` (unmapped legacy rows), fall back to: `products.name = CONCAT(products.milk_type, ' - ₹', FORMAT(products.rate, 2))`.

This overwrites any existing `name` values with the standardised auto-generated format.

#### 2c. Backfill `product_offered_sizes`

For every active `product_container_types` row, look up the `container_type_id`, find the `container_type_sizes` row for that container type, and insert a row into `product_offered_sizes` with `product_id` and `size_liters`. Use `insertOrIgnore`. This migrates the "which sizes does this product offer" data from the old pivot to the new table.

#### 2d. Seed `milk_quantities`

Insert the 20 standard quantity values. Use `insertOrIgnore` on `(quantity_liters)`. See §4 for exact values.

**Tables touched:** `container_types` (update name, delete non-canonical rows), `container_type_sizes` (insert), `product_container_types` (update FKs), `products` (update container_type_id where re-pointed, update name), `product_offered_sizes` (insert backfill), `milk_quantities` (insert seed).

**What breaks if rolled back:** The down() for this step is complex. Recommend: the down() truncates `container_type_sizes`, `product_offered_sizes`, and `milk_quantities`, then re-seeds the old flat container_types rows from the known defaults list. Products.name is tolerably stale if rolled back (the old name was already stored). Document in the migration that a full down() is a manual recovery operation.

**API backward compatibility:** During the transition period (Step 2 applied, Step 3 not yet applied), the `container_types` API response still includes `kind`, `size_ml`, `size_key`, and `size_label` — these columns still exist on the rows. The old app version continues to work. The new app version must also request `container_type_sizes` via a new or augmented endpoint.

---

### Step 3 — Column removal (deferred — separate migration file, DO NOT run until confirmed)

**Migration file name:** `YYYY_MM_DD_HHMMNN_sprint_or_step3_drop_legacy_columns.php`

**Gate condition:** This file is written and committed but NOT executed until:
1. The new APK (Sprint OR build) is live and verified as working correctly on all live farm accounts.
2. The human (farm owner / PM) explicitly confirms the go-ahead.
3. The Laravel API has been updated to no longer read `kind`, `size_ml`, `size_key`, `container_kind` in any response.

**Operations:**

1. DROP COLUMNS `kind`, `size_ml`, `size_key` from `container_types`.
2. DROP INDEX `idx_container_types_kind_size` from `container_types` (created by migration `2026_06_05_100000`).
3. DROP COLUMNS `milk_type`, `container_type`, `container_kind` from `products`.
4. DROP TABLE `product_container_types` (deferred — confirm no code path still reads this table).

> **Risk note on `product_container_types`:** Confirm via grep before dropping. The `ContainerType::products()` and `Product::allowedContainers()` relationships reference this pivot. Both must be removed from the models before this table is dropped.

**Tables touched:** `container_types` (drop columns, drop index), `products` (drop columns), `product_container_types` (drop table).

**What breaks if rolled back:** Restoring dropped columns requires a new migration that re-adds them as nullable. Data for the dropped columns is not recoverable from this migration alone — it would need to be reconstructed from `container_type_sizes`. Rolling back Step 3 is a manual operation. Only execute Step 3 after thorough verification.

**API backward compatibility:** Step 3 is a breaking change to the API response for `GET /owner/product-types/containers` (which currently returns `kind`, `size_key`, `size_ml`, `size_label`). The Laravel Engineer must update `containerTypePayload()` in `OwnerProductTypesController` to return `sizes` (from `container_type_sizes`) and remove the deprecated fields before Step 3 runs.

---

## 4. Seed definitions

### `container_types` system defaults (farm_id = NULL)

After Step 2, the system-default container_types table has exactly 6 rows:

| id (logical) | name | farm_id | is_active |
|---|---|---|---|
| (retained from merge) | Glass Bottle | NULL | 1 |
| (retained from merge) | Plastic Bag | NULL | 1 |
| (new) | 5L Can | NULL | 1 |
| (new) | 10L Can | NULL | 1 |
| (new) | 15L Can | NULL | 1 |
| (new) | 20L Can | NULL | 1 |

### `container_type_sizes` system defaults

| container_type.name | size_liters |
|---|---|
| Glass Bottle | 0.50 |
| Glass Bottle | 1.00 |
| Plastic Bag | 0.50 |
| Plastic Bag | 1.00 |
| Plastic Bag | 1.50 |
| Plastic Bag | 2.00 |
| 5L Can | 5.00 |
| 10L Can | 10.00 |
| 15L Can | 15.00 |
| 20L Can | 20.00 |

### `milk_types` system defaults (farm_id = NULL)

The Sprint OR seeder replaces the current 6-entry seed with 4 canonical entries. The seeder must use `upsert` (insert-or-update) keyed on `(farm_id, name)`.

**Upsert these 4 rows:**

| name | farm_id | is_active |
|---|---|---|
| Gir Cow Milk | NULL | 1 |
| Cow Milk | NULL | 1 |
| Buffalo Milk | NULL | 1 |
| Special Buffalo Milk | NULL | 1 |

**Do NOT delete or deactivate:**

| name | Reason |
|---|---|
| Gir Cow | May be referenced by existing `products.milk_type_id` on live farms |
| Cow | May be referenced by existing `products.milk_type_id` on live farms |
| Buffalo | May be referenced by existing `products.milk_type_id` on live farms |
| Kankrej Cow | May have live farm data (products, subscriptions) referencing this milk_type_id |
| Mehoni Buffalo | Same |
| Jafrabadi Buffalo | Same |

The seeder file must no longer insert Kankrej Cow, Mehoni Buffalo, or Jafrabadi Buffalo on fresh installs. Existing rows are untouched.

**Note on name migration:** The current live rows are named "Gir Cow", "Cow", "Buffalo". The new canonical names are "Gir Cow Milk", "Cow Milk", "Buffalo Milk". These are different strings — a seeder upsert on name will insert new rows, not update the existing ones. The DBMS Architect decision: insert the 4 new canonical rows as additional system defaults. Do not rename the old rows — they remain for FK integrity on existing products. The old short names (Gir Cow, Cow, Buffalo) become legacy system defaults that are still visible but superseded. The Laravel Engineer must mark old short-name defaults as `is_active = 0` in the backfill step if the UI should hide them from new product creation — confirm with PM before doing this, as it affects the existing live farm's product display.

### `milk_quantities` seed (all 20 values)

| quantity_liters | display_label |
|---|---|
| 0.50 | 500 ml |
| 1.00 | 1 L |
| 1.50 | 1.5 L |
| 2.00 | 2 L |
| 2.50 | 2.5 L |
| 3.00 | 3 L |
| 3.50 | 3.5 L |
| 4.00 | 4 L |
| 4.50 | 4.5 L |
| 5.00 | 5 L |
| 5.50 | 5.5 L |
| 6.00 | 6 L |
| 6.50 | 6.5 L |
| 7.00 | 7 L |
| 7.50 | 7.5 L |
| 8.00 | 8 L |
| 8.50 | 8.5 L |
| 9.00 | 9 L |
| 9.50 | 9.5 L |
| 10.00 | 10 L |

Display label rule: values below 1 L → format as `"{ml} ml"` (e.g. 0.5 → "500 ml"). Values 1 L and above → format as `"{L} L"` (e.g. 1.5 → "1.5 L"). Whole numbers drop the decimal (1.0 → "1 L", not "1.0 L").

---

## 5. API impact assessment

### GET `/owner/product-types/containers` (indexContainerTypes)

**Current response per item:**
```json
{
  "id": 1,
  "name": "Glass Bottle 1L",
  "kind": "glass_bottle",
  "size_key": "1L",
  "size_ml": 1000,
  "size_label": "1 L",
  "farm_id": null,
  "is_system": true,
  "is_hidden": false,
  "is_active": true
}
```

**Required response per item (after Step 2, before Step 3):**

The Laravel Engineer must ADD a `sizes` array to the response, sourced from `container_type_sizes`. The old `kind`, `size_key`, `size_ml`, `size_label` fields must remain in the response until Step 3 (old app versions still read them).

```json
{
  "id": 1,
  "name": "Glass Bottle",
  "kind": "glass_bottle",
  "size_key": null,
  "size_ml": null,
  "size_label": null,
  "farm_id": null,
  "is_system": true,
  "is_hidden": false,
  "is_active": true,
  "sizes": [
    { "id": 1, "size_liters": "0.50" },
    { "id": 2, "size_liters": "1.00" }
  ]
}
```

After Step 3, the `kind`, `size_key`, `size_ml`, `size_label` fields are dropped from the response.

**Controller change required:** `containerTypePayload()` in `OwnerProductTypesController` must eager-load `containerType->sizes` and include the `sizes` array. The `scopeForKind()` scope on ContainerType and the `orderBy('kind')->orderByDesc('size_ml')` sort in `indexContainerTypes()` must be updated — after Step 2 the `kind` and `size_ml` columns still exist so sorting is unchanged; after Step 3, sorting must be replaced with `orderBy('name')` or a different strategy.

### POST `/owner/product-types/containers` (storeContainerType)

**Current:** Accepts `kind` and `size` fields, builds `name` via `ContainerTypeMetadata::buildName()`, stores `kind`, `size_ml`, `size_key`.

**Required:** The request contract must change to accept `name` (the container type name, e.g. "Glass Bottle") and `sizes` (array of decimal values). The controller must INSERT into `container_types` (name only) then INSERT into `container_type_sizes` for each size.

**Breaking change:** The old `kind` and `size` request params are deprecated. The new app sends `name` and `sizes`. The controller must support both during the transition period (check if `sizes` is present; if not, fall back to old behaviour).

### PUT `/owner/product-types/containers/{id}` (updateContainerType)

**Required:** Accept `sizes` as an addable/removable array. The controller must sync `container_type_sizes` (insert new, delete removed) rather than updating flat columns.

### GET `/owner/products` (or equivalent products listing endpoint)

**Current:** Each product item returns `name`, `milk_type_id`, `container_type_id`, `rate`, `is_active`.

**Required:** Add `offered_sizes` array from `product_offered_sizes`. Also include `container_type.name` and `milk_type.name` for the table display (§5.5 of PRD).

```json
{
  "id": 1,
  "name": "Gir Cow Milk - ₹80",
  "milk_type": { "id": 2, "name": "Gir Cow Milk" },
  "container_type": { "id": 1, "name": "Glass Bottle" },
  "offered_sizes": [
    { "id": 1, "size_liters": "1.00" }
  ],
  "rate": "80.00",
  "is_active": true
}
```

### POST `/owner/products` (storeProduct)

**Required:** Accept `milk_type_id`, `container_type_id`, `offered_sizes` (array of decimal size values), `rate`. Auto-generate `name` server-side as `"{milk_type.name} - ₹{rate}"`. Do not accept `name` from the client.

### GET `/owner/settings` (OwnerSettingsController)

**Required:** Include `prefill_customer_address` in the farms section of the settings response.

### PUT `/owner/settings` (OwnerSettingsController)

**Required:** Accept and persist `prefill_customer_address` (boolean). Validate as boolean.

### GET `/owner/quantities` (new endpoint — or include in product types)

**Required:** New endpoint to return the `milk_quantities` table. Flutter uses this to populate all quantity dropdowns.

Suggested route: `GET /owner/product-types/quantities`

Response:
```json
{
  "quantities": [
    { "id": 1, "quantity_liters": "0.50", "display_label": "500 ml" },
    { "id": 2, "quantity_liters": "1.00", "display_label": "1 L" }
  ]
}
```

### POST `/owner/subscriptions` and PUT `/owner/subscriptions/{id}` (subscription creation/edit)

**Required:** Accept `container_size` (decimal). Validate that the value exists in `product_offered_sizes` for the given `product_id`. Store in `subscription_lines.container_size`.

---

## Appendix: Table dependency diagram

```
farms
  └── container_types (farm_id nullable)
        └── container_type_sizes (container_type_id)
        └── farm_container_type_visibility (container_type_id) [no change]
  └── milk_types (farm_id nullable)
        └── farm_milk_type_visibility (milk_type_id) [no change]
  └── products (farm_id)
        └── product_offered_sizes (product_id) [new]
        └── product_container_types (product_id) [existing pivot — deferred removal]
        └── subscription_lines (product_id)
              └── container_size [new column]

milk_quantities [new, no FK — system-wide reference table]
```
