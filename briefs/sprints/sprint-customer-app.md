# Sprint CA — Customer App

> **Status:** PM sprint written — awaiting human approval
> **Author:** Project Manager
> **Date:** 2026-06-06
> **PRD source:** `briefs/requirements/customer-app.md`

---

## Context notes (from PM codebase audit)

Before the sprint was written, the PM inspected the codebase. Key findings that shape the stories below:

| Finding | Impact on stories |
|---|---|
| `Customer` model extends plain `Illuminate\Database\Eloquent\Model` — not `Authenticatable` | CA-02 must upgrade the model. Risk: owner-side code that uses `Customer` (e.g. `OwnerController`) does Eloquent queries only — no auth calls — so the upgrade is additive and safe. Confirm in CA-02 AC. |
| `customers` table has no `pin`, `mobile_verified_at`, `last_login_at`, `last_address_change_at` columns | CA-01 migration adds them. |
| `customers` table has no OTP fields (`otp`, `otp_expires_at`) | CA-01 migration adds them (customer OTP flow is separate from the `otp_requests` table used by owners). |
| Vacation columns (`vacation_start`, `vacation_end`) already exist on `customers` (migration `2026_05_30_300001`) | CA-01 does NOT re-add them. |
| No `customer` guard in `config/auth.php`; no `customers` provider | CA-02 adds both. Existing `farm_owner` and `admin` guards are untouched. |
| No `customer/v1` route group in `routes/api.php` | CA-02 scaffolds the group and auth sub-routes; CA-03 through CA-09 add routes to it. |
| `customer_day_skips` table does NOT exist | PRD §4c uses `daily_order_logs` for skips (upsert `qty=0, status=skipped`). A separate `customer_day_skips` table is therefore NOT needed. The PM brief originally listed it — that was incorrect. CA-01 does not create it. |

---

## Story table

| ID | Title | Type | Owner | Depends on |
|---|---|---|---|---|
| CA-01 | DB schema — customers auth columns | `schema` | DBMS Architect | — |
| CA-02 | Customer Sanctum guard + auth API (4 endpoints) | `api` | Laravel Engineer | CA-01 |
| CA-03 | Dashboard API | `api` | Laravel Engineer | CA-01, CA-02 |
| CA-04 | Order log API | `api` | Laravel Engineer | CA-01, CA-02 |
| CA-05 | Bills + bill image + payments APIs | `api` | Laravel Engineer | CA-01, CA-02 |
| CA-06 | Profile + farm-contact APIs | `api` | Laravel Engineer | CA-01, CA-02 |
| CA-07 | Qty change endpoint (shift-aware lock) | `api` | Laravel Engineer | CA-01, CA-02 |
| CA-08 | Single-day skip endpoint | `api` | Laravel Engineer | CA-01, CA-02 |
| CA-09 | Vacation CRUD endpoints | `api` | Laravel Engineer | CA-01, CA-02 |
| CA-10 | Vacation auto-clear scheduler command | `scheduler` | Laravel Engineer | CA-01 |
| CA-11 | Flutter: customer auth screens | `flutter` | Flutter Engineer | CA-02, UX spec |
| CA-12 | Flutter: dashboard screen | `flutter` | Flutter Engineer | CA-03, CA-11, UX spec |
| CA-13 | Flutter: order log + qty change + single-day skip | `flutter` | Flutter Engineer | CA-04, CA-07, CA-08, CA-11, UX spec |
| CA-14 | Flutter: vacation screen | `flutter` | Flutter Engineer | CA-09, CA-11, UX spec |
| CA-15 | Flutter: bills screen (inline PNG viewer) | `flutter` | Flutter Engineer | CA-05, CA-11, UX spec |
| CA-16 | Flutter: payments screen | `flutter` | Flutter Engineer | CA-05, CA-11, UX spec |
| CA-17 | Flutter: profile screen (edit + farm contact card) | `flutter` | Flutter Engineer | CA-06, CA-11, UX spec |
| CA-18 | QA test plan | `schema` | QA Engineer | CA-11–CA-17 |
| CA-19 | APK build + VPS deploy | `scheduler` | DevOps Engineer | CA-18 |

---

## Acceptance criteria by story

### CA-01 — DB schema — customers auth columns

> **Owner:** DBMS Architect
> **Spec to write:** `briefs/specs/schema-customer-app.md`
> **Note:** DBMS Architect writes the spec; Laravel Engineer implements it as a migration.

