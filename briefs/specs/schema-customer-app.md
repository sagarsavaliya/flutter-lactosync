# Schema Spec — Customer App (CA-01)

> **Author:** DBMS Architect
> **Date:** 2026-06-06
> **Story:** CA-01 — DB schema — customers auth columns
> **Implements against:** `briefs/requirements/customer-app.md`, `briefs/sprints/sprint-customer-app.md`
> **Hands to:** Laravel Engineer — implement as a single migration file; no PHP code is in this spec

---

## 0. Existing state — confirmed by migration audit

Before this migration runs, the `customers` table has these columns (confirmed from existing migrations):

| Column | Type | Notes |
|---|---|---|
| `id` | `BIGINT UNSIGNED` | PK, auto-increment |
| `farm_id` | `BIGINT UNSIGNED` | FK → `farms.id`, cascade delete |
| `first_name` | `VARCHAR(255)` | NOT NULL |
| `last_name` | `VARCHAR(255)` | NOT NULL |
| `address_line` | `VARCHAR(255)` | NOT NULL |
| `area` | `VARCHAR(255)` | nullable |
| `landmark` | `VARCHAR(255)` | nullable |
| `city` | `VARCHAR(255)` | NOT NULL |
| `state` | `VARCHAR(255)` | NOT NULL |
| `zip` | `VARCHAR(10)` | NOT NULL |
| `contact` | `VARCHAR(10)` | NOT NULL — login identifier |
| `whatsapp_enabled` | `TINYINT(1)` | NOT NULL, default `1` |
| `secondary_contact` | `VARCHAR(10)` | nullable |
| `is_active` | `TINYINT(1)` | NOT NULL, default `1` |
| `vacation_start` | `DATE` | nullable — added by migration `2026_05_30_300001` |
| `vacation_end` | `DATE` | nullable — added by migration `2026_05_30_300001` |
| `created_at` | `TIMESTAMP` | nullable |
| `updated_at` | `TIMESTAMP` | nullable |
| `deleted_at` | `TIMESTAMP` | nullable (soft-deletes) |

No OTP, PIN, or auth-timestamp columns exist yet. The `contact` column is already the login identifier. No unique index on `contact` currently — the Laravel Engineer must note that `contact` functions as the auth identifier; a unique index is specified below.

---

## 1. `customers` table — new columns (ALTER TABLE)

All six columns below are added by a single new migration. The migration filename must start with a timestamp later than `2026_06_06_100001` (the most recent migration as of spec date).

### Column specifications

| Column | MySQL type | Nullable | Default | After column | Index |
|---|---|---|---|---|---|
| `pin` | `VARCHAR(255)` | NOT NULL (nullable in migration — set once PIN is created; see note A) | none | `vacation_end` | none |
| `otp` | `VARCHAR(6)` | nullable | none | `pin` | none |
| `otp_expires_at` | `TIMESTAMP` | nullable | none | `otp` | none |
| `mobile_verified_at` | `TIMESTAMP` | nullable | none | `otp_expires_at` | none |
| `last_login_at` | `TIMESTAMP` | nullable | none | `mobile_verified_at` | none |
| `last_address_change_at` | `TIMESTAMP` | nullable | none | `last_login_at` | none |

**Note A — `pin` nullability:**
The column must be declared `nullable` in the migration so existing customer rows (populated by the owner) are not broken (they have no PIN yet). The PRD requires a PIN to be set before the customer can log in; enforcement is at the application layer, not a DB constraint. The column holds a bcrypt hash once set, so `VARCHAR(255)` matches the bcrypt output length exactly.

**Note B — `otp` storage pattern:**
Owner OTP uses a separate `otp_requests` table (hashed). For customer OTP, the PM decision in the CA-01/CA-02 sprint ACs is to store OTP inline on the `customers` row. The `otp` column stores the **raw 6-digit code as a plain string** (`VARCHAR(6)`). The application layer handles expiry via `otp_expires_at`. This is intentional — it matches the CA-02 AC which says "stores hashed OTP + expiry in `customers.otp` / `customers.otp_expires_at`". Because the CA-02 AC uses the word "hashed", the Laravel Engineer should clarify during CA-02 implementation whether to store plain or hashed. For schema purposes, `VARCHAR(6)` accommodates a plain 6-digit code; a hash would require `VARCHAR(255)`. **Recommendation: use `VARCHAR(255)` to remain compatible with either approach.** The DBMS Architect flags this as a peer-to-peer clarification for the Laravel Engineer to resolve in CA-02 and log in `DECISIONS.md`.

**Updated column spec for `otp` (revised recommendation):**

| Column | MySQL type | Nullable | Default |
|---|---|---|---|
| `otp` | `VARCHAR(255)` | nullable | none |

This accommodates both plain (6 chars) and bcrypt-hashed (60 chars) storage without a future ALTER.

### Additional index — `contact` uniqueness

The `contact` column is the auth login identifier. The existing migration (`2026_05_30_200002`) does not enforce uniqueness on `contact`. A `contact` duplicate would allow two customers to share a mobile number and break the OTP/PIN auth flow.

**This migration must also add:**

```
UNIQUE INDEX `customers_contact_unique` ON `customers` (`contact`)
```

