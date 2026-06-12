# Schema Spec — Tenant Admin Web App

> Author: DBMS Architect · Source: `briefs/requirements/tenant-admin-webapp.md` · Date: 2026-06-05
> Implemented by: Laravel Engineer (T1-08 — migrations + Eloquent models)

---

## Domain overview

The Tenant Admin Web App introduces a SaaS platform-management layer on top of the existing
milk-delivery product. The domain has four entities:

- **Admin User** — the platform operator who logs in to govern all tenants. Designed for N rows;
  seeded with exactly one super-admin at launch.
- **Subscription Plan** — a pricing tier (name, price, billing cycle, feature limits) that the
  operator defines and assigns to tenants.
- **Tenant Plan Assignment** — the live contract between one tenant (an `owner` row) and one
  `subscription_plan`. Carries all state the Laravel subscription-enforcement middleware needs in a
  single row: status, due date, grace window, suspension timestamp.
- **SaaS Payment** — a manually recorded payment from a tenant to the platform. Completely
  separate from the milk-delivery `payments`/`invoices` tables.

Relationships:

```
owners (existing, read-only)
  │
  └─── tenant_plan_assignments ───► subscription_plans
            │
            └─── saas_payments
```

---

## Tenancy / isolation

The admin panel is a **cross-tenant, single-operator** view — the super-admin sees all tenants by
design. There is no per-row tenant isolation on the new tables themselves.

Isolation is enforced at the route/middleware level:

- All admin routes live under `/api/admin/v1/` and are guarded by the `admin` Sanctum guard.
- An owner-scoped Sanctum token must never pass the `admin` guard (separate guards, separate
  personal access token tables if needed, or a `guard_name` column on `personal_access_tokens`).
- The subscription-enforcement middleware on `/api/v1/owner/*` routes reads
  `tenant_plan_assignments` to decide the 402/403 response. It does NOT use admin-guard tokens.

---

## Tables

---

### `admin_users`

**Purpose:** Stores super-admin accounts for the Tenant Admin Web App; seeded with one row but
designed to hold N admins without a schema change.

| Column | Type | Null | Default | Meaning |
| ------ | ---- | ---- | ------- | ------- |
| `id` | BIGINT UNSIGNED | no | — | Surrogate primary key |
| `name` | VARCHAR(100) | no | — | Display name of the admin (e.g. "Sagar Savaliya") |
| `email` | VARCHAR(191) | no | — | Login email address; unique |
| `pin_hash` | VARCHAR(255) | no | — | bcrypt hash of the 6-digit numeric PIN; never plain-text |
| `failed_attempts` | TINYINT UNSIGNED | no | 0 | Consecutive failed PIN attempts since last success; reset to 0 on success |
| `locked_until` | TIMESTAMP | yes | NULL | When non-null, login is blocked until this UTC timestamp (lockout after 5 failures = now + 15 min) |
| `last_login_at` | TIMESTAMP | yes | NULL | UTC timestamp of the most recent successful login |
| `is_active` | TINYINT(1) | no | 1 | 0 = deactivated account; kept for soft-disable without deletion |
| `created_at` | TIMESTAMP | no | — | UTC creation timestamp (managed by Laravel) |
| `updated_at` | TIMESTAMP | no | — | UTC last-update timestamp (managed by Laravel) |

- **Primary key:** `id`
- **Foreign keys:** none
- **Unique constraints:** `uq_admin_users_email` on (`email`)
- **Indexes:**
  - `uq_admin_users_email` (unique, doubles as index) — serves `SELECT … WHERE email = ?` on login
- **Check constraints:** none required (bcrypt guarantees hash format; PIN format validated at
  application layer before hashing)

---

### `subscription_plans`

**Purpose:** Defines available SaaS pricing tiers; the operator creates, edits, and archives plans
here. Feature limits on this table are enforced by the API (not informational only — see DECISIONS
2026-06-05, OQ-6).

| Column | Type | Null | Default | Meaning |
| ------ | ---- | ---- | ------- | ------- |
| `id` | BIGINT UNSIGNED | no | — | Surrogate primary key |
| `name` | VARCHAR(100) | no | — | Human-readable plan name (e.g. "Starter", "Pro") |
| `description` | TEXT | yes | NULL | Optional marketing / admin notes for this plan |
| `price` | DECIMAL(10,2) | no | — | Price in INR per billing cycle |
| `billing_cycle` | VARCHAR(20) | no | — | One of: `monthly`, `quarterly`, `half_yearly`, `yearly` |
| `max_customers` | INT UNSIGNED | no | — | Maximum customer records allowed for a tenant on this plan; enforced by API middleware |
| `max_subscriptions` | INT UNSIGNED | no | — | Maximum active milk-delivery subscriptions allowed; enforced by API middleware |
| `is_archived` | TINYINT(1) | no | 0 | 1 = archived; archived plans cannot be assigned to new tenants but existing assignments continue |
| `created_at` | TIMESTAMP | no | — | UTC creation timestamp |
| `updated_at` | TIMESTAMP | no | — | UTC last-update timestamp |