- [ ] A new migration file adds four nullable columns to `customers`: `pin varchar(255)`, `otp varchar(6) nullable`, `otp_expires_at timestamp nullable`, `mobile_verified_at timestamp nullable`, `last_login_at timestamp nullable`, `last_address_change_at timestamp nullable`.
- [ ] Migration runs cleanly on a fresh database and on an existing populated database (`php artisan migrate` produces no errors, existing customer rows retain all data).
- [ ] `pin` is listed in `$hidden` on the `Customer` model so it is never included in JSON serialization.
- [ ] `mobile_verified_at`, `last_login_at`, `last_address_change_at` are cast to `datetime` in the model's `casts()` method.
- [ ] Migration has a correct `down()` that drops only the added columns (not the whole table).

---

### CA-02 — Customer Sanctum guard + auth API

> **Owner:** Laravel Engineer
> **Depends on:** CA-01 (schema), `briefs/specs/schema-customer-app.md`

- [ ] `config/auth.php` gains a `customer` guard (driver: `sanctum`, provider: `customers`) and a `customers` provider (driver: `eloquent`, model: `App\Models\Customer`). Existing `farm_owner` and `admin` guards are identical to their pre-CA-02 state.
- [ ] `App\Models\Customer` extends `Illuminate\Foundation\Auth\User as Authenticatable` and uses `Laravel\Sanctum\HasApiTokens`. All existing owner-side Eloquent usage of `Customer` (queries, relationships) passes a regression test or a manual smoke check.
- [ ] Four unauthenticated routes exist under `POST /api/customer/v1/auth/`: `send-otp`, `verify-otp`, `set-pin`, `login`. Each returns the standard `{success, data}` envelope.
- [ ] `send-otp`: accepts `contact` (10-digit mobile); looks up the customer by `contact`; returns HTTP 422 if not found; sends OTP via WhatsApp (same mechanism as owner OTP) and stores hashed OTP + expiry in `customers.otp` / `customers.otp_expires_at`.
- [ ] `verify-otp`: accepts `contact` + `otp`; validates OTP and expiry; on success sets `mobile_verified_at = now()` and returns a short-lived session token (or a flag) that allows the `set-pin` call; returns HTTP 422 on invalid/expired OTP.
- [ ] `set-pin`: accepts `contact` + `pin` (4 digits); requires prior OTP verification (either session flag or a signed token passed from `verify-otp`); stores `bcrypt($pin)` in `customers.pin`; issues and returns a Sanctum token for the `customer` guard.
- [ ] `login`: accepts `contact` + `pin`; validates against `customers.pin` using `Hash::check`; on success updates `last_login_at = now()` and issues a Sanctum token for the `customer` guard; returns HTTP 401 on mismatch.
- [ ] A token issued by the `customer` guard cannot authenticate any `auth:sanctum` (owner) or `auth:admin` route — verified by a feature test or manual curl.

---

### CA-03 — Dashboard API

> **Owner:** Laravel Engineer
> **Depends on:** CA-01, CA-02

- [ ] `GET /api/customer/v1/dashboard` is protected by `auth:customer` middleware; returns HTTP 401 for unauthenticated requests.
- [ ] Response `data` contains: `outstanding_balance` (sum of `invoices.balance_due` where `status != 'paid'` for this customer), `upi_qr_url` (present only when `outstanding_balance > 0`; derived from the farm record), `monthly_summary` object with integer counts `delivered`, `skipped`, `vacation_days` for the current calendar month, and `active_subscriptions` array (each item: `product_name`, `shift`, `qty`).
- [ ] All queries are scoped to `auth()->user()->farm_id` — a customer cannot see another farm's data.
- [ ] `vacation_days` count is computed from days within `customers.vacation_start`–`vacation_end` that fall in the current month, not from `daily_order_logs`.
- [ ] `monthly_summary` counts reflect only the authenticated customer's `daily_order_logs` rows for the current UTC month.

---

### CA-04 — Order log API

> **Owner:** Laravel Engineer
> **Depends on:** CA-01, CA-02

