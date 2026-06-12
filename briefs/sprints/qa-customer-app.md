# QA Test Plan — LactoSync Customer App (Sprint CA)

> **Author:** QA Engineer
> **Date:** 2026-06-06
> **Sprint:** CA
> **PRD:** `briefs/requirements/customer-app.md`
> **UX Spec:** `briefs/specs/ux-customer-app.md`
> **Sprint plan:** `briefs/sprints/sprint-customer-app.md`
> **Stories covered:** CA-02, CA-03, CA-04, CA-05, CA-06, CA-07, CA-08, CA-09, CA-10, CA-11, CA-12, CA-13, CA-14, CA-15, CA-16, CA-17

---

## Legend

- **Pass/Fail** column: `[ ]` = not yet run · `[P]` = pass · `[F]` = fail
- **Area** abbreviations: Auth, Dashboard, OrderLog, QtyChange, Skip, Vacation, Bills, Payments, Profile, Security, EdgeCase
- All API paths are relative to the server base URL.
- "Customer token" = Sanctum token obtained from `POST /api/customer/v1/auth/login` or `set-pin`.
- "Owner token" = Sanctum token obtained from owner login flow.
- HTTP status codes are verified in the response; body envelope `{success, data/message}` verified where specified.

---

## 1. Auth (CA-02, CA-11)

---

### TC-CA-001

| Field | Content |
|---|---|
| **ID** | TC-CA-001 |
| **Story** | CA-02, CA-11 |
| **Area** | Auth |
| **Title** | First-time login: OTP → set PIN → land on dashboard |
| **Precondition** | A customer row exists in `customers` with a known `contact` (10-digit mobile). `pin` is null (customer has never logged in). The app is installed with no stored `customer_auth_token`. |
| **Steps** | 1. Launch app — splash routes to `/customer/login`. <br> 2. Tap "New here? Send OTP first" → navigate to `/customer/otp`. <br> 3. Enter the registered 10-digit mobile number, tap "Send OTP". <br> 4. Observe WhatsApp message arrives on the registered number with a 6-digit OTP. <br> 5. Navigate to `/customer/otp/verify`, enter the received OTP, tap "Verify OTP". <br> 6. On success, navigate to `/customer/set-pin`. Enter a 4-digit PIN and confirm it, tap "Save PIN". <br> 7. Observe navigation to `/customer/home` (dashboard). |
| **Expected result** | Step 3: `POST /api/customer/v1/auth/send-otp` returns HTTP 200 `{success:true}`. A WhatsApp OTP message is received. Step 5: `POST /api/customer/v1/auth/verify-otp` returns HTTP 200 with a session token or verification flag. `customers.mobile_verified_at` is set. Step 6: `POST /api/customer/v1/auth/set-pin` returns HTTP 200 with a Sanctum token. App stores token as `customer_auth_token` in secure storage. Step 7: Dashboard screen renders with customer data. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-002

| Field | Content |
|---|---|
| **ID** | TC-CA-002 |
| **Story** | CA-02, CA-11 |
| **Area** | Auth |
| **Title** | Subsequent login: contact + PIN → dashboard |
| **Precondition** | Customer has a hashed PIN set in `customers.pin`. App has no stored `customer_auth_token` (cleared from storage). |
| **Steps** | 1. Launch app → splash routes to `/customer/login`. <br> 2. Enter the registered 10-digit mobile number and the correct 4-digit PIN. <br> 3. Tap "Sign in". |
| **Expected result** | `POST /api/customer/v1/auth/login` returns HTTP 200 with a Sanctum token. `customers.last_login_at` is updated to now. App navigates to `/customer/home`. Dashboard loads customer data. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-003

| Field | Content |
|---|---|
| **ID** | TC-CA-003 |
| **Story** | CA-02, CA-11 |
| **Area** | Auth |
| **Title** | Wrong PIN: returns "Invalid" error snackbar, not a crash |
| **Precondition** | Customer has a PIN set. App is on the login screen. |
| **Steps** | 1. Enter the correct mobile number. <br> 2. Enter an incorrect 4-digit PIN. <br> 3. Tap "Sign in". |
| **Expected result** | `POST /api/customer/v1/auth/login` returns HTTP 401. App shows a red error snackbar with the message "Invalid mobile number or PIN." The app remains on the login screen. No crash or unhandled exception. Token is not stored. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-004

| Field | Content |
|---|---|
| **ID** | TC-CA-004 |
| **Story** | CA-02, CA-11 |
| **Area** | Auth |
| **Title** | Expired OTP: shows "OTP has expired" message |
| **Precondition** | Customer has received an OTP. The OTP has passed its expiry time (`otp_expires_at` is in the past). App is on the OTP verify screen. |
| **Steps** | 1. Wait until the OTP has expired (or manually set `otp_expires_at` to a past timestamp in the database). <br> 2. Enter the (now-expired) OTP in the Verify OTP screen. <br> 3. Tap "Verify OTP". |
| **Expected result** | `POST /api/customer/v1/auth/verify-otp` returns HTTP 422. App shows a red error snackbar "OTP has expired. Tap Resend." The verify screen remains open. The "Resend" button is available. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-005

| Field | Content |
|---|---|
| **ID** | TC-CA-005 |
| **Story** | CA-02 |
| **Area** | Auth, Security |
| **Title** | Customer token cannot hit an owner route (guard isolation — API level) |
| **Precondition** | A valid customer Sanctum token is available (obtained from customer login). |
| **Steps** | 1. Make a `GET /api/v1/owner/customers` request with `Authorization: Bearer {customer_token}` header. |
| **Expected result** | Response is HTTP 401 or HTTP 403. The response body does not contain any customer or owner data. The owner route does not authenticate the customer token. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-006

| Field | Content |
|---|---|
| **ID** | TC-CA-006 |
| **Story** | CA-02 |
| **Area** | Auth, Security |
| **Title** | Customer token cannot hit an admin route (guard isolation — API level) |
| **Precondition** | A valid customer Sanctum token is available. |
| **Steps** | 1. Make a `GET /api/admin/v1/tenants` request with `Authorization: Bearer {customer_token}` header. |
| **Expected result** | Response is HTTP 401 or HTTP 403. Admin route does not authenticate the customer token. No admin data is returned. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-007

| Field | Content |
|---|---|
| **ID** | TC-CA-007 |
| **Story** | CA-02, CA-11 |
| **Area** | Auth |
| **Title** | Forgot PIN flow: OTP → set new PIN → old PIN no longer works |
| **Precondition** | Customer has a known PIN set (e.g. "1234"). App is on the login screen. |
| **Steps** | 1. Tap "Forgot PIN?" on the login screen. <br> 2. Enter the mobile number, tap "Send OTP". <br> 3. Enter the received OTP, tap "Verify OTP". <br> 4. Set a new PIN (e.g. "5678"), confirm it, tap "Save PIN". <br> 5. Log out (clear the stored token from secure storage). <br> 6. Return to login screen and attempt login with the old PIN "1234". |
| **Expected result** | Steps 2–4: OTP and set-pin flow succeeds; new Sanctum token issued; app navigates to dashboard. Step 6: `POST /api/customer/v1/auth/login` with old PIN returns HTTP 401. Red snackbar "Invalid mobile number or PIN." New PIN "5678" should succeed on a subsequent attempt. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-008

| Field | Content |
|---|---|
| **ID** | TC-CA-008 |
| **Story** | CA-02 |
| **Area** | Auth |
| **Title** | send-otp with unregistered mobile returns 422 |
| **Precondition** | A mobile number that does not exist in the `customers` table. |
| **Steps** | 1. Navigate to the Send OTP screen. <br> 2. Enter a mobile number not in the `customers` table. <br> 3. Tap "Send OTP". |
| **Expected result** | `POST /api/customer/v1/auth/send-otp` returns HTTP 422. App displays a red snackbar with the API `message` field (e.g. "Mobile number not registered"). No WhatsApp message is sent. |
| **Pass/Fail** | `[ ]` |

