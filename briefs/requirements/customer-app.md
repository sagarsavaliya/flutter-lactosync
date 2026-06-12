# PRD — LactoSync Customer-Facing App

> **Status:** BA complete — awaiting PM sprint breakdown
> **Author:** Business Analyst
> **Date:** 2026-06-06
> **Source:** `briefs/client-input/customer-app.md`

---

## 1. Overview

The LactoSync customer app is a Flutter mobile application (Android + iOS) through which dairy farm customers manage their own milk delivery relationship. A customer can view their daily order log, change delivery quantities within permitted windows, set and cancel vacation holds, skip individual delivery days, view invoices and payment history, and manage their profile. The app sits alongside the existing owner app — both talk to the same Laravel API but through separate authentication guards. The customer app's primary goal is to reduce owner workload by letting customers self-serve actions that currently require the owner to act as a middleman (qty changes, vacation, address updates, payment visibility).

---

## 2. Actors

| Actor | Role in this app |
|---|---|
| **Customer** | Primary user. Authenticated via PIN. Can read and modify their own data within the rules defined in this document. |
| **FarmOwner** | Read-only / passive actor. Receives WhatsApp notifications when customers perform certain actions (address change). Does not log in to this app. Their data (farm name, UPI QR, schedule times) is surfaced read-only to customers. |

---

## 3. Authentication

### 3.1 First-time login (sign-up flow)

1. Customer enters their mobile number.
2. Server sends a 6-digit OTP via WhatsApp (same OTP mechanism as the owner app).
3. Customer enters the OTP. Server verifies it and marks `mobile_verified_at`.
4. Customer is prompted to set a 4-digit PIN. Server stores it hashed in `customers.pin`.
5. A Sanctum token is issued for the `customer` guard and returned to the app.
6. App navigates to the dashboard.

### 3.2 Subsequent logins

1. Customer enters their mobile number.
2. Customer enters their 4-digit PIN.
3. Server authenticates against `customers` table using the `customer` Sanctum guard.
4. A Sanctum token is issued and returned.
5. App navigates to the dashboard.

### 3.3 Forgot PIN

1. Customer taps "Forgot PIN".
2. OTP flow (same as first-time step 2–3).
3. After OTP verified, customer sets a new PIN.

### 3.4 Guard configuration

- Authenticatable model: `App\Models\Customer`
- Sanctum guard name: `customer`
- This guard is **completely separate** from the `farm_owner` guard. A customer token cannot authenticate against owner endpoints and vice versa.
- The `Customer` model must extend `Illuminate\Foundation\Auth\User as Authenticatable` and use `Laravel\Sanctum\HasApiTokens` (same pattern as `FarmOwner`).

### 3.5 Mobile number

- The customer's `contact` field (mobile number) is the login identifier.
- It is **read-only** from the customer's perspective. The customer cannot change their own mobile number.
- It is displayed in the Profile screen without an edit control.

### 3.6 New fields required on `customers` table

| Column | Type | Purpose |
|---|---|---|
| `pin` | `varchar(255)` | Hashed PIN (bcrypt). Hidden in model. |
| `mobile_verified_at` | `timestamp`, nullable | Set after first OTP verification. |
| `last_login_at` | `timestamp`, nullable | Updated on each successful login. |
| `last_address_change_at` | `timestamp`, nullable | Enforces 1-change-per-24-hours rule on address. |

---

## 4. Screens and Feature Areas

### 4a. Dashboard

**Purpose:** The first screen after login. A summary of the customer's current standing.

**Content:**

1. **Outstanding balance banner**
   - Query: sum of `invoices.balance_due` where `customer_id = auth()->id()` and `status != 'paid'`.
   - If balance > 0: show "You owe ₹{amount}" in a prominent banner. Below the amount, show the farm owner's UPI QR code image (sourced from the farm-contact endpoint; derived from `farms.upi_vpa` or `farms.upi_payee`).
   - If balance == 0: do not show the banner.

2. **Monthly order summary** (current calendar month)
   - Three counters: **Delivered** / **Skipped** / **Paused (vacation)** days.
   - Counts derived from `daily_order_logs` for the current month for this customer.