- [ ] `GET /api/customer/v1/orders?month=YYYY-MM` returns an array of day objects for every calendar day in the requested month; defaults to the current month if `month` is omitted.
- [ ] Each day object contains: `date` (YYYY-MM-DD), `status` (`delivered` | `skipped` | `vacation` | `expected` | `no_record`), `entries` array (one entry per subscription line: `subscription_line_id`, `product_name`, `shift`, `qty`).
- [ ] `vacation` status is derived from `customers.vacation_start`–`vacation_end`; `delivered`/`skipped` from `daily_order_logs`; future days with no log show `expected` with qty from the subscription; past days with no log show `no_record`.
- [ ] The shift lock state for each entry is included as `locked: true|false` based on server-side schedule time comparison so the Flutter client can disable the edit control without a separate round-trip.
- [ ] Response is scoped to the authenticated customer only; requesting another customer's data via `?customer_id=` or URL manipulation returns only the authenticated customer's data.

---

### CA-05 — Bills + bill image + payments APIs

> **Owner:** Laravel Engineer
> **Depends on:** CA-01, CA-02

- [ ] `GET /api/customer/v1/bills` returns all invoices for the authenticated customer ordered by `billing_month` descending; each row includes `id`, `billing_month`, `total_amount`, `balance_due`, `status`.
- [ ] `GET /api/customer/v1/bills/{id}/image` verifies the invoice belongs to the authenticated customer (HTTP 403 if not); returns a signed URL or redirect to the bill PNG stored on disk/S3; returns HTTP 404 if no image exists for that invoice.
- [ ] `GET /api/customer/v1/payments` returns all payments for the authenticated customer ordered by `payment_date` descending; each row includes `id`, `amount`, `payment_date`, `method`, `note`.
- [ ] All three endpoints return HTTP 401 for unauthenticated requests and HTTP 403 if the resource belongs to a different customer.
- [ ] No create/update/delete payment routes are exposed on the customer guard.

---

### CA-06 — Profile + farm-contact APIs

> **Owner:** Laravel Engineer
> **Depends on:** CA-01, CA-02

- [ ] `GET /api/customer/v1/profile` returns: `first_name`, `last_name`, `contact` (read-only), `address_line`, `area`, `landmark`, `city`, `state`, `zip`, `whatsapp_enabled`, `active_subscriptions` array (product + shift + qty per line).
- [ ] `PUT /api/customer/v1/profile` accepts any subset of: `first_name`, `last_name`, `address_line`, `area`, `landmark`, `city`, `state`, `zip`, `whatsapp_enabled`. The `contact` field is ignored even if submitted.
- [ ] If any address field is present in the request and `last_address_change_at` is not null and `now() - last_address_change_at < 24 hours`, the endpoint returns HTTP 422 with message "Address can only be updated once every 24 hours." No other fields are saved in this case.
- [ ] On a successful address save, `last_address_change_at = now()` is written and a WhatsApp notification is sent to the farm owner (not the customer) with the new full address; the customer's `whatsapp_enabled` flag does not suppress this message.
- [ ] `GET /api/customer/v1/farm-contact` returns: `farm_name`, `owner_first_name`, `owner_last_name`, `owner_mobile`, `upi_qr_url`; all sourced from the farm and farm_owner records linked to the authenticated customer's `farm_id`.

---

### CA-07 — Qty change endpoint

> **Owner:** Laravel Engineer
> **Depends on:** CA-01, CA-02

- [ ] `PUT /api/customer/v1/orders/{date}/qty` accepts `subscription_line_id` and `qty` (integer ≥ 0) in the request body; `{date}` is YYYY-MM-DD.
- [ ] Server loads the subscription line, confirms it belongs to the authenticated customer; returns HTTP 403 if not.
- [ ] Server resolves the line's `shift` and compares `now()` (in the farm's timezone) against `farms.morning_schedule_time` (for morning shift, editable date = tomorrow) or `farms.evening_schedule_time` (for evening shift, editable date = today); if the window is closed returns HTTP 422 "Order already submitted — changes are locked."
- [ ] On success, upserts a `daily_order_logs` record for the customer + date + subscription_line_id: sets `qty` to the provided value and `status` to `skipped` if `qty == 0`, else `pending` (or the existing status if already `delivered`).
- [ ] Returns HTTP 422 if `{date}` is in the past (beyond the shift-editable window).

---

### CA-08 — Single-day skip endpoint

> **Owner:** Laravel Engineer
> **Depends on:** CA-01, CA-02