- **Primary key:** `id`
- **Foreign keys:** none
- **Unique constraints:** `uq_subscription_plans_name` on (`name`) — plan names must be unique to
  avoid operator confusion
- **Indexes:**
  - `idx_subscription_plans_is_archived` on (`is_archived`) — serves plan-list query filtered by
    active/archived status (FR-22)
- **Check constraints:**
  - `chk_subscription_plans_billing_cycle` — `billing_cycle IN ('monthly','quarterly','half_yearly','yearly')`
  - `chk_subscription_plans_price` — `price > 0`
  - `chk_subscription_plans_max_customers` — `max_customers > 0`
  - `chk_subscription_plans_max_subscriptions` — `max_subscriptions > 0`

**Design note — price freeze on active assignments (FR-20):** The plan price and limits are stored
here. The application layer (Laravel controller) must refuse edits to `price`, `max_customers`, and
`max_subscriptions` when the plan has at least one active `tenant_plan_assignments` row. The schema
does not enforce this — it is a business-rule guard, not a DB constraint — but the spec records it
so the Laravel Engineer is not surprised.

---

### `tenant_plan_assignments`

**Purpose:** Live contract linking one tenant (`owners.id`) to one `subscription_plan`. Carries
all fields needed by the subscription-enforcement middleware to determine tenant status (active /
grace / suspended / paused / expired) in a single indexed read, without extra queries.

| Column | Type | Null | Default | Meaning |
| ------ | ---- | ---- | ------- | ------- |
| `id` | BIGINT UNSIGNED | no | — | Surrogate primary key |
| `owner_id` | BIGINT UNSIGNED | no | — | FK → `owners.id`; one assignment per tenant at a time (enforced by unique constraint below) |
| `subscription_plan_id` | BIGINT UNSIGNED | no | — | FK → `subscription_plans.id`; the assigned plan |
| `status` | VARCHAR(20) | no | `'active'` | Lifecycle state; one of: `active`, `grace_period`, `suspended`, `paused`, `expired`, `no_plan` |
| `start_date` | DATE | no | — | UTC date the assignment became effective |
| `renewal_date` | DATE | no | — | UTC date the current billing cycle expires and payment is next due |
| `due_date` | DATE | no | — | UTC date payment was/is due for the current cycle (typically equals `renewal_date`) |
| `grace_expires_at` | DATE | yes | NULL | `due_date + 5 days`; when non-null and today > this date without payment, status must be `suspended`; stored (not computed) so the middleware reads one column, no arithmetic |
| `suspended_at` | TIMESTAMP | yes | NULL | UTC timestamp when the tenant was moved to `suspended`; null if never suspended |
| `paused_at` | TIMESTAMP | yes | NULL | UTC timestamp when the admin paused the plan |
| `resumed_at` | TIMESTAMP | yes | NULL | UTC timestamp of the most recent resume from `paused` state |
| `paused_by` | BIGINT UNSIGNED | yes | NULL | FK → `admin_users.id`; which admin paused the plan |
| `resumed_by` | BIGINT UNSIGNED | yes | NULL | FK → `admin_users.id`; which admin resumed the plan |
| `assigned_by` | BIGINT UNSIGNED | yes | NULL | FK → `admin_users.id`; which admin created this assignment row (nullable for programmatic/seeded assignments) |
| `plan_change_log` | JSON | yes | NULL | Ordered array of plan-change events; see format below |
| `notes` | TEXT | yes | NULL | Free-text admin notes on this assignment |
| `created_at` | TIMESTAMP | no | — | UTC row-creation timestamp |
| `updated_at` | TIMESTAMP | no | — | UTC last-update timestamp |

- **Primary key:** `id`
- **Foreign keys:**
  - `owner_id` → `owners.id`, on delete **RESTRICT** — an assignment row must not be orphaned; if
    an owner were ever deleted (currently out of scope), the constraint surfaces it
  - `subscription_plan_id` → `subscription_plans.id`, on delete **RESTRICT** — a plan in use
    cannot be deleted; archiving (soft flag) is the correct route
  - `paused_by` → `admin_users.id`, on delete **SET NULL** — audit survives even if admin row were
    removed
  - `resumed_by` → `admin_users.id`, on delete **SET NULL**
  - `assigned_by` → `admin_users.id`, on delete **SET NULL**