3. **Active subscriptions list**
   - Each active `SubscriptionLine` for this customer, showing product name + shift (morning/evening) + quantity.
   - Read-only on the dashboard; quantity changes happen in the order log screen.

4. **Quick navigation row**
   - Tappable cards/icons: Bills · Payments · Profile.

---

### 4b. Order Log (Monthly View)

**Purpose:** A calendar or scrollable list showing every day of the selected month with the delivery status for that customer.

**Display per day:**

| Status | Source | Display |
|---|---|---|
| `delivered` | `daily_order_logs.status = 'delivered'` | Green tick, qty shown |
| `skipped` | `daily_order_logs.status = 'skipped'` | "Skipped" label |
| `vacation` | Day falls within `customers.vacation_start`–`vacation_end` | "Vacation" label |
| No log yet (future) | No record exists | Shows expected qty from subscription |
| No log, past | No record, date is past | "No record" or dash |

**Month navigation:** Customer can swipe or tap arrows to move between months. Default is current month.

**Tapping a future day — quantity change:**

When a customer taps a future delivery day, the app checks whether the edit window is open:

- **Morning-shift subscriber:** the editable day is **tomorrow**. The window is open until today's `farm.morning_schedule_time` passes (server-side time, farm's timezone).
  - If today's time < `morning_schedule_time`: show qty stepper for tomorrow's delivery.
  - If today's time >= `morning_schedule_time`: show "Locked — order already submitted for tomorrow" message.
- **Evening-shift subscriber:** the editable day is **today**. The window is open until today's `farm.evening_schedule_time` passes.
  - If current time < `evening_schedule_time`: show qty stepper for today's delivery.
  - If current time >= `evening_schedule_time`: show "Locked — order already submitted for today" message.

**Qty change rules:**
- Minimum qty: 0 (zero means effectively skipping; record a `daily_order_log` with `qty = 0` and `status = skipped`).
- Maximum qty: no server-enforced cap for MVP (owner can adjust later).
- A customer with multiple subscription lines (e.g. morning milk + evening curd) sees a **separate qty control for each line**. Each line has its own shift check.
- Saving a qty change writes (or upserts) a record in `daily_order_logs` for that customer + date + subscription_line.
- The `PUT /api/customer/v1/orders/{date}/qty` endpoint performs the shift + schedule time check server-side. Client-side UI state is a hint only; server is the authority.

---

### 4c. Single-Day Skip

**Purpose:** Mark a single future delivery day as skipped without setting a full vacation range.

**Trigger:** A "Skip this day" button/action on a future day in the order log view, or a dedicated skip entry point.

**Rules (all enforced server-side):**

1. The skip date must be **in the future** (strictly after today's date in the farm's timezone).
2. The skip date must **not fall within** an existing active vacation range (`vacation_start <= skip_date <= vacation_end`).
3. The skip date must be **no more than 7 calendar days ahead** of today.
4. A day already marked as `skipped` cannot be skipped again (idempotent — return success if already skipped).
5. A day already marked as `delivered` (past day with a log) cannot be skipped.

**Effect:** Creates or upserts a `daily_order_log` record: `qty = 0`, `status = 'skipped'` for the given customer + date.

**Undo:** If the customer taps a skipped future day and it is still within the editable window, they may restore the qty (the qty-change flow replaces the skip record).

---

### 4d. Vacation

**Purpose:** Pause all deliveries for a contiguous date range.

**Fields:** `vacation_start` (date) and `vacation_end` (date), stored on the `customers` row.

**Validation rules (all enforced server-side):**

1. Both `vacation_start` and `vacation_end` must be **strictly in the future** (> today).
2. `vacation_end` must be **≥ vacation_start**.
3. The new range must **not overlap** an already-active vacation on this customer. (For MVP, a customer has at most one active vacation at a time.)
4. `vacation_start` and `vacation_end` cannot be in the past.