---

## 2. Dashboard (CA-03, CA-12)

---

### TC-CA-009

| Field | Content |
|---|---|
| **ID** | TC-CA-009 |
| **Story** | CA-03, CA-12 |
| **Area** | Dashboard |
| **Title** | Customer with outstanding balance: balance card and UPI QR shown |
| **Precondition** | Customer has at least one invoice with `status != 'paid'` and `balance_due > 0`. Customer is logged in and on the dashboard. |
| **Steps** | 1. Navigate to `/customer/home`. <br> 2. Wait for the dashboard to load. <br> 3. Observe the outstanding balance card at the top of the screen. |
| **Expected result** | `GET /api/customer/v1/dashboard` returns `outstanding_balance > 0`. The outstanding balance card is visible showing "You owe ₹{amount}" formatted in Indian number format with danger colour. A UPI QR code image (200×200 dp) is rendered inside the card. The text "Tap to pay via UPI" is shown below the QR. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-010

| Field | Content |
|---|---|
| **ID** | TC-CA-010 |
| **Story** | CA-03, CA-12 |
| **Area** | Dashboard |
| **Title** | Customer with zero balance: balance card hidden |
| **Precondition** | Customer has no unpaid invoices (`balance_due = 0` for all invoices, or no invoices). Customer is logged in. |
| **Steps** | 1. Navigate to `/customer/home`. <br> 2. Wait for the dashboard to load. <br> 3. Inspect the page content. |
| **Expected result** | `GET /api/customer/v1/dashboard` returns `outstanding_balance = 0` and `upi_qr_url` is absent or null. The balance card is completely absent — no placeholder space, no hidden container. Monthly summary row, subscriptions section, and quick-nav row are visible. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-011

| Field | Content |
|---|---|
| **ID** | TC-CA-011 |
| **Story** | CA-03, CA-12 |
| **Area** | Dashboard |
| **Title** | Monthly summary counts match order log for current month |
| **Precondition** | Customer has `daily_order_logs` rows for the current calendar month. Customer is logged in. Note the exact delivered and skipped counts from direct DB inspection or order log screen. |
| **Steps** | 1. Navigate to `/customer/home`. <br> 2. Read the "Delivered", "Skipped", "On vacation" counters from the summary chip row. <br> 3. Navigate to `/customer/orders` and count delivered, skipped, and vacation days for the current month. <br> 4. Compare both sets of numbers. |
| **Expected result** | The dashboard "Delivered" count matches the number of `daily_order_logs` rows with `status='delivered'` for this customer in the current UTC month. "Skipped" matches `status='skipped'` rows. "On vacation" matches calendar days that fall within `customers.vacation_start`–`vacation_end` for the current month (not from `daily_order_logs`). All three counts are integers ≥ 0. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-012

| Field | Content |
|---|---|
| **ID** | TC-CA-012 |
| **Story** | CA-03, CA-12 |
| **Area** | Dashboard |
| **Title** | Pull-to-refresh updates data |
| **Precondition** | Customer is on the dashboard screen with data already loaded. |
| **Steps** | 1. While on `/customer/home`, note the current "Delivered" count. <br> 2. Using the database or owner app, record a new delivery for today. <br> 3. Pull down on the dashboard to trigger refresh. <br> 4. Wait for the spinner to complete and data to reload. |
| **Expected result** | The `RefreshIndicator` spinner shows during data fetch. After reload, the "Delivered" counter increments to reflect the newly recorded delivery. No crash. Data is fresh (not stale). |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-013

| Field | Content |
|---|---|
| **ID** | TC-CA-013 |
| **Story** | CA-03, CA-12 |
| **Area** | Dashboard |
| **Title** | Quick-nav row: Bills and Payments tap to correct screens |
| **Precondition** | Customer is logged in and on the dashboard. |
| **Steps** | 1. Tap the "Bills" quick-nav card on the dashboard. <br> 2. Observe the navigation destination. <br> 3. Navigate back to `/customer/home`. <br> 4. Tap the "Payments" quick-nav card. <br> 5. Observe the navigation destination. |
| **Expected result** | Step 1: App switches to the Bills tab (`/customer/bills`) via `context.go`. Bottom navigation highlights the Bills tab. Step 4: App pushes the Payments screen (`/customer/payments`) with its own AppBar and a back arrow. |
| **Pass/Fail** | `[ ]` |

---

## 3. Order Log (CA-04, CA-13)

---

### TC-CA-014

| Field | Content |
|---|---|
| **ID** | TC-CA-014 |
| **Story** | CA-04, CA-13 |
| **Area** | OrderLog |
| **Title** | Morning-shift customer before morning_order_time: tomorrow's row is editable |
| **Precondition** | Customer has an active morning-shift subscription. Current time (in farm timezone) is before `farms.morning_schedule_time` (e.g. before 8:00 AM). Customer is on the Orders screen for the current month. |
| **Steps** | 1. Navigate to `/customer/orders`. <br> 2. Find tomorrow's row in the list. <br> 3. Observe the row's trailing icon and tappability. <br> 4. Tap tomorrow's row. |
| **Expected result** | Tomorrow's row shows the expected qty with `Icons.circle_outlined` trailing icon (not a lock icon). The row has an `onTap` handler. Tapping opens the day edit bottom sheet showing a qty stepper for the morning subscription line. The `locked` flag from the API for this entry is `false`. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-015

| Field | Content |
|---|---|
| **ID** | TC-CA-015 |
| **Story** | CA-04, CA-13 |
| **Area** | OrderLog |
| **Title** | Morning-shift customer after morning_order_time: tomorrow's row shows locked padlock |
| **Precondition** | Customer has an active morning-shift subscription. Current time (in farm timezone) is after `farms.morning_schedule_time` (e.g. after 8:00 AM). Customer is on the Orders screen. |
| **Steps** | 1. Navigate to `/customer/orders`. <br> 2. Find tomorrow's row. <br> 3. Observe the trailing icon. <br> 4. Tap tomorrow's row. |
| **Expected result** | Tomorrow's row shows `Icons.lock_outline` as the trailing icon. Tapping the row shows a snackbar "Changes are locked — order already submitted." and does NOT open the edit bottom sheet. The `locked` flag from the API for this entry is `true`. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-016

| Field | Content |
|---|---|
| **ID** | TC-CA-016 |
| **Story** | CA-04, CA-13 |
| **Area** | OrderLog |
| **Title** | Evening-shift customer before evening_order_time: today's row is editable |
| **Precondition** | Customer has an active evening-shift subscription. Current time (in farm timezone) is before `farms.evening_schedule_time` (e.g. before 5:00 PM). Customer is on the Orders screen. |
| **Steps** | 1. Navigate to `/customer/orders`. <br> 2. Find today's row in the list. <br> 3. Observe the trailing icon and tappability. <br> 4. Tap today's row. |
| **Expected result** | Today's row is tappable with `Icons.circle_outlined` trailing icon. Tapping opens the edit bottom sheet with a qty stepper for the evening subscription line. The `locked` flag from the API is `false`. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-017

| Field | Content |
|---|---|
| **ID** | TC-CA-017 |
| **Story** | CA-04, CA-13 |
| **Area** | OrderLog |
| **Title** | Vacation days show "On vacation" status |
| **Precondition** | Customer has `vacation_start` and `vacation_end` set on their row, covering at least one day in the current month. Customer is on the Orders screen. |
| **Steps** | 1. Navigate to `/customer/orders`. <br> 2. Find a day that falls within the customer's vacation range. <br> 3. Observe the row's title text and trailing icon. |
| **Expected result** | The row shows "On vacation" text in `AppColors.primary` colour and `Icons.beach_access_outlined` trailing icon also in `primary` colour. The row has no `onTap` handler. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-018

