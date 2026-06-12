# DECISIONS — <project name>

Every resolved question and decision is logged here — both PM escalations and peer-to-peer
clarifications. A decision that lives only in one exchange is invisible to QA, to the next
sprint, and to the human. Newest at the top.

Format per entry:

---

### <date> — <short title>

- **Context / question:** <what came up>
- **Decided by:** <peer-to-peer between X and Y | PM | human>
- **Decision:** <the answer, precisely>
- **Affects:** <stories / contracts / files impacted>
- **New work?** <no | yes → story S_ created>

---

### 2026-06-06 — CA-01/CA-02: OTP storage for customer auth

- **Context / question:** DBMS spec Note B flagged that `otp` column type affects both CA-01 (schema) and CA-02 (controller logic). `VARCHAR(6)` fits a plain 6-digit code; `VARCHAR(255)` is required if the OTP is bcrypt-hashed. CA-02 AC says "stores hashed OTP + expiry", which implies bcrypt.
- **Decided by:** peer-to-peer (DBMS Architect and Laravel Engineer)
- **Decision:** `customers.otp` is `VARCHAR(255)` to accommodate bcrypt hashing (not `VARCHAR(6)`). OTP will be stored hashed, consistent with the owner OTP pattern. This was the DBMS Architect's recommendation in the spec (Note B updated column spec). The CA-01 migration and Customer model are implemented with `VARCHAR(255)`. CA-02 must store the OTP using `Hash::make()` and verify with `Hash::check()`.
- **Affects:** CA-01 migration (`customers.otp` column), CA-02 `send-otp` and `verify-otp` controller logic
- **New work?** no

---

### 2026-06-05 — T1-10: plan-resume due_date recalculation strategy

- **Context / question:** When resuming a paused plan, should `due_date` = today + remaining days from before the pause, or today + full billing cycle?
- **Decided by:** peer-to-peer (Laravel Engineer, per task instructions "keep it simple, document the choice")
- **Decision:** On resume, `due_date` = today + full billing cycle. Carrying over remaining days is complex (requires storing the exact pause-entry date and billing position). The admin and tenant are expected to negotiate the new renewal date manually, which aligns with the spec note A6. The full-cycle approach gives the tenant a fresh, clean window from the resume date.
- **Affects:** T1-10 `planResume()` in TenantController.php; T1-15 (React resume modal — display of new due date)
- **New work?** no

---

### 2026-06-05 — T1-08: "owners" in schema spec maps to farm_owners table

- **Context / question:** The schema spec (`briefs/specs/schema-tenant-admin.md`) references `owners.id` as the FK target for `owner_id` in `tenant_plan_assignments` and `saas_payments`. The actual table in the codebase is `farm_owners`, not `owners`.
- **Decided by:** peer-to-peer (DBMS Architect spec intent vs Laravel Engineer implementation)
- **Decision:** All FK constraints in T1-08 migrations reference `farm_owners.id`. The Eloquent model relationships use `FarmOwner::class`. The term "owner" in the schema spec is a conceptual label for the farm-owner tenant row, not a separate table.
- **Affects:** T1-08 migrations and models, T1-09–12 (any future FK joins to owner context)
- **New work?** no

---

### 2026-06-05 — Tenant Admin Web App: OQ resolutions (human-approved)

- **Context / question:** Four open questions from the PRD were presented to the human for approval.
- **Decided by:** human
- **Decision (OQ-2 — plan pause + overdue behaviour):**
  - When a tenant's SaaS payment becomes overdue, their plan is automatically paused.
  - A 5-day grace period starts from the due date. During this window the tenant sees an in-app alert ("Clear your dues to continue") with a payment option and a redirect to the payment screen.
  - After 5 days with no payment, ALL operations for that tenant are fully suspended (API middleware blocks every owner API call with a `SUBSCRIPTION_SUSPENDED` error).
  - Once payment is confirmed by the admin, subscription resumes **immediately** (no manual step).
- **Decision (OQ-4 — suspension):** confirmed by OQ-2 above — 5-day grace → full suspension. No auto-suspend before the grace period expires.
- **Decision (OQ-6 — plan limits):** Plan feature limits are **enforced by the API** (not informational). Middleware checks limits on relevant endpoints.
- **Decision (OQ-7 — deployment):** React build served from `superadmin.lactosync.com` — human will add the DNS subdomain; VPS Nginx config added by DevOps.
- **Affects:** T1-07 (schema), T1-08 (admin auth), T1-11 (plan lifecycle), T1-12 (payments), T1-13..17 (React), and two new stories:
  - **T1-21** (Laravel Engineer) — subscription enforcement middleware: intercepts every `api/v1/owner/*` call, checks tenant subscription status, returns `402 PAYMENT_OVERDUE` (in grace) or `403 SUBSCRIPTION_SUSPENDED` (post-grace) with structured payload.
  - **T1-22** (Flutter Engineer) — subscription overdue/suspended screen in the Flutter mobile app: intercept 402/403 from Dio interceptor, show alert with "Pay Now" redirect, on payment confirmation from admin resume immediately.
- **New work?** yes → stories T1-21 and T1-22 added to sprint.

---

### <date> — Example: invoice date format

- **Context / question:** React needed the date format returned by `GET /api/v1/invoices`.
- **Decided by:** peer-to-peer (React ↔ Laravel)
- **Decision:** API returns ISO 8601 UTC strings; client formats for display.
- **Affects:** S2 (invoice list UI), S5 (invoice API)
- **New work?** no