**Setting vacation:** `POST /api/customer/v1/vacation` — writes `vacation_start` + `vacation_end` to the `customers` row. Sends `lacto_sync_vacation_set` WhatsApp notification to the customer (already-wired template).

**Cancelling vacation:** `DELETE /api/customer/v1/vacation` — nullifies `vacation_start` + `vacation_end`. No notification.

**Viewing:** `GET /api/customer/v1/vacation` — returns the current vacation dates (or null if none set).

**Automated scheduler (daily at 7:00 AM server time):**

The existing scheduler or a new `UpdateVacationStatuses` command must:

1. Find all customers where `vacation_end == yesterday` (i.e., `vacation_end + 1 day == today`). For these customers:
   - Clear `vacation_start` and `vacation_end` (set both to null).
   - Send `lacto_sync_vacation_ended` WhatsApp notification to the customer.

   > Note: the notification says "delivery resumes tomorrow" but it fires when `vacation_end == today` (1 day before resume), meaning the scheduler fires on the last day of vacation and the customer gets notified that delivery starts the next day. Clarification: the scheduler fires when `vacation_end == today`. It sends the "vacation ending" notification and clears the dates. Delivery resumes the following day.

**Correct scheduler logic:**

- Fire when `vacation_end = CURDATE()` (today is the last vacation day).
- Send `lacto_sync_vacation_ended` (delivery resumes tomorrow).
- Set `vacation_start = null`, `vacation_end = null`.

This matches the client input: "sends WhatsApp 1 day before delivery resumes" + "auto-clears vacation for customer whose `vacation_end + 1 day == today`" — these are the same event (today is `vacation_end`; tomorrow = `vacation_end + 1` = first delivery day).

---

### 4e. Bills

**Purpose:** A list of the customer's invoices with ability to view the bill image inline.

**List view — each row shows:**
- `billing_month` (formatted as "June 2026")
- `total_amount` (₹ formatted)
- `balance_due` (₹ formatted)
- `status` (paid / partial / unpaid) — badge

**Tap a bill:**
- Fetch the bill image URL from `GET /api/customer/v1/bills/{id}/image`.
- Display the PNG inline in a full-screen or sheet image viewer.
- No download button required for MVP.

**Scope:** All invoices for this customer across all months (no 12-month limit imposed at the screen level; the out-of-scope 12-month limit applies to order history, not bills).

---

### 4f. Payments

**Purpose:** A read-only ledger of all payments recorded against the customer.

**List view — each row shows:**
- `amount` (₹ formatted)
- `payment_date`
- `method` (cash / UPI / other)
- Optional: `note` if present

**Ordered:** descending by `payment_date`.

**Read-only:** Customers cannot add or delete payments. Payments are recorded by the owner.

---

### 4g. Profile

**Purpose:** View and edit the customer's own profile details.

**View mode shows:**
- Full name (`first_name last_name`)
- Mobile number (read-only, no edit icon)
- Delivery address (composed of `address_line`, `area`, `landmark`, `city`, `state`, `zip`)
- Active subscription lines (product + shift + qty) — read-only here
- WhatsApp notification toggle (`customers.whatsapp_enabled`)

**Editable fields and rules:**

| Field | Editable? | Rule |
|---|---|---|
| `first_name` / `last_name` | Yes, any time | No special constraint |
| Delivery address fields | Yes, once per 24 hours | Server enforces: check `last_address_change_at`; reject if < 24 h ago. On success: set `last_address_change_at = now()` |
| Mobile (`contact`) | No | Display-only. No edit control rendered. |
| `whatsapp_enabled` | Yes, any time | Toggle; maps directly to `customers.whatsapp_enabled` |

**On address save:** Server sends a WhatsApp notification to the **farm owner** (not the customer):

> Template message (plain content, not a Meta template): "Customer {full_name} updated their delivery address to {new_full_address}."

This notification uses the owner's whatsapp_enabled check on the farm level (not customer-level; the message goes to the owner, so the customer's `whatsapp_enabled` flag is irrelevant for this specific message).

**WhatsApp toggle behaviour:**