| Field | Content |
|---|---|
| **ID** | TC-CA-018 |
| **Story** | CA-04, CA-13 |
| **Area** | OrderLog |
| **Title** | Delivered days show green tick and are not editable |
| **Precondition** | Customer has at least one `daily_order_logs` row with `status='delivered'` in the current month. |
| **Steps** | 1. Navigate to `/customer/orders`. <br> 2. Find a delivered day. <br> 3. Observe the row's title and trailing icon. <br> 4. Attempt to tap the row. |
| **Expected result** | The row shows qty text in `ink` colour and `Icons.check_circle_rounded` trailing icon in `AppColors.success` (green). Tapping the row does nothing (no bottom sheet opens, no snackbar). |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-019

| Field | Content |
|---|---|
| **ID** | TC-CA-019 |
| **Story** | CA-04, CA-13 |
| **Area** | OrderLog |
| **Title** | Month navigation: previous month loads correct data |
| **Precondition** | Customer has order log data for the previous month. Customer is on the Orders screen showing the current month. |
| **Steps** | 1. Navigate to `/customer/orders`. <br> 2. Tap the left chevron (`Icons.chevron_left`) in the month navigation header. <br> 3. Wait for the list to reload. <br> 4. Observe the month header text and the day rows. |
| **Expected result** | The month header text updates to the previous month and year (e.g. "May 2026"). A loading indicator is shown while fetching. The day list shows the correct number of calendar days for that month. Delivered/skipped/vacation statuses reflect data for the previous month only. `GET /api/customer/v1/orders?month=YYYY-MM` is called with the previous month's value. |
| **Pass/Fail** | `[ ]` |

---

## 4. Qty Change (CA-07, CA-13)

---

### TC-CA-020

| Field | Content |
|---|---|
| **ID** | TC-CA-020 |
| **Story** | CA-07, CA-13 |
| **Area** | QtyChange |
| **Title** | Change qty to 2 → API updates → row shows new qty |
| **Precondition** | Customer has an unlocked future editable day (see TC-CA-014 or TC-CA-016 for preconditions). Current qty for the subscription line on that day is 1. |
| **Steps** | 1. Navigate to `/customer/orders` and tap the target unlocked future day. <br> 2. In the edit bottom sheet, tap the "+" stepper button twice to change qty from 1 to 2 (or set to 2 directly). <br> 3. Verify the stepper shows "2". <br> 4. Tap "Save". <br> 5. Observe the bottom sheet closing and the day row. |
| **Expected result** | `PUT /api/customer/v1/orders/{date}/qty` is called with `{subscription_line_id, qty: 2}`. Response is HTTP 200 `{success:true}`. Bottom sheet closes. The corresponding day row in the order list refreshes and shows "2" (or the qty label for that line). A `daily_order_logs` upsert has occurred with `qty=2` and `status` not `skipped`. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-021

| Field | Content |
|---|---|
| **ID** | TC-CA-021 |
| **Story** | CA-07, CA-13 |
| **Area** | QtyChange |
| **Title** | Change qty to 0 → treated as skip (status becomes skipped) |
| **Precondition** | Customer has an unlocked future editable day with qty > 0. |
| **Steps** | 1. Navigate to `/customer/orders` and tap the target unlocked future day. <br> 2. In the edit bottom sheet, tap the "−" stepper until qty shows "0" (decrement button should become disabled at 0). <br> 3. Tap "Save". |
| **Expected result** | `PUT /api/customer/v1/orders/{date}/qty` is called with `{subscription_line_id, qty: 0}`. Response is HTTP 200. The `daily_order_logs` record for that date is upserted with `qty=0, status='skipped'`. The day row refreshes to show "Skipped" label with warning colour. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-022

| Field | Content |
|---|---|
| **ID** | TC-CA-022 |
| **Story** | CA-07, CA-13 |
| **Area** | QtyChange |
| **Title** | Attempt to change qty after lock time → 422 shown as snackbar |
| **Precondition** | The target date's shift lock time has passed (e.g. morning customer, time is after `morning_schedule_time`). Despite the `locked` flag, a direct API call is made (bypassing the UI lock). |
| **Steps** | 1. Directly call `PUT /api/customer/v1/orders/{date}/qty` with a valid `subscription_line_id` and `qty: 1` for a date that is now locked (lock time has passed). <br> *(Alternatively: set device clock forward past lock time with the edit sheet still open and tap Save.)* |
| **Expected result** | `PUT /api/customer/v1/orders/{date}/qty` returns HTTP 422 with message "Order already submitted — changes are locked." In the Flutter app, the error snackbar is shown with this message in danger colour. The bottom sheet closes (per UX spec: close sheet, then show error snackbar). |
| **Pass/Fail** | `[ ]` |

---

## 5. Single-Day Skip (CA-08, CA-13)

---

### TC-CA-023

| Field | Content |
|---|---|
| **ID** | TC-CA-023 |
| **Story** | CA-08, CA-13 |
| **Area** | Skip |
| **Title** | Skip a future date (within 7 days) → day shows "Skipped" |
| **Precondition** | Customer has a future date that is: strictly after today, within 7 days from today, not within a vacation range, and not already delivered. Customer is on the Orders screen. |
| **Steps** | 1. Navigate to `/customer/orders`. <br> 2. Tap a future unlocked day that satisfies the precondition. <br> 3. In the edit bottom sheet, tap "Skip this day". |
| **Expected result** | `POST /api/customer/v1/orders/{date}/skip` returns HTTP 200 `{success:true}`. Bottom sheet closes. The day row updates to "Skipped" status with warning colour and `Icons.remove_circle_outline` trailing icon. A `daily_order_logs` record exists with `qty=0, status='skipped'` for that date. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-024

| Field | Content |
|---|---|
| **ID** | TC-CA-024 |
| **Story** | CA-08, CA-13 |
| **Area** | Skip |
| **Title** | Skip a past date → 422 "Date must be in the future" |
| **Precondition** | A past date (at least yesterday). |
| **Steps** | 1. Directly call `POST /api/customer/v1/orders/{yesterday}/skip` with a valid customer token. |
| **Expected result** | Response is HTTP 422 with message "Cannot skip a past or current-day delivery." |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-025

| Field | Content |
|---|---|
| **ID** | TC-CA-025 |
| **Story** | CA-08, CA-13 |
| **Area** | Skip |
| **Title** | Skip a date more than 7 days ahead → 422 "Cannot skip more than 7 days" |
| **Precondition** | A date that is today + 8 or more calendar days. |
| **Steps** | 1. Directly call `POST /api/customer/v1/orders/{today+8}/skip` with a valid customer token. |
| **Expected result** | Response is HTTP 422 with message "Skips can only be set up to 7 days in advance." |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-026

| Field | Content |
|---|---|
| **ID** | TC-CA-026 |
| **Story** | CA-08, CA-13 |
| **Area** | Skip |
| **Title** | Skip a date within vacation range → 422 "Cannot skip during vacation" |
| **Precondition** | Customer has an active vacation with `vacation_start` = tomorrow and `vacation_end` = today + 5. The target skip date falls within this range (e.g. today + 3). |
| **Steps** | 1. Directly call `POST /api/customer/v1/orders/{today+3}/skip` with a valid customer token. |
| **Expected result** | Response is HTTP 422 with message "That day is already within your vacation hold." |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-027

| Field | Content |
|---|---|
| **ID** | TC-CA-027 |
| **Story** | CA-08 |
| **Area** | Skip |
| **Title** | Skip an already-delivered day → 422 "Cannot skip a day already delivered" |
| **Precondition** | A `daily_order_logs` row exists for a past date with `status='delivered'` for this customer. The date must be in the future for the skip window (use a test setup where a "delivered" record exists on a technically future date, or advance date accordingly). |
| **Steps** | 1. Directly call `POST /api/customer/v1/orders/{delivered_date}/skip` with a valid customer token. |
| **Expected result** | Response is HTTP 422 with message "Cannot skip a day that has already been delivered." |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-028