- [ ] `POST /api/customer/v1/orders/{date}/skip` where `{date}` is YYYY-MM-DD.
- [ ] Server enforces all three skip constraints (§7.5 of PRD) server-side: (1) date must be strictly in the future, (2) date must not fall within active vacation range, (3) date must be ≤ today + 7 days; each violation returns a distinct HTTP 422 message matching the PRD text.
- [ ] If the day already has a `daily_order_log` with `status = 'skipped'` for this customer, the endpoint returns HTTP 200 with `{success: true}` (idempotent).
- [ ] If the day already has a `daily_order_log` with `status = 'delivered'`, returns HTTP 422 "Cannot skip a day that has already been delivered."
- [ ] On success, creates or upserts a `daily_order_logs` record with `qty = 0` and `status = 'skipped'` for the authenticated customer and the given date (one record per subscription line for that customer).

---

### CA-09 — Vacation CRUD endpoints

> **Owner:** Laravel Engineer
> **Depends on:** CA-01, CA-02

- [ ] `GET /api/customer/v1/vacation` returns `{vacation_start, vacation_end}` (both null if no active vacation).
- [ ] `POST /api/customer/v1/vacation` accepts `vacation_start` (date) and `vacation_end` (date); enforces all three PRD §7.6 constraints with the specified HTTP 422 messages; on success writes both dates to `customers` row and sends `lacto_sync_vacation_set` WhatsApp notification to the customer (suppressed if `whatsapp_enabled = false`).
- [ ] `DELETE /api/customer/v1/vacation` nullifies `vacation_start` and `vacation_end` on the customers row; returns HTTP 200 with `{success: true}`; no WhatsApp notification is sent on cancel.
- [ ] All three endpoints return HTTP 401 for unauthenticated requests.
- [ ] A customer with no active vacation who calls `DELETE /api/customer/v1/vacation` receives HTTP 200 (idempotent).

---

### CA-10 — Vacation auto-clear scheduler command

> **Owner:** Laravel Engineer
> **Depends on:** CA-01 (schema only — can run in parallel with CA-02 through CA-09)

- [ ] An Artisan command `customer:clear-ended-vacations` (or placed in an existing scheduler file) runs daily at 07:00 AM server time.
- [ ] The command selects all customers where `vacation_end = CURDATE()` (today is the last vacation day) and, for each: sets `vacation_start = null` and `vacation_end = null`, then sends the `lacto_sync_vacation_ended` WhatsApp notification to the customer (suppressed if `customers.whatsapp_enabled = false`).
- [ ] The command logs the number of customers processed (visible via `php artisan schedule:run` or the scheduler log).
- [ ] The command is registered in `app/Console/Kernel.php` (or the `schedule()` callback in `bootstrap/app.php` if the project uses the Laravel 11 style) with `->dailyAt('07:00')`.
- [ ] A unit or feature test asserts that a customer with `vacation_end = today` is cleared and a customer with `vacation_end = tomorrow` is not affected.

---

### CA-11 — Flutter: customer auth screens

> **Owner:** Flutter Engineer
> **Depends on:** CA-02 (API), `briefs/specs/ux-customer-app.md` (UX spec)
> **Note:** UX/UI Designer must produce `briefs/specs/ux-customer-app.md` before this story can start.

- [ ] Four screens exist and are navigable: Enter Mobile, Verify OTP, Set PIN (first-time / forgot), and PIN Login.
- [ ] Auth screens match the visual design language of the existing owner app (same colour scheme, typography, button styles) per the UX spec.
- [ ] Successful PIN login stores the Sanctum token in Flutter secure storage under a key that does not collide with the owner app token (e.g., `customer_auth_token`).
- [ ] "Forgot PIN" from the login screen navigates back through the OTP → Set PIN flow and replaces the token on success.
- [ ] A `CustomerAuthRepository` (or equivalent Riverpod provider) is created in `lib/features/customer/data/` — it does not share state with the owner's auth provider.

---

### CA-12 — Flutter: dashboard screen

> **Owner:** Flutter Engineer
> **Depends on:** CA-03 (API), CA-11, `briefs/specs/ux-customer-app.md`

- [ ] The dashboard screen shows: outstanding balance banner (only when `outstanding_balance > 0`) with UPI QR image, monthly summary counters (Delivered / Skipped / Vacation), active subscriptions list, and quick-nav row (Bills · Payments · Profile).
- [ ] UPI QR image is rendered inline using Flutter's `Image.network` with an auth-header-injected Dio client or a signed URL.
- [ ] Outstanding balance is formatted as "You owe ₹{amount}" matching the PRD.
- [ ] Monthly summary counters are correct for the current calendar month.
- [ ] Tapping quick-nav items navigates to the correct screens.