- **Unique constraints:** `uq_tenant_plan_assignments_owner` on (`owner_id`) — each tenant has at
  most one active assignment row. Historical rows are promoted to `expired` status, not deleted, so
  this unique index is on `owner_id` only (one live row per tenant at any time).

  **Important implementation note:** Because there is one row per tenant (updated in place as the
  contract evolves), the `plan_change_log` JSON column carries the full history of plan changes.
  When the admin upgrades/downgrades a tenant, the Laravel Engineer updates `subscription_plan_id`
  and appends a new entry to `plan_change_log` — both in the same atomic transaction.

- **Indexes:**
  - `idx_tpa_owner_status` on (`owner_id`, `status`) — primary middleware lookup: `WHERE owner_id = ? AND status IN (...)` on every owner API request (T1-21, FR from DECISIONS OQ-2)
  - `idx_tpa_status` on (`status`) — serves dashboard aggregate counts by status (FR-07, FR-08)
  - `idx_tpa_renewal_date` on (`renewal_date`) — serves dashboard "renewal within 7 days" flag query (FR-09)
  - `idx_tpa_due_date_grace` on (`due_date`, `grace_expires_at`) — serves a scheduled job / middleware check that scans for rows where `due_date < TODAY` and `grace_expires_at >= TODAY` (grace_period detection)
  - `idx_tpa_subscription_plan_id` on (`subscription_plan_id`) — serves plan-detail "count of tenants on this plan" query (FR-22)

- **Check constraints:**
  - `chk_tpa_status` — `status IN ('active','grace_period','suspended','paused','expired','no_plan')`
  - `chk_tpa_grace_after_due` — `grace_expires_at IS NULL OR grace_expires_at >= due_date`
  - `chk_tpa_dates` — `renewal_date >= start_date`

**`plan_change_log` JSON format:**

Each element of the array is an object:

```json
{
  "changed_at": "2026-06-05T10:30:00Z",
  "changed_by_admin_id": 1,
  "from_plan_id": 2,
  "to_plan_id": 3,
  "from_plan_name": "Starter",
  "to_plan_name": "Pro",
  "reason": "Tenant requested upgrade after adding 12th customer",
  "type": "upgrade"
}
```

`type` is one of: `initial_assignment`, `upgrade`, `downgrade`, `renewal`, `plan_edit`
(when only plan name/description changed without a plan swap).

Storing plan names (denormalised) inside the log entry is intentional: if the plan record is
later renamed, the log still reads correctly without a join. This is a justified denormalisation
for an audit trail.

**Middleware contract (T1-21):**

The subscription-enforcement middleware reads one row per request:

```sql
SELECT status, grace_expires_at, suspended_at, due_date
FROM tenant_plan_assignments
WHERE owner_id = :owner_id
LIMIT 1;
```

Decision logic (no extra queries needed):

| `status` | Result |
| -------- | ------ |
| `active` | Allow request |
| `grace_period` | Return `402 PAYMENT_OVERDUE` with `grace_expires_at` in payload |
| `suspended` | Return `403 SUBSCRIPTION_SUSPENDED` |
| `paused` | Allow or block per business rule (to be confirmed with PM; suggest allow with alert) |
| `expired` | Return `403 SUBSCRIPTION_SUSPENDED` |
| `no_plan` | Return `402 PAYMENT_OVERDUE` (no plan assigned yet) |
| row missing | Return `403 SUBSCRIPTION_SUSPENDED` (treat as unprovisioned) |

**On payment confirmed (atomic update, T1-08 / T1-12):**

```sql
UPDATE tenant_plan_assignments
SET status = 'active',
    due_date = :next_due_date,
    renewal_date = :next_renewal_date,
    grace_expires_at = NULL,
    suspended_at = NULL,
    updated_at = NOW()
WHERE owner_id = :owner_id;
```

This single-row update is atomic in InnoDB. No separate query is needed.

---

### `saas_payments`

**Purpose:** Records each manually entered SaaS subscription payment from a tenant to the platform.
Completely separate from milk-delivery `payments`/`invoices`. Supports soft delete with full admin
audit trail.