The Laravel Engineer must verify that no existing data has duplicate `contact` values before running this migration on production. If duplicates exist, they must be resolved manually before deploying. Add a note in the migration comment.

---

## 2. Full column list for the migration `up()` method

```
$table->string('pin')->nullable()->after('vacation_end');
$table->string('otp')->nullable()->after('pin');
$table->timestamp('otp_expires_at')->nullable()->after('otp');
$table->timestamp('mobile_verified_at')->nullable()->after('otp_expires_at');
$table->timestamp('last_login_at')->nullable()->after('mobile_verified_at');
$table->timestamp('last_address_change_at')->nullable()->after('last_login_at');
$table->unique('contact');
```

## 3. `down()` method — must reverse only the added columns and index

```
$table->dropUnique('customers_contact_unique');
$table->dropColumn([
    'pin',
    'otp',
    'otp_expires_at',
    'mobile_verified_at',
    'last_login_at',
    'last_address_change_at',
]);
```

---

## 4. `Customer` model — required changes (spec only; Laravel Engineer writes the PHP)

### 4a. Class declaration

The model must be changed from extending `Illuminate\Database\Eloquent\Model` to extending `Illuminate\Foundation\Auth\User as Authenticatable` and must `use Laravel\Sanctum\HasApiTokens`. The `SoftDeletes` trait stays. This is additive: all existing owner-side Eloquent usage of `Customer` (queries, relationships) is unaffected.

### 4b. `$hidden` additions

Add the following to `$hidden`:

| Field | Reason |
|---|---|
| `pin` | Bcrypt hash — must never appear in JSON responses |
| `otp` | Sensitive auth token — must never appear in JSON responses |

Existing `$hidden` is not defined on the current `Customer` model — the array must be created. Existing `$fillable` is not affected except for the additions below.

### 4c. `$fillable` additions

Add the following to `$fillable`:

| Field |
|---|
| `pin` |
| `otp` |
| `otp_expires_at` |
| `mobile_verified_at` |
| `last_login_at` |
| `last_address_change_at` |

### 4d. `casts()` additions

Add the following to the existing `casts()` method:

| Field | Cast | Rationale |
|---|---|---|
| `pin` | `'hashed'` | Laravel's built-in hashed cast — auto-bcrypts on assignment; matches `FarmOwner` pattern |
| `otp_expires_at` | `'datetime'` | Enables Carbon comparisons in application logic |
| `mobile_verified_at` | `'datetime'` | Enables Carbon comparisons; matches `FarmOwner` pattern |
| `last_login_at` | `'datetime'` | Enables Carbon comparisons; matches `FarmOwner` pattern |
| `last_address_change_at` | `'datetime'` | Enables 24-hour address rate-limit check (`now()->diffInHours($this->last_address_change_at) < 24`) |

**Note on `pin` cast:** If the `'hashed'` cast is used, the `otp` column should **not** use `'hashed'` — the OTP must be readable for verification. `otp` has no cast; comparison is done as a plain string in the controller.

---

## 5. No new tables required

The PM confirmed and the DBMS Architect verifies: single-day skips use an upsert into `daily_order_logs` — no separate table is needed.

**`daily_order_logs` column audit (migration `2026_05_30_400001`):**

| Required column | Present? | Column name | Type |
|---|---|---|---|
| Customer reference | Yes | `customer_id` | `BIGINT UNSIGNED` FK → `customers.id` |
| Quantity | Yes | `quantity` | `DECIMAL(8,2)` |
| Status | Yes | `status` | `VARCHAR(255)`, default `'pending'` |
| Date | Yes | `delivery_date` | `DATE` |
| Subscription line reference | Yes | `subscription_line_id` | `BIGINT UNSIGNED` FK → `subscription_lines.id`, nullable |

All columns required by the skip upsert (`customer_id`, `quantity`, `status`, `delivery_date`, `subscription_line_id`) exist. The upsert sets `quantity = 0` and `status = 'skipped'`. The unique constraint `daily_order_logs_idempotent` on `(farm_id, customer_id, subscription_id, product_id, shift, delivery_date)` ensures idempotency. **No schema change to `daily_order_logs` is needed.**

---

## 6. Auth configuration additions (spec only; Laravel Engineer writes the PHP)

The following changes are required in `config/auth.php`. They are listed here for completeness so the Laravel Engineer has a single source of truth for CA-02.

### 6a. New guard

```
'customer' => [
    'driver'   => 'sanctum',
    'provider' => 'customers',
],
```

### 6b. New provider

```
'customers' => [
    'driver' => 'eloquent',
    'model'  => App\Models\Customer::class,
],
```

### 6c. Isolation requirement

The `farm_owner` guard and `admin` guard must remain byte-for-byte identical to their current state. The `customer` guard is completely isolated: a Sanctum token created via the `customer` guard cannot authenticate any route protected by `auth:farm_owner` or `auth:admin`, and vice versa.

---

## 7. Migration filename convention

The new migration file must be named with a timestamp **after** `2026_06_06_100001` (the last migration as of spec date). Suggested:

```
2026_06_06_200000_add_auth_columns_to_customers_table.php
```

This ensures it runs after all existing migrations on both fresh installs and existing databases.