- When `whatsapp_enabled = false` for a customer, all outbound WhatsApp messages to that customer (bill ready, order log, payment confirmation, vacation set/ended, qty change) are suppressed server-side.
- The address-change notification goes to the **owner**, so it is never suppressed by the customer's toggle.

---

### 4h. Farm Contact Card

**Purpose:** Allow the customer to contact their farm directly from the app.

**Displayed on:** Profile screen (and optionally a card on the Dashboard).

**Content:**
- Farm name (`farms.name`)
- Owner name (`farm_owners.first_name` + `last_name`)
- Mobile number (`farm_owners.mobile`)
- **Tap-to-call** button: triggers `tel:{mobile}` deep link.
- **Tap-to-WhatsApp** button: triggers `https://wa.me/91{mobile}` deep link (strip leading 0 / country code prefix as needed).

Sourced from `GET /api/customer/v1/farm-contact`. The customer's `farm_id` determines which farm record to return.

---

## 5. Notifications the Customer Receives

All notifications are WhatsApp-based (no FCM for MVP). Each is sent server-side when the triggering event occurs.

| Event | Template name | Triggered by |
|---|---|---|
| Bill generated | `lacto_sync_monthly_bill` | Owner generates bill |
| Daily milk log image | `lacto_sync_order_log` | Owner sends order log |
| Payment recorded | `lacto_sync_payment_confirmed` | Owner records payment |
| Vacation set (by customer) | `lacto_sync_vacation_set` | Customer POSTs vacation |
| Vacation ending (1 day before resume) | `lacto_sync_vacation_ended` | Scheduler fires on `vacation_end` day |
| Subscription qty / product changed | `lacto_sync_qty_changed` | Owner edits subscription |

All notifications are suppressed (not sent) if `customers.whatsapp_enabled = false` for that customer.

---

## 6. API Surface

The following endpoints must be implemented. The DBMS Architect and Laravel Engineer will spec the request/response contracts in detail. All responses follow the existing envelope:

```json
{ "success": true, "data": { ... } }
```

Error responses:

```json
{ "success": false, "message": "...", "errors": { ... } }
```

### Auth (unauthenticated routes)

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/customer/v1/auth/send-otp` | Send OTP to mobile number |
| POST | `/api/customer/v1/auth/verify-otp` | Verify OTP; mark `mobile_verified_at` |
| POST | `/api/customer/v1/auth/set-pin` | Set PIN after OTP verification (first time or forgot) |
| POST | `/api/customer/v1/auth/login` | Mobile + PIN → issue Sanctum token |

### Authenticated routes (customer guard)

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/customer/v1/dashboard` | Outstanding balance, monthly summary, active subscriptions |
| GET | `/api/customer/v1/orders?month=YYYY-MM` | Order log for a given month (defaults to current) |
| PUT | `/api/customer/v1/orders/{date}/qty` | Change qty for a specific date (shift + schedule time enforced server-side) |
| POST | `/api/customer/v1/orders/{date}/skip` | Mark a single future date as skipped |
| GET | `/api/customer/v1/vacation` | Get current vacation dates |
| POST | `/api/customer/v1/vacation` | Set vacation (start + end) |
| DELETE | `/api/customer/v1/vacation` | Cancel (clear) vacation |
| GET | `/api/customer/v1/bills` | List invoices for this customer |
| GET | `/api/customer/v1/bills/{id}/image` | Return URL or redirect to bill PNG |
| GET | `/api/customer/v1/payments` | List payments for this customer |
| GET | `/api/customer/v1/profile` | Get profile data |
| PUT | `/api/customer/v1/profile` | Update name / address / whatsapp_enabled |
| GET | `/api/customer/v1/farm-contact` | Farm name, owner name, mobile (for contact card + UPI QR) |

---

## 7. Constraints and Business Rules

### 7.1 Customer ↔ Farm

- Every customer belongs to exactly one farm (`customers.farm_id` FK to `farms.id`).
- All API queries for a customer's data are scoped to their `farm_id`. A customer can never read another farm's data.

### 7.2 Auth guard isolation