| Field | Content |
|---|---|
| **ID** | TC-CA-028 |
| **Story** | CA-08 |
| **Area** | Skip |
| **Title** | Skip an already-skipped day → idempotent HTTP 200 |
| **Precondition** | A `daily_order_logs` row exists for a future date with `status='skipped'` for this customer. |
| **Steps** | 1. Directly call `POST /api/customer/v1/orders/{already_skipped_date}/skip` with a valid customer token. |
| **Expected result** | Response is HTTP 200 `{success:true}`. No duplicate record is created. Existing `status='skipped'` record is unchanged. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-029

| Field | Content |
|---|---|
| **ID** | TC-CA-029 |
| **Story** | CA-13 |
| **Area** | Skip |
| **Title** | Flutter: each 422 skip error shows distinct snackbar message |
| **Precondition** | Customer is using the Flutter app's skip button. |
| **Steps** | 1. Trigger each of the three 422 skip cases via the Flutter UI (using dates that will trigger each validation): past-date skip (TC-CA-024 scenario), vacation-range skip (TC-CA-026 scenario), 7+ days skip (TC-CA-025 scenario). <br> 2. For each, tap "Skip this day" in the edit bottom sheet. |
| **Expected result** | For each scenario: the bottom sheet closes and a distinct red snackbar appears with the exact API `message` text. Three different messages are shown for three different failure cases. |
| **Pass/Fail** | `[ ]` |

---

## 6. Vacation (CA-09, CA-14)

---

### TC-CA-030

| Field | Content |
|---|---|
| **ID** | TC-CA-030 |
| **Story** | CA-09, CA-14 |
| **Area** | Vacation |
| **Title** | Set vacation: valid future dates → success, UI transitions to "vacation active" view |
| **Precondition** | Customer has no active vacation (`vacation_start` and `vacation_end` are null). Customer is on the Vacation screen (State A — no vacation set). |
| **Steps** | 1. Navigate to the Profile tab → tap "Manage vacation". <br> 2. Tap the "From" field, select a date that is tomorrow or later. <br> 3. Tap the "Until" field, select a date on or after the "From" date. <br> 4. Tap "Set vacation". |
| **Expected result** | `POST /api/customer/v1/vacation` is called with `{vacation_start, vacation_end}`. Response is HTTP 200 `{success:true}`. The `customers` row has `vacation_start` and `vacation_end` set. The vacation screen transitions to State B ("On vacation" active card). A success snackbar "Vacation set. You'll receive a WhatsApp confirmation." is shown. WhatsApp notification (`lacto_sync_vacation_set`) is sent to the customer (if `whatsapp_enabled = true`). |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-031

| Field | Content |
|---|---|
| **ID** | TC-CA-031 |
| **Story** | CA-09, CA-14 |
| **Area** | Vacation |
| **Title** | Set vacation with start date = today → 422 error |
| **Precondition** | Customer has no active vacation. |
| **Steps** | 1. Directly call `POST /api/customer/v1/vacation` with `{vacation_start: today, vacation_end: today+5}` and a valid customer token. |
| **Expected result** | Response is HTTP 422 with message "Vacation start must be in the future." `customers.vacation_start` and `vacation_end` remain null. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-032

| Field | Content |
|---|---|
| **ID** | TC-CA-032 |
| **Story** | CA-09, CA-14 |
| **Area** | Vacation |
| **Title** | Set vacation when one already exists → 422 "A vacation is already set" |
| **Precondition** | Customer already has an active vacation (`vacation_start` and `vacation_end` are not null). |
| **Steps** | 1. Directly call `POST /api/customer/v1/vacation` with a new `{vacation_start, vacation_end}` and a valid customer token. |
| **Expected result** | Response is HTTP 422 with message "You already have an active vacation. Cancel it before setting a new one." Existing vacation dates are unchanged. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-033

| Field | Content |
|---|---|
| **ID** | TC-CA-033 |
| **Story** | CA-09, CA-14 |
| **Area** | Vacation |
| **Title** | Cancel vacation → both fields cleared, no notification, UI transitions to "no vacation" state |
| **Precondition** | Customer has an active vacation. Customer is on the Vacation screen in State B (vacation active). |
| **Steps** | 1. Navigate to `/customer/vacation`. Observe the active vacation card. <br> 2. Tap "Cancel vacation". |
| **Expected result** | `DELETE /api/customer/v1/vacation` is called. Response is HTTP 200 `{success:true}`. `customers.vacation_start` and `vacation_end` are set to null. The vacation screen transitions to State A (date picker form). A snackbar "Vacation cancelled." is shown. No WhatsApp notification is sent to the customer. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-034

| Field | Content |
|---|---|
| **ID** | TC-CA-034 |
| **Story** | CA-09 |
| **Area** | Vacation |
| **Title** | Cancel vacation when no vacation exists → idempotent HTTP 200 |
| **Precondition** | Customer has no active vacation (`vacation_start` and `vacation_end` are null). |
| **Steps** | 1. Directly call `DELETE /api/customer/v1/vacation` with a valid customer token. |
| **Expected result** | Response is HTTP 200 `{success:true}`. No errors. Database state is unchanged (both vacation fields remain null). |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-035

| Field | Content |
|---|---|
| **ID** | TC-CA-035 |
| **Story** | CA-09, CA-14 |
| **Area** | Vacation |
| **Title** | Client-side date picker enforces: start >= tomorrow and end >= start |
| **Precondition** | Customer is on the Vacation screen (State A). |
| **Steps** | 1. Tap the "From" date picker. <br> 2. Observe the minimum selectable date. <br> 3. Select a "From" date (e.g. day after tomorrow). <br> 4. Tap the "Until" date picker. <br> 5. Observe the minimum selectable date. |
| **Expected result** | Step 2: `firstDate` in the date picker is tomorrow — today's date is greyed out / not selectable. Step 5: `firstDate` in the "Until" picker equals the selected "From" date — dates before "From" are not selectable. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-036

| Field | Content |
|---|---|
| **ID** | TC-CA-036 |
| **Story** | CA-09, CA-14 |
| **Area** | Vacation |
| **Title** | "Set vacation" button disabled until both dates selected |
| **Precondition** | Customer is on the Vacation screen (State A) with no dates selected. |
| **Steps** | 1. Observe the "Set vacation" button state before any date is selected. <br> 2. Select only the "From" date. <br> 3. Observe the button state again. <br> 4. Select the "Until" date. <br> 5. Observe the button state. |
| **Expected result** | Step 1: Button is greyed/disabled. Step 3: Button is still greyed/disabled (only one date selected). Step 5: Button becomes enabled (both dates selected). |
| **Pass/Fail** | `[ ]` |

---

## 7. Bills + Image (CA-05, CA-15)

---

### TC-CA-037

| Field | Content |
|---|---|
| **ID** | TC-CA-037 |
| **Story** | CA-05, CA-15 |
| **Area** | Bills |
| **Title** | Bills list shows correct months, amounts, and status badges ordered newest first |
| **Precondition** | Customer has at least two invoices in the database across different months. Customer is logged in. |
| **Steps** | 1. Navigate to the Bills tab (`/customer/bills`). <br> 2. Inspect the list of bill cards. |
| **Expected result** | `GET /api/customer/v1/bills` returns invoices ordered by `billing_month` descending. The most recent month appears first. Each card displays: billing month formatted as "June 2026", total amount formatted as "₹X,XXX", balance due formatted as "₹X,XXX" (in danger colour if > 0, ink if 0), and a status badge (Paid/Partial/Unpaid) with correct colour coding. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-038