| Column | Type | Null | Default | Meaning |
| ------ | ---- | ---- | ------- | ------- |
| `id` | BIGINT UNSIGNED | no | — | Surrogate primary key |
| `owner_id` | BIGINT UNSIGNED | no | — | FK → `owners.id`; which tenant made the payment |
| `tenant_plan_assignment_id` | BIGINT UNSIGNED | yes | NULL | FK → `tenant_plan_assignments.id`; the assignment this payment is against; nullable because an assignment row may not exist if data is recorded retrospectively |
| `amount` | DECIMAL(10,2) | no | — | Amount paid in INR |
| `payment_date` | DATE | no | — | The date the payment was actually made (not the record date) |
| `due_date` | DATE | yes | NULL | The billing cycle due date this payment is settling; nullable for ad-hoc partial payments |
| `payment_method` | VARCHAR(20) | no | — | One of: `upi`, `cash`, `credit`, `bank_transfer`, `other` |
| `paid_by_name` | VARCHAR(150) | yes | NULL | Name of the person / business who made the payment (free text, optional) |
| `reference` | VARCHAR(255) | yes | NULL | UPI ref, bank transaction ID, cheque number, or any external reference |
| `notes` | TEXT | yes | NULL | Admin free-text notes on this payment |
| `recorded_by` | BIGINT UNSIGNED | no | — | FK → `admin_users.id`; admin who entered this record |
| `edited_by` | BIGINT UNSIGNED | yes | NULL | FK → `admin_users.id`; last admin who edited this record (NULL if never edited) |
| `deleted_by` | BIGINT UNSIGNED | yes | NULL | FK → `admin_users.id`; admin who soft-deleted this record (NULL if not deleted) |
| `created_at` | TIMESTAMP | no | — | UTC system timestamp when this record was created |
| `updated_at` | TIMESTAMP | no | — | UTC last-update timestamp |
| `deleted_at` | TIMESTAMP | yes | NULL | Laravel SoftDeletes column; non-null = soft-deleted |

- **Primary key:** `id`
- **Foreign keys:**
  - `owner_id` → `owners.id`, on delete **RESTRICT** — payment records are financial data; deletion of an owner is blocked while payment rows exist
  - `tenant_plan_assignment_id` → `tenant_plan_assignments.id`, on delete **SET NULL** — if an assignment row is ever logically replaced, historical payments remain linked to the owner and are not orphaned
  - `recorded_by` → `admin_users.id`, on delete **RESTRICT** — audit trail must reference a real admin row; if the admin account must be deactivated use `is_active = 0`, not deletion
  - `edited_by` → `admin_users.id`, on delete **SET NULL**
  - `deleted_by` → `admin_users.id`, on delete **SET NULL**
- **Unique constraints:** none (the same tenant can make multiple payments on the same day for the same amount legitimately)
- **Indexes:**
  - `idx_saas_payments_owner_date` on (`owner_id`, `payment_date` DESC) — serves per-tenant payment history sorted by date (FR-24); also serves outstanding-balance aggregate
  - `idx_saas_payments_payment_date` on (`payment_date`) — serves global payment list date-range filter (FR-26)
  - `idx_saas_payments_deleted_at` on (`deleted_at`) — Laravel SoftDeletes scope; used by every `withTrashed` / `onlyTrashed` query
  - `idx_saas_payments_assignment` on (`tenant_plan_assignment_id`) — serves lookup of payments per assignment
  - `idx_saas_payments_recorded_by` on (`recorded_by`) — serves audit queries "payments entered by admin X"
- **Check constraints:**
  - `chk_saas_payments_amount` — `amount > 0`
  - `chk_saas_payments_method` — `payment_method IN ('upi','cash','credit','bank_transfer','other')`

---

## Scale notes

**`saas_payments`** is the only table expected to grow continuously. At 3 live tenants paying
monthly, the table grows ~36 rows/year. At 50 tenants it reaches ~600 rows/year. No partitioning
or archival is required within the foreseeable scale horizon (50 tenants per NFR). If the platform
reaches hundreds of tenants, a date-range partition on `payment_date` is the natural strategy — the
`idx_saas_payments_payment_date` index already matches that partition key.

**`tenant_plan_assignments`** will have exactly one row per tenant (unique on `owner_id`). At 50
tenants it is a 50-row table — no scale concern.

**`subscription_plans`** and **`admin_users`** are configuration tables with tens of rows. No scale
concern.

**Outstanding balance calculation (FR-25):** The "outstanding balance" per tenant is computed at
query time by the API:

```
balance = SUM(plan fees billed since start_date) − SUM(saas_payments.amount WHERE owner_id = ?)
```

This involves a scan of `saas_payments` scoped to one `owner_id` — the `idx_saas_payments_owner_date`
composite index makes this efficient at any foreseeable volume.

**Middleware read (T1-21):** The `idx_tpa_owner_status` composite index on
`tenant_plan_assignments` ensures the per-request status check is a single B-tree lookup on a
~50-row table. Latency impact is negligible.