- Customer authenticatable: `App\Models\Customer` (to be upgraded to extend `Authenticatable` + `HasApiTokens`).
- Guard name: `customer` (defined in `config/auth.php`).
- Owner guard name: `farm_owner` (existing, unchanged).
- Middleware on customer routes: `auth:sanctum` with the `customer` guard.
- A token issued for one guard cannot authenticate the other.

### 7.3 Address change rate-limit

- Column `customers.last_address_change_at` (`timestamp`, nullable).
- On `PUT /api/customer/v1/profile` with any address field changed:
  - If `last_address_change_at` is not null and `now() - last_address_change_at < 24 hours`: return HTTP 422 with message "Address can only be updated once every 24 hours."
  - Otherwise: save address, set `last_address_change_at = now()`, send owner notification.
- Name changes and `whatsapp_enabled` changes are never rate-limited.

### 7.4 Qty change lock

- The server evaluates the lock on `PUT /api/customer/v1/orders/{date}/qty` and `POST /api/customer/v1/orders/{date}/skip`:
  - Determine the subscription line's shift (`morning` or `evening`).
  - Load `farms.morning_schedule_time` or `farms.evening_schedule_time` for this customer's farm.
  - Compare `now()` (in farm timezone) against the schedule time.
  - Morning: editable date is tomorrow. If today's current time >= `morning_schedule_time`, reject with HTTP 422 "Order already submitted — changes are locked until tomorrow."
  - Evening: editable date is today. If today's current time >= `evening_schedule_time`, reject with HTTP 422 "Order already submitted — changes are locked."
- Client UI mirrors this check but server is authoritative.

### 7.5 Single-day skip constraints (server-side)

1. `skip_date > today` — else HTTP 422 "Cannot skip a past or current-day delivery."
2. `skip_date` not within `[vacation_start, vacation_end]` — else HTTP 422 "That day is already within your vacation hold."
3. `skip_date <= today + 7 days` — else HTTP 422 "Skips can only be set up to 7 days in advance."

### 7.6 Vacation constraints (server-side)

1. `vacation_start > today` — else HTTP 422 "Vacation start must be in the future."
2. `vacation_end >= vacation_start` — else HTTP 422 "Vacation end must be on or after vacation start."
3. No overlapping vacation — check if existing `vacation_start` / `vacation_end` is not null; if so return HTTP 422 "You already have an active vacation. Cancel it before setting a new one."

### 7.7 Response envelope

All endpoints return:

```json
{ "success": true, "data": { ... } }
```

or on error:

```json
{ "success": false, "message": "Human-readable message", "errors": { "field": ["detail"] } }
```

This matches the existing owner API envelope exactly.

### 7.8 Multiple subscription lines

A customer may have more than one active subscription (e.g., morning milk + evening curd). The order log screen displays a separate qty control for **each subscription line**. The `PUT /api/customer/v1/orders/{date}/qty` request body must include a `subscription_line_id` to identify which line is being changed. The shift lock check uses that line's shift.

---

## 8. Out of Scope for MVP

The following items are explicitly deferred. They must not be designed into the MVP schema or API in ways that would block them later, but they are not to be built now.

| Item | Reason for deferral |
|---|---|
| FCM push notifications | Requires FCM setup + device token management |
| Referral / coupon code entry | Business feature not ready |
| Driver delivery status ("delivered today") | Requires driver app + driver flow not yet in system |
| Order / payment history beyond 12 months | Data volume concern; can be paged in later |

---

## 9. Design and Platform

- **Platform:** Flutter 3 (Android + iOS), same as the existing owner app.
- **Theme:** Identical colour scheme, typography, and component style as the owner app. The UX/UI Designer will produce screen specs that match the owner app's design language.
- **State management:** Riverpod (same as owner app).
- **Routing:** go_router (same as owner app).
- **HTTP client:** Dio (same as owner app), using the existing `DioProvider` pattern with a separate base URL path prefix (`/api/customer/v1/`).
- **Auth token storage:** Same secure storage pattern as the owner app; tokens keyed separately so owner and customer sessions do not collide on the same device.