| Field | Content |
|---|---|
| **ID** | TC-CA-038 |
| **Story** | CA-05, CA-15 |
| **Area** | Bills |
| **Title** | Tap bill → image viewer opens with bill PNG |
| **Precondition** | Customer has an invoice that has a corresponding bill image stored. Customer is on the Bills screen. |
| **Steps** | 1. Navigate to `/customer/bills`. <br> 2. Tap a bill card that has a known image. <br> 3. Wait for the image viewer screen to load. <br> 4. Attempt to pinch-to-zoom the image. |
| **Expected result** | `GET /api/customer/v1/bills/{id}/image` returns HTTP 200 with a valid image URL or signed URL. The bill image viewer screen (`/customer/bills/{id}/view`) is pushed with an AppBar title "Bill — {billingMonth}". The bill PNG is rendered in an `InteractiveViewer`. Pinch-to-zoom works (min scale 0.5, max scale 4.0). A loading indicator is shown while the image streams in. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-039

| Field | Content |
|---|---|
| **ID** | TC-CA-039 |
| **Story** | CA-05, CA-15 |
| **Area** | Bills |
| **Title** | Bill with no image → "Bill not available" shown |
| **Precondition** | Customer has an invoice that has no corresponding bill image file on disk/S3. |
| **Steps** | 1. Navigate to `/customer/bills`. <br> 2. Tap the bill card that has no image. |
| **Expected result** | `GET /api/customer/v1/bills/{id}/image` returns HTTP 404. The bill image viewer screen shows the error state: `Icon(Icons.image_not_supported_outlined)` and "Bill image not available" text in `inkMuted` colour. No crash. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-040

| Field | Content |
|---|---|
| **ID** | TC-CA-040 |
| **Story** | CA-05 |
| **Area** | Bills, Security |
| **Title** | Customer cannot access another customer's bill image (403) |
| **Precondition** | Customer A has a valid token. Customer B has a different invoice in the same or different farm. Invoice ID belongs to Customer B. |
| **Steps** | 1. Using Customer A's token, call `GET /api/customer/v1/bills/{invoice_id_belonging_to_customer_B}/image`. |
| **Expected result** | Response is HTTP 403. No image URL is returned. Customer A's token cannot access Customer B's bill. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-041

| Field | Content |
|---|---|
| **ID** | TC-CA-041 |
| **Story** | CA-05, CA-15 |
| **Area** | Bills |
| **Title** | Bills screen: empty state when customer has no invoices |
| **Precondition** | Customer has no invoices in the database. |
| **Steps** | 1. Navigate to the Bills tab. <br> 2. Observe the screen content. |
| **Expected result** | Screen shows the empty state: `Icon(Icons.receipt_long_outlined, size: 64, color: inkFaint)` and "No bills yet" text in `inkMuted`. No list items are rendered. No crash. |
| **Pass/Fail** | `[ ]` |

---

## 8. Payments (CA-05, CA-16)

---

### TC-CA-042

| Field | Content |
|---|---|
| **ID** | TC-CA-042 |
| **Story** | CA-05, CA-16 |
| **Area** | Payments |
| **Title** | Payments list shows correct entries, newest first |
| **Precondition** | Customer has at least two payments recorded by the owner on different dates. Customer is logged in. |
| **Steps** | 1. Navigate to the Payments screen (via dashboard "Payments" quick-nav card or other navigation). <br> 2. Inspect the list of payment cards. |
| **Expected result** | `GET /api/customer/v1/payments` returns payments ordered by `payment_date` descending. The most recent payment appears first. Each card shows: amount formatted as "₹X,XXX" in success green, payment date formatted as "D Mon YYYY", method badge with correct colour (Cash = warning, UPI = primary), and note (if non-null and non-empty). The screen is read-only — no add/edit/delete controls. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-043

| Field | Content |
|---|---|
| **ID** | TC-CA-043 |
| **Story** | CA-05, CA-16 |
| **Area** | Payments |
| **Title** | Empty state shown for customer with no payments |
| **Precondition** | Customer has no recorded payments. |
| **Steps** | 1. Navigate to the Payments screen. <br> 2. Observe the screen content. |
| **Expected result** | Screen shows the empty state: `Icon(Icons.payments_outlined, size: 64, color: inkFaint)` and "No payments recorded yet" text in `inkMuted`. No list items. No crash. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-044

| Field | Content |
|---|---|
| **ID** | TC-CA-044 |
| **Story** | CA-05, CA-16 |
| **Area** | Payments |
| **Title** | Pull-to-refresh on Payments screen triggers fresh fetch |
| **Precondition** | Customer has payments loaded on the Payments screen. |
| **Steps** | 1. Open the Payments screen. <br> 2. Owner records a new payment for this customer via the owner app. <br> 3. Pull down on the Payments screen to trigger refresh. |
| **Expected result** | `RefreshIndicator` spinner shows during fetch. After reload, the newly recorded payment appears at the top of the list. No crash. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-045

| Field | Content |
|---|---|
| **ID** | TC-CA-045 |
| **Story** | CA-05 |
| **Area** | Payments |
| **Title** | No create/update/delete payment routes exist on customer guard |
| **Precondition** | A valid customer token. |
| **Steps** | 1. Attempt `POST /api/customer/v1/payments` with a valid customer token and a payment body. <br> 2. Attempt `PUT /api/customer/v1/payments/1` with a valid customer token. <br> 3. Attempt `DELETE /api/customer/v1/payments/1` with a valid customer token. |
| **Expected result** | All three requests return HTTP 404 (route does not exist) or HTTP 405 (method not allowed). None return HTTP 200 or any payment mutation. |
| **Pass/Fail** | `[ ]` |

---

## 9. Profile (CA-06, CA-17)

---

### TC-CA-046

| Field | Content |
|---|---|
| **ID** | TC-CA-046 |
| **Story** | CA-06, CA-17 |
| **Area** | Profile |
| **Title** | View profile: all fields correct |
| **Precondition** | Customer has a known profile in the database. Customer is logged in. |
| **Steps** | 1. Navigate to the Profile tab (`/customer/profile`). <br> 2. Wait for data to load. <br> 3. Compare each displayed field against the database values. |
| **Expected result** | `GET /api/customer/v1/profile` returns data. Profile header card shows: avatar with initials (first char of first_name + first char of last_name, uppercase), full name, mobile number in muted text. WhatsApp toggle reflects `whatsapp_enabled`. Subscriptions section lists all active subscription lines (product + shift + qty). Dairy contact card shows farm name and owner full name. No mobile number edit control is present anywhere on the page. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-047

| Field | Content |
|---|---|
| **ID** | TC-CA-047 |
| **Story** | CA-06, CA-17 |
| **Area** | Profile |
| **Title** | Edit name: changes saved, profile refreshes |
| **Precondition** | Customer is on the Profile screen. |
| **Steps** | 1. Tap "Edit profile" button. <br> 2. Clear the first name field and enter a new first name (e.g. "Rajesh"). <br> 3. Clear the last name field and enter a new last name (e.g. "Patel"). <br> 4. Tap "Save". |
| **Expected result** | `PUT /api/customer/v1/profile` is called with the updated `first_name` and `last_name`. Response is HTTP 200. Bottom sheet closes. A success snackbar "Profile updated." is shown. The profile header card refreshes and shows the new full name "Rajesh Patel". `customers.last_address_change_at` is NOT updated (name change does not trigger the 24-hour rate limit). |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-048

| Field | Content |
|---|---|
| **ID** | TC-CA-048 |
| **Story** | CA-06, CA-17 |
| **Area** | Profile |
| **Title** | Edit address: saved successfully |
| **Precondition** | Customer is on the Profile screen. `customers.last_address_change_at` is null or was more than 24 hours ago. |
| **Steps** | 1. Tap "Edit profile". <br> 2. Change the address line to "123 New Street". <br> 3. Tap "Save". |
| **Expected result** | `PUT /api/customer/v1/profile` is called with the new address. Response is HTTP 200. `customers.last_address_change_at` is set to now. Bottom sheet closes. Snackbar "Profile updated." shown. Profile refreshes with the new address. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-049