---

### CA-13 — Flutter: order log + qty change + single-day skip

> **Owner:** Flutter Engineer
> **Depends on:** CA-04, CA-07, CA-08, CA-11, `briefs/specs/ux-customer-app.md`

- [ ] A scrollable or calendar-style monthly view renders every day of the selected month with its status (green tick + qty for delivered, "Skipped" label, "Vacation" label, expected qty for future, dash for past no-record).
- [ ] Month navigation (previous/next arrows or swipe) works; defaults to current month on first open.
- [ ] Tapping a future non-vacation, non-locked day opens a bottom sheet or inline control showing a qty stepper for each subscription line for that customer; the `locked` flag from the API disables the stepper and shows the lock message.
- [ ] Saving a qty change calls `PUT /api/customer/v1/orders/{date}/qty` and refreshes the day's display on success; shows an error snackbar on HTTP 422.
- [ ] A "Skip this day" action on a future unlocked day calls `POST /api/customer/v1/orders/{date}/skip` and updates the day's display; shows a distinct error message for each 422 case (past day, within vacation, more than 7 days ahead).

---

### CA-14 — Flutter: vacation screen

> **Owner:** Flutter Engineer
> **Depends on:** CA-09, CA-11, `briefs/specs/ux-customer-app.md`

- [ ] The screen shows the current vacation range if set, with a "Cancel vacation" button that calls `DELETE /api/customer/v1/vacation`.
- [ ] If no vacation is set, the screen shows two date-picker fields (start and end) and a "Set vacation" button that calls `POST /api/customer/v1/vacation`.
- [ ] Date pickers enforce `start >= tomorrow` and `end >= start` on the client side; server-side validation errors are displayed as inline error messages.
- [ ] On successful `POST`, the screen transitions to the "vacation active" view and shows a confirmation snackbar mentioning WhatsApp notification sent.
- [ ] On successful `DELETE`, the screen transitions to the "no vacation" view.

---

### CA-15 — Flutter: bills screen

> **Owner:** Flutter Engineer
> **Depends on:** CA-05, CA-11, `briefs/specs/ux-customer-app.md`

- [ ] A list view shows all invoices with `billing_month`, `total_amount`, `balance_due`, and a status badge (paid / partial / unpaid) matching the PRD.
- [ ] Tapping a bill row fetches `GET /api/customer/v1/bills/{id}/image`; the PNG is displayed inline in a full-screen or modal image viewer (pinch-to-zoom acceptable; no download button required for MVP).
- [ ] A loading indicator is shown while the bill image is fetching; an error state is shown if the image is not available (HTTP 404).
- [ ] The list is ordered by `billing_month` descending.
- [ ] The screen is reachable from both the dashboard quick-nav and the app's bottom navigation (if one exists per UX spec).

---

### CA-16 — Flutter: payments screen

> **Owner:** Flutter Engineer
> **Depends on:** CA-05, CA-11, `briefs/specs/ux-customer-app.md`

- [ ] A list view shows all payments ordered by `payment_date` descending; each row shows `amount` (₹ formatted), `payment_date`, `method`, and `note` (if non-null).
- [ ] The screen is read-only — no add/edit/delete controls are rendered.
- [ ] Empty state is handled (message shown when the list is empty).
- [ ] The screen is reachable from both the dashboard quick-nav and the app's navigation.
- [ ] Pull-to-refresh triggers a fresh `GET /api/customer/v1/payments` request.

---

### CA-17 — Flutter: profile screen

> **Owner:** Flutter Engineer
> **Depends on:** CA-06, CA-11, `briefs/specs/ux-customer-app.md`

- [ ] Profile view shows: full name, mobile (no edit control), all address fields, WhatsApp toggle, active subscriptions (read-only), and a farm contact card (farm name, owner name, tap-to-call button, tap-to-WhatsApp button).
- [ ] Tapping "Edit" opens an edit form for `first_name`, `last_name`, address fields, and `whatsapp_enabled`; `contact` field has no edit control anywhere in the screen.
- [ ] Saving with an address change when `last_address_change_at` is less than 24 hours ago shows the "Address can only be updated once every 24 hours" HTTP 422 message as an inline error; no other fields are lost.
- [ ] Tap-to-call launches `tel:{mobile}` deep link; tap-to-WhatsApp launches `https://wa.me/91{mobile}` deep link.
- [ ] `PUT /api/customer/v1/profile` is called only for changed fields; on success the profile view refreshes with the new values.