| Field | Content |
|---|---|
| **ID** | TC-CA-049 |
| **Story** | CA-06, CA-17 |
| **Area** | Profile |
| **Title** | Edit address second time within 24 hours: 422 rate-limit message shown inline |
| **Precondition** | Customer has updated their address within the past 24 hours (`last_address_change_at` < 24 hours ago). Customer is on the Profile screen. |
| **Steps** | 1. Tap "Edit profile". <br> 2. Change any address field (e.g. address line). <br> 3. Tap "Save". |
| **Expected result** | `PUT /api/customer/v1/profile` returns HTTP 422 with message "Address can only be updated once every 24 hours." The edit bottom sheet remains open (does not close). A red snackbar is shown with this exact message. All form fields retain their current values. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-050

| Field | Content |
|---|---|
| **ID** | TC-CA-050 |
| **Story** | CA-06, CA-17 |
| **Area** | Profile |
| **Title** | Mobile number is not editable anywhere in the UI |
| **Precondition** | Customer is on the Profile screen. |
| **Steps** | 1. Inspect the Profile screen view mode for an edit control next to the mobile number. <br> 2. Tap "Edit profile" and inspect the edit bottom sheet for a mobile/contact input field. <br> 3. Directly call `PUT /api/customer/v1/profile` with `{contact: "9999999999"}` and a valid customer token. |
| **Expected result** | Step 1: Mobile number is displayed in muted text with no edit icon/button. Step 2: No `contact` or mobile input field exists in the edit bottom sheet. Step 3: `PUT /api/customer/v1/profile` returns HTTP 200 but the `contact` field in the database is unchanged (server ignores it even if submitted). |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-051

| Field | Content |
|---|---|
| **ID** | TC-CA-051 |
| **Story** | CA-06, CA-17 |
| **Area** | Profile |
| **Title** | WhatsApp toggle off → uses optimistic update and hits profile update endpoint |
| **Precondition** | Customer has `whatsapp_enabled = true`. Customer is on the Profile screen. |
| **Steps** | 1. Observe the "Delivery notifications" switch is ON. <br> 2. Tap the switch to toggle it off. <br> 3. Observe the switch state change immediately. <br> 4. Wait briefly for the API call to complete. |
| **Expected result** | Switch flips to OFF immediately (optimistic update). `PUT /api/customer/v1/profile` is called with `{whatsapp_enabled: false}`. Response is HTTP 200. `customers.whatsapp_enabled` is set to false. No loading indicator on the switch row itself. On API success, switch stays OFF. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-052

| Field | Content |
|---|---|
| **ID** | TC-CA-052 |
| **Story** | CA-06, CA-17 |
| **Area** | Profile |
| **Title** | Farm contact card: "Call" launches dialer, "WhatsApp" launches WhatsApp |
| **Precondition** | Customer is on the Profile screen with the farm contact card visible. A test device has phone/WhatsApp apps installed. |
| **Steps** | 1. Tap the "Call" button in the dairy contact card. <br> 2. Observe the app launched. <br> 3. Navigate back to the Profile screen. <br> 4. Tap the "WhatsApp" button. <br> 5. Observe the app/URL launched. |
| **Expected result** | Step 1: Device dialer launches with the owner's mobile number pre-filled (`tel:{owner_mobile}` deep link). Step 4: WhatsApp opens a new chat with the owner's number (`https://wa.me/91{owner_mobile_stripped}` deep link). No crash. No navigation within the app itself. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-053

| Field | Content |
|---|---|
| **ID** | TC-CA-053 |
| **Story** | CA-06 |
| **Area** | Profile |
| **Title** | farm-contact endpoint returns correct farm and owner data |
| **Precondition** | Customer belongs to a farm with known farm name and owner mobile. |
| **Steps** | 1. Call `GET /api/customer/v1/farm-contact` with a valid customer token. <br> 2. Compare response fields against the database. |
| **Expected result** | Response is HTTP 200 with `{farm_name, owner_first_name, owner_last_name, owner_mobile, upi_qr_url}` matching the `farms` and `farm_owners` records linked to the customer's `farm_id`. |
| **Pass/Fail** | `[ ]` |

---

## 10. Security Test Cases (Guard Isolation)

---

### TC-CA-S01

| Field | Content |
|---|---|
| **ID** | TC-CA-S01 |
| **Story** | CA-02 |
| **Area** | Security |
| **Title** | Customer token on owner route → 401 or 403 |
| **Precondition** | A valid `customer` guard Sanctum token. The `farm_owner` guard is on `auth:sanctum` middleware for owner routes. Guard names confirmed in `config/auth.php`: `customer` (driver: sanctum, provider: customers), `farm_owner` (driver: sanctum, provider: farm_owners). |
| **Steps** | 1. Obtain a customer Sanctum token via `POST /api/customer/v1/auth/login`. <br> 2. Send `GET /api/v1/owner/customers` with header `Authorization: Bearer {customer_token}`. <br> 3. Send `GET /api/v1/owner/dashboard` with header `Authorization: Bearer {customer_token}`. |
| **Expected result** | Both requests return HTTP 401 or HTTP 403. No owner data is returned in either response. The customer token does not satisfy the `auth:sanctum` (farm_owner) guard. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-S02

| Field | Content |
|---|---|
| **ID** | TC-CA-S02 |
| **Story** | CA-02 |
| **Area** | Security |
| **Title** | Owner token on customer route → 401 or 403 |
| **Precondition** | A valid `farm_owner` guard Sanctum token (from owner login). |
| **Steps** | 1. Obtain an owner Sanctum token via owner login flow. <br> 2. Send `GET /api/customer/v1/dashboard` with header `Authorization: Bearer {owner_token}`. <br> 3. Send `GET /api/customer/v1/orders` with header `Authorization: Bearer {owner_token}`. |
| **Expected result** | Both requests return HTTP 401 or HTTP 403. No customer data is returned. The owner token does not satisfy the `auth:customer` guard. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-S03

| Field | Content |
|---|---|
| **ID** | TC-CA-S03 |
| **Story** | CA-05 |
| **Area** | Security |
| **Title** | Customer A's token for Customer B's bill image → 403 |
| **Precondition** | Customer A and Customer B exist in the database. Customer B has an invoice with a known `id`. Customer A's Sanctum token is available. |
| **Steps** | 1. Obtain Customer A's token via customer login. <br> 2. Send `GET /api/customer/v1/bills/{invoice_id_of_customer_B}/image` with Customer A's token. |
| **Expected result** | Response is HTTP 403. No image URL is returned. The server verifies invoice ownership before serving the image. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-S04

| Field | Content |
|---|---|
| **ID** | TC-CA-S04 |
| **Story** | CA-02 |
| **Area** | Security |
| **Title** | Unauthenticated request to any `auth:customer` route → 401 |
| **Precondition** | No authentication header is included in the request. |
| **Steps** | 1. Send `GET /api/customer/v1/dashboard` with no `Authorization` header. <br> 2. Send `GET /api/customer/v1/orders` with no `Authorization` header. <br> 3. Send `GET /api/customer/v1/profile` with no `Authorization` header. <br> 4. Send `GET /api/customer/v1/bills` with no `Authorization` header. <br> 5. Send `GET /api/customer/v1/vacation` with no `Authorization` header. |
| **Expected result** | All five requests return HTTP 401. No data is exposed. Response body is `{success: false, message: "Unauthenticated."}` or equivalent. |
| **Pass/Fail** | `[ ]` |

---

## 11. Edge Cases

---

### TC-CA-054

| Field | Content |
|---|---|
| **ID** | TC-CA-054 |
| **Story** | CA-03, CA-04, CA-12, CA-13 |
| **Area** | EdgeCase |
| **Title** | Customer with no active subscriptions: dashboard shows empty subscriptions, order log shows no entries |
| **Precondition** | Customer exists in the database but has no active `SubscriptionLine` records. Customer is logged in. |
| **Steps** | 1. Navigate to `/customer/home`. <br> 2. Inspect the "Active subscriptions" section. <br> 3. Navigate to `/customer/orders`. <br> 4. Inspect the day rows. |
| **Expected result** | Dashboard `active_subscriptions` array is empty. The subscriptions card shows "No active subscriptions" in `inkMuted`. Order log day rows show no subscription entries (entries array empty). No crash. All other dashboard sections (monthly summary, quick-nav) render correctly. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-055

| Field | Content |
|---|---|
| **ID** | TC-CA-055 |
| **Story** | CA-04, CA-07, CA-13 |
| **Area** | EdgeCase |
| **Title** | Customer with two subscription lines (morning + evening): both show in order log, edit sheet, and dashboard |
| **Precondition** | Customer has two active `SubscriptionLine` records: one `morning` shift (e.g. Full Cream Milk, qty 1) and one `evening` shift (e.g. Curd, qty 1). Customer is logged in. |
| **Steps** | 1. Navigate to `/customer/home`. <br> 2. Inspect the "Active subscriptions" section. <br> 3. Navigate to `/customer/orders`. <br> 4. Tap an unlocked future day. <br> 5. Inspect the edit bottom sheet. |
| **Expected result** | Step 2: Dashboard shows two subscription line rows (morning milk + evening curd). Step 3: Each day row in the order log shows both subscription entries stacked in the title column (e.g. "Full Cream Milk: 1" and "Curd: 1"). Step 5: Edit bottom sheet shows two separate stepper rows — one for each subscription line with the correct product name and shift label. The lock note per line reflects each line's shift schedule time. Saving a qty change calls the API once per changed line. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-056

| Field | Content |
|---|---|
| **ID** | TC-CA-056 |
| **Story** | CA-10 |
| **Area** | EdgeCase, Vacation |
| **Title** | Vacation ends today: scheduler clears vacation (manual verification — see Manual Verification section) |
| **Precondition** | A customer row has `vacation_end = CURDATE()` (today). The scheduler command `customer:clear-ended-vacations` is registered and will run at 07:00 AM server time. |
| **Steps** | 1. Set up a customer with `vacation_end = today` directly in the database. <br> 2. Run `php artisan customer:clear-ended-vacations` manually (or wait for the 07:00 AM scheduled run). <br> 3. Inspect `customers` row after the command runs. <br> 4. Inspect WhatsApp delivery (if `whatsapp_enabled = true`). |
| **Expected result** | After the command runs: `customers.vacation_start = null` and `customers.vacation_end = null`. The command log shows "1 customer processed." A `lacto_sync_vacation_ended` WhatsApp notification was sent to the customer. A customer with `vacation_end = tomorrow` is NOT affected (their vacation dates remain unchanged). |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-057

| Field | Content |
|---|---|
| **ID** | TC-CA-057 |
| **Story** | CA-04 |
| **Area** | EdgeCase |
| **Title** | Order log API scoping: requesting another customer's data returns only authenticated customer's data |
| **Precondition** | Two customers (A and B) exist in the same farm. Customer A's token is available. Customer B has orders for the current month that Customer A does not have. |
| **Steps** | 1. Using Customer A's token, call `GET /api/customer/v1/orders?month=YYYY-MM`. <br> 2. Attempt to add a `?customer_id={customer_B_id}` query parameter and repeat the call. |
| **Expected result** | Both calls return only Customer A's order data. The extra `customer_id` parameter is ignored. Customer B's data is not present in either response. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-058

| Field | Content |
|---|---|
| **ID** | TC-CA-058 |
| **Story** | CA-03 |
| **Area** | EdgeCase |
| **Title** | Dashboard API scoping: customer cannot see another farm's data |
| **Precondition** | Customer belongs to Farm A. Farm B exists with a different customer who has payments and subscriptions. |
| **Steps** | 1. Using Customer A's (Farm A) token, call `GET /api/customer/v1/dashboard`. <br> 2. Inspect the `outstanding_balance`, `active_subscriptions`, and `monthly_summary` in the response. |
| **Expected result** | All data returned is scoped to Customer A's `farm_id`. No data from Farm B appears. The `active_subscriptions` list contains only Customer A's lines. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-059

| Field | Content |
|---|---|
| **ID** | TC-CA-059 |
| **Story** | CA-06 |
| **Area** | EdgeCase |
| **Title** | Address change notification goes to owner regardless of customer's whatsapp_enabled flag |
| **Precondition** | Customer has `whatsapp_enabled = false`. Customer is on the Profile edit sheet. |
| **Steps** | 1. With `whatsapp_enabled = false`, save a new address via the edit profile sheet. |
| **Expected result** | `PUT /api/customer/v1/profile` returns HTTP 200 and address is saved. A WhatsApp notification is sent to the **farm owner** (not the customer) with the new address. The customer does NOT receive a WhatsApp notification (their flag is false). The owner notification is not suppressed by the customer's `whatsapp_enabled` flag. |
| **Pass/Fail** | `[ ]` |

---

## 12. UI / Navigation Conformance

---

### TC-CA-060