---

### CA-18 — QA test plan

> **Owner:** QA Engineer
> **Depends on:** CA-11 through CA-17

- [ ] A test plan document exists in `briefs/` covering: auth flow (first-time, login, forgot PIN), dashboard data accuracy, order log month navigation and qty change (both inside and outside lock window), single-day skip (all three 422 cases), vacation set/cancel/scheduler, bills image viewer, payments read-only, profile edit with 24-hour address rate-limit.
- [ ] Each test case specifies: precondition, steps, expected result, pass/fail criterion.
- [ ] At least one test per API endpoint verifies that a customer token cannot access an owner or admin route.
- [ ] Edge cases documented: zero outstanding balance (no banner), customer with no subscriptions, customer with two active subscription lines (morning + evening), customer whose vacation ends today (scheduler fires tonight).
- [ ] All test cases are traceable to a story ID (CA-XX).

---

### CA-19 — APK build + VPS deploy

> **Owner:** DevOps Engineer
> **Depends on:** CA-18 (QA sign-off)

- [ ] A release APK is built (`flutter build apk --release`) with version bump following the existing `major.minor.patch+build` pattern.
- [ ] All Laravel migrations for Sprint CA are run on the production VPS (`php artisan migrate --force`) without data loss; a pre-migration DB dump is taken and confirmed.
- [ ] The `customer:clear-ended-vacations` scheduler command is confirmed running in the VPS cron or Laravel scheduler process.
- [ ] The `customer` Sanctum guard in `config/auth.php` on the VPS matches the code (no stale `.env` override).
- [ ] A smoke test is performed on the production VPS: register a customer, login, view dashboard, set vacation, view a bill — all return correct data.

---

## Spec prerequisites (PM cannot proceed without these)

The following two producer specs must be written before their dependent stories can start implementation. The PM does not write these — the named producer must.

| Spec file | Produced by | Blocks stories | Status |
|---|---|---|---|
| `briefs/specs/schema-customer-app.md` | DBMS Architect | CA-01 (and transitively all API + Flutter stories) | Not started |
| `briefs/specs/ux-customer-app.md` | UX/UI Designer | CA-11 through CA-17 | Not started |

---

## Critical path to first testable APK

The critical path is the longest chain of sequential dependencies. No story on this path can be parallelised with the one before it.

```
CA-01 (schema spec + migration)
  └─▶ CA-02 (customer guard + auth API)
        └─▶ CA-03 / CA-04 / CA-05 / CA-06 / CA-07 / CA-08 / CA-09  ← parallel
              └─▶ CA-11 (Flutter auth)       ← needs UX spec in parallel
                    └─▶ CA-12 through CA-17  ← parallel, each needs UX spec
                          └─▶ CA-18 (QA)
                                └─▶ CA-19 (APK + deploy)
```

**Critical path (longest sequential chain):**

CA-01 → CA-02 → any single API story (e.g. CA-03) → CA-11 → CA-12 → CA-18 → CA-19

The UX spec (`briefs/specs/ux-customer-app.md`) is a parallel pre-condition for CA-11 through CA-17. It does not lengthen the critical path only if the UX/UI Designer completes it before CA-02 is done. If the UX spec is late, it becomes the critical path gate.

**Recommendation:** Start the DBMS Architect (schema spec) and UX/UI Designer (screen specs) immediately and in parallel. Both can run while the human approves this sprint plan.

---

## Suggested parallelism once human approves

| Phase | Stories to run in parallel | Gate before next phase |
|---|---|---|
| 1 — Producers (start immediately) | DBMS Architect → `schema-customer-app.md`; UX/UI Designer → `ux-customer-app.md` | Both specs complete |
| 2 — Foundation | CA-01 (migration), CA-10 (scheduler — only needs CA-01 schema) | CA-01 merged |
| 3 — Auth | CA-02 | CA-02 merged |
| 4 — Core APIs | CA-03, CA-04, CA-05, CA-06, CA-07, CA-08, CA-09 — all in parallel | All CA-03–CA-09 merged; UX spec ready |
| 5 — Flutter | CA-11 first, then CA-12–CA-17 in parallel after CA-11 auth shell is done | All Flutter screens done |
| 6 — QA + Release | CA-18 then CA-19 sequentially | APK live |