| Field | Content |
|---|---|
| **ID** | TC-CA-060 |
| **Story** | CA-11 |
| **Area** | Auth |
| **Title** | Auth screens match owner app design language |
| **Precondition** | Customer app is installed. Owner app design language is known (forest green primary, surface background cards, AppTextField style). |
| **Steps** | 1. Navigate through each auth screen: login, send OTP, verify OTP, set PIN. <br> 2. Compare colour tokens, button height, typography, and input field styling against the owner app. |
| **Expected result** | All four auth screens use `AppColors.primary` (#386948 light mode), `AppColors.bg` scaffold background, `AppTextField` widget styling (filled, border colour `AppColors.border`), elevated button height 48 dp, and `AppText` typography styles. No hardcoded colours or font sizes. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-061

| Field | Content |
|---|---|
| **ID** | TC-CA-061 |
| **Story** | CA-11 |
| **Area** | Auth |
| **Title** | Token stored as `customer_auth_token` — does not collide with owner token key |
| **Precondition** | Both owner app and customer app share the same device or secure storage. |
| **Steps** | 1. Log in to the owner app — confirm token is stored under key `auth_token` (or the owner's key). <br> 2. Log in to the customer app — confirm token is stored under key `customer_auth_token`. <br> 3. Inspect secure storage for both keys. |
| **Expected result** | Owner token key and customer token key are distinct strings. Clearing one does not clear the other. Customer logout does not log out the owner session, and vice versa. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-062

| Field | Content |
|---|---|
| **ID** | TC-CA-062 |
| **Story** | CA-11–CA-17 |
| **Area** | Auth |
| **Title** | Customer shell bottom nav has 4 tabs with correct routes and icons |
| **Precondition** | Customer is logged in and on the dashboard. |
| **Steps** | 1. Inspect the bottom navigation bar. <br> 2. Tap each of the 4 tabs in sequence and verify the destination route and AppBar title. |
| **Expected result** | Tab 0 (Home, `Icons.home_rounded`) → `/customer/home` — Dashboard screen. Tab 1 (Orders, `Icons.calendar_month_outlined`) → `/customer/orders` — Order log screen. Tab 2 (Bills, `Icons.receipt_long_outlined`) → `/customer/bills` — Bills screen. Tab 3 (Profile, `Icons.person_outline_rounded`) → `/customer/profile` — Profile screen. Selected tab uses `AppColors.primary` colour; unselected tabs use `AppColors.inkMuted` at 60% opacity. |
| **Pass/Fail** | `[ ]` |

---

### TC-CA-063

| Field | Content |
|---|---|
| **ID** | TC-CA-063 |
| **Story** | CA-14, CA-16 |
| **Area** | Vacation, Payments |
| **Title** | Vacation and Payments screens are pushed (not shell tabs) and have a back arrow |
| **Precondition** | Customer is logged in. |
| **Steps** | 1. Navigate to the Vacation screen (from Profile → "Manage vacation"). <br> 2. Inspect the screen's AppBar. <br> 3. Navigate back. <br> 4. Navigate to the Payments screen (from Dashboard "Payments" card). <br> 5. Inspect the AppBar. |
| **Expected result** | Both screens have an AppBar with a back arrow. The bottom navigation bar is NOT visible on either screen. Tapping the back arrow returns to the previous screen. The bottom navigation is visible only within the 4-tab shell. |
| **Pass/Fail** | `[ ]` |

---

## 13. Manual Verification Required

The following test cases cannot be fully automated. They require manual setup, scheduled execution observation, or WhatsApp device verification. Each must be executed by a human tester with access to the production or staging environment.

---

### MV-CA-01 — Scheduler: vacation auto-clear fires correctly

**Story:** CA-10
**When to run:** Any morning at or after 07:00 AM server time, with a customer whose `vacation_end = today` set up in advance.

**Setup:**
1. Insert or update a customer row: set `vacation_end = CURDATE()`, `whatsapp_enabled = 1`, and note their mobile number.
2. Insert a second customer row with `vacation_end = CURDATE() + 1` as a control case.

**Verification steps:**
1. At 07:00 AM server time (or manually run `php artisan customer:clear-ended-vacations`), observe the command output.
2. Query `SELECT vacation_start, vacation_end FROM customers WHERE id = {test_customer_id}`.
3. Check WhatsApp on the test customer's device for the `lacto_sync_vacation_ended` notification.
4. Query the control customer — confirm their vacation dates are unchanged.

**Pass when:** Customer 1's `vacation_start` and `vacation_end` are null; WhatsApp notification received; Customer 2's dates are unchanged; command log shows "1 customer processed" (or the correct count).

---

### MV-CA-02 — WhatsApp delivery on vacation set

**Story:** CA-09
**When to run:** After TC-CA-030 (vacation set) passes.

**Verification steps:**
1. With a customer whose `whatsapp_enabled = true` and a real WhatsApp-connected mobile, set a valid vacation via the app.
2. Check WhatsApp on the customer's device within 2 minutes.

**Pass when:** A WhatsApp message from the `lacto_sync_vacation_set` template is received on the customer's device within the expected delivery window. The message content references the vacation dates set.

---

### MV-CA-03 — Owner WhatsApp notification on customer address change

**Story:** CA-06
**When to run:** After TC-CA-048 (address change) passes.

**Verification steps:**
1. With the farm owner's WhatsApp-connected mobile accessible, submit an address change via the customer app.
2. Check the farm owner's WhatsApp within 2 minutes.

**Pass when:** The farm owner receives a WhatsApp message that includes the customer's full name and the new delivery address. The customer does NOT receive a WhatsApp message for this event.

---

### MV-CA-04 — WhatsApp suppressed when customer whatsapp_enabled = false

**Story:** CA-09, CA-06
**When to run:** After toggle-off test (TC-CA-051) with `whatsapp_enabled = false` confirmed in the database.

**Verification steps:**
1. Set `customers.whatsapp_enabled = 0` for a customer (via the toggle in the app or directly in the database).
2. Set a vacation for this customer (POST vacation endpoint).
3. Check the customer's WhatsApp device for the `lacto_sync_vacation_set` notification.

**Pass when:** No WhatsApp notification is received by the customer. The vacation is still saved correctly in the database (notification suppression does not affect data persistence).

---

## Test Execution Summary

| Area | Total TCs | Automated | Manual only |
|---|---|---|---|
| Auth | 8 (TC-CA-001–008) | 8 | 0 |
| Dashboard | 5 (TC-CA-009–013) | 5 | 0 |
| Order Log | 6 (TC-CA-014–019) | 6 | 0 |
| Qty Change | 3 (TC-CA-020–022) | 3 | 0 |
| Single-Day Skip | 7 (TC-CA-023–029) | 7 | 0 |
| Vacation | 7 (TC-CA-030–036) | 6 | 1 (MV-CA-01) |
| Bills | 5 (TC-CA-037–041) | 5 | 0 |
| Payments | 4 (TC-CA-042–045) | 4 | 0 |
| Profile | 8 (TC-CA-046–053) | 7 | 1 (MV-CA-03) |
| Security | 4 (TC-CA-S01–S04) | 4 | 0 |
| Edge Cases | 6 (TC-CA-054–059) | 5 | 1 (TC-CA-056 / MV-CA-01) |
| UI / Nav | 4 (TC-CA-060–063) | 4 | 0 |
| WhatsApp delivery | — | — | 4 (MV-CA-01–04) |
| **Total** | **67 test cases** | **63** | **4 manual-only** |

---

## Traceability Matrix

| Story | Test case IDs |
|---|---|
| CA-02 | TC-CA-001, TC-CA-002, TC-CA-003, TC-CA-004, TC-CA-005, TC-CA-006, TC-CA-007, TC-CA-008, TC-CA-S01, TC-CA-S02, TC-CA-S04 |
| CA-03 | TC-CA-009, TC-CA-010, TC-CA-011, TC-CA-012, TC-CA-013, TC-CA-054, TC-CA-058 |
| CA-04 | TC-CA-014, TC-CA-015, TC-CA-016, TC-CA-017, TC-CA-018, TC-CA-019, TC-CA-054, TC-CA-055, TC-CA-057 |
| CA-05 | TC-CA-037, TC-CA-038, TC-CA-039, TC-CA-040, TC-CA-041, TC-CA-042, TC-CA-043, TC-CA-044, TC-CA-045, TC-CA-S03 |
| CA-06 | TC-CA-046, TC-CA-047, TC-CA-048, TC-CA-049, TC-CA-050, TC-CA-051, TC-CA-052, TC-CA-053, TC-CA-059, MV-CA-03 |
| CA-07 | TC-CA-020, TC-CA-021, TC-CA-022, TC-CA-055 |
| CA-08 | TC-CA-023, TC-CA-024, TC-CA-025, TC-CA-026, TC-CA-027, TC-CA-028 |
| CA-09 | TC-CA-030, TC-CA-031, TC-CA-032, TC-CA-033, TC-CA-034, MV-CA-02, MV-CA-04 |
| CA-10 | TC-CA-056, MV-CA-01 |
| CA-11 | TC-CA-001, TC-CA-002, TC-CA-003, TC-CA-004, TC-CA-007, TC-CA-008, TC-CA-060, TC-CA-061, TC-CA-062 |
| CA-12 | TC-CA-009, TC-CA-010, TC-CA-011, TC-CA-012, TC-CA-013, TC-CA-054, TC-CA-055 |
| CA-13 | TC-CA-014, TC-CA-015, TC-CA-016, TC-CA-017, TC-CA-018, TC-CA-019, TC-CA-020, TC-CA-021, TC-CA-022, TC-CA-023, TC-CA-029, TC-CA-055 |
| CA-14 | TC-CA-030, TC-CA-031, TC-CA-032, TC-CA-033, TC-CA-034, TC-CA-035, TC-CA-036, TC-CA-063 |
| CA-15 | TC-CA-037, TC-CA-038, TC-CA-039, TC-CA-040, TC-CA-041 |
| CA-16 | TC-CA-042, TC-CA-043, TC-CA-044, TC-CA-045, TC-CA-063 |
| CA-17 | TC-CA-046, TC-CA-047, TC-CA-048, TC-CA-049, TC-CA-050, TC-CA-051, TC-CA-052, TC-CA-053, TC-CA-059, TC-CA-060, TC-CA-062, TC-CA-063 |
