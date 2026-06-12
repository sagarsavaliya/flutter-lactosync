# QA Test Checklist — Tenant Admin Web App

> Author: QA / Test Engineer · Story: T1-18 · Date: 2026-06-06
> Sources: `briefs/requirements/tenant-admin-webapp.md`, `briefs/sprints/sprint-tenant-admin.md`, `briefs/DECISIONS.md`, all `briefs/specs/ux-admin-*.md`, `briefs/specs/schema-tenant-admin.md`

---

> **IMPORTANT — Manual verification required.**
> All test cases below have status ⚪ pending. Execute this checklist against the live VPS after migration, seeding, and deployment are complete. Update each row to ✅ pass, ❌ fail, or ⚠️ partial as you go. Log every failure with severity (Critical / High / Medium / Low) and reproduction steps in the "Bug log" section at the bottom of this file.

---

## Setup prerequisites

Complete all five steps before running any test case. Failing to do so will produce false negatives.

1. SSH into the Hostinger VPS and run `php artisan migrate` in the Laravel project root to apply all T1-08 and T1-21 migrations (subscription_plans, tenant_plan_assignments, saas_payments, admin_users, plus the subscription enforcement columns).
2. Run `php artisan db:seed --class=AdminUserSeeder` to create the single super-admin record (`savaliya.sagar@aksharatech.com`, PIN `159874`) with a bcrypt-hashed PIN.
3. Build the React SPA locally: `npm run build` inside the `admin-web/` directory. Confirm the `dist/` folder is produced with no TypeScript errors.
4. Deploy the built `dist/` folder to the VPS at the path served by the `superadmin.lactosync.com` Nginx server block (per T1-20 DevOps story). Verify Nginx rewrite (`try_files`) is in place.
5. Configure the React build's `.env` (or `.env.production`) with `VITE_API_BASE_URL` pointing to the live VPS API root (e.g. `https://api.lactosync.com`). Rebuild and redeploy after any `.env` change.
6. Add a DNS A record for `superadmin.lactosync.com` pointing to the VPS IP address and confirm it resolves before running browser tests.
7. Have a farm-owner Sanctum token ready (log into the Flutter app or hit `POST /api/v1/auth/login` with a live owner account) for the guard-isolation test cases.
8. Confirm the three live tenant accounts (Shreeji Gir Gaushala, Farenidham Gaushala, Gokul Dairy Farm) exist in `farm_owners` and are accessible to the admin API.

---

## Test case table

Status legend: ⚪ pending | ✅ pass | ❌ fail | ⚠️ partial

---

### 1. Authentication (FR-01 – FR-06)

| # | Area | Test case | Expected result | Status |
|---|------|-----------|-----------------|--------|
| A-01 | Auth | Navigate to `https://superadmin.lactosync.com` in Chrome 120+. | Browser loads the React SPA and redirects to `/login` (no blank page, no 404). | ⚪ |
| A-02 | Auth | On the login page, verify the PIN input renders as 6 individual numeric digit boxes (not a single password field). | Six separate single-character numeric input boxes are visible. Focus auto-advances to next box on each digit entry. | ⚪ |
| A-03 | Auth | Enter valid email `savaliya.sagar@aksharatech.com` and PIN `159874`. Submit. | API returns 200 with a Sanctum token. React stores the token in memory (Zustand). Browser navigates to `/dashboard`. | ⚪ |
| A-04 | Auth | After successful login (A-03), open DevTools → Application → Local Storage and Session Storage. | The raw PIN value `159874` does NOT appear in any storage key. Token is in memory state only (or in an httpOnly cookie — not readable via JS). | ⚪ |
| A-05 | Auth | With no token (fresh incognito session), navigate directly to `https://superadmin.lactosync.com/dashboard`. | Browser is redirected to `/login`. The dashboard does not render at all. | ⚪ |
| A-06 | Auth | With no token, navigate directly to `/tenants`, `/plans`, and `/payments`. | All three routes redirect to `/login`. | ⚪ |
| A-07 | Auth | Enter valid email but incorrect PIN (e.g. `000000`). Submit. | Login form shows a clear error message (e.g. "Invalid credentials"). HTTP status from API is 401. | ⚪ |
| A-08 | Auth | Enter wrong PIN 5 consecutive times (each time the form re-enables). | After the 5th failure the API returns 423 (or 429 with Retry-After header). The login form shows a lockout message with a countdown timer (15 minutes). The submit button is disabled. | ⚪ |
| A-09 | Auth | While locked out (A-08), attempt login again with the correct PIN before the 15-minute window expires. | API still returns 423. The form remains disabled and the countdown continues. The lockout is enforced server-side, not only in the UI. | ⚪ |
| A-10 | Auth | Wait for the 15-minute lockout to expire (or manually expire it via DB if testing on VPS), then attempt login with correct credentials. | Login succeeds. Token returned. Redirect to `/dashboard`. | ⚪ |
| A-11 | Auth | While logged in, click the Logout button. | React calls `POST /api/admin/v1/auth/logout`. Token is deleted from Zustand state. Browser navigates to `/login`. | ⚪ |
| A-12 | Auth | After logout (A-11), attempt to navigate to `/dashboard` in the same tab. | Browser redirects to `/login`. The dashboard does not render. | ⚪ |
| A-13 | Auth — Guard isolation | Take a valid farm-owner Sanctum token and make a direct HTTP request to `GET /api/admin/v1/dashboard` using that token (curl or Postman). | API returns 401 or 403. No admin data is returned. | ⚪ |
| A-14 | Auth — Guard isolation | Use the farm-owner token to call `GET /api/admin/v1/tenants`, `GET /api/admin/v1/plans`, and `GET /api/admin/v1/payments`. | All three endpoints return 401 or 403. | ⚪ |

---

### 2. Dashboard (FR-07 – FR-10)

| # | Area | Test case | Expected result | Status |
|---|------|-----------|-----------------|--------|
| D-01 | Dashboard | Log in as admin. Navigate to `/dashboard`. Observe initial page load. | Loading skeletons are displayed for KPI cards and the tenant table while the API request is in-flight. No blank cards or unformatted data appear during load. | ⚪ |
| D-02 | Dashboard — KPIs | After data loads, verify that exactly 7 KPI cards are rendered with the following labels (exact text): "Total Tenants", "Active Subscriptions", "Total Customers", "Today's Orders", "Monthly Collected", "Monthly Billed", "Total Outstanding". | All 7 cards are present with correct labels and non-empty values. | ⚪ |
| D-03 | Dashboard — KPIs | Cross-check "Total Tenants" value against the count of rows in `farm_owners` table on the VPS database. | KPI value matches the DB count. | ⚪ |
| D-04 | Dashboard — KPIs | Cross-check "Total Customers" against the count of rows in the `customers` table. | KPI value matches. | ⚪ |
| D-05 | Dashboard — KPIs | Cross-check "Total Outstanding" against manually computed sum of overdue tenant balances (plan fees - payments). | KPI value matches the manual calculation within ±1 INR (rounding). | ⚪ |
| D-06 | Dashboard — Tenant table | Verify the per-tenant summary table renders with all required columns: tenant name, plan name, plan status, renewal date, days until renewal, last payment date, outstanding balance. | All 7 columns are present for each tenant row. No column is missing or blank without reason. | ⚪ |
| D-07 | Dashboard — Amber badge | Identify or create a tenant whose renewal date is exactly 7 days from today. Observe their row in the summary table. | The "Days Left" cell or a badge in that row is rendered in amber (warning colour). | ⚪ |
| D-08 | Dashboard — Amber badge boundary | Verify a tenant with 8 days until renewal shows no amber badge. | Row appears in the default style with no amber or red highlight. | ⚪ |
| D-09 | Dashboard — Red badge | Identify or simulate a tenant with an overdue payment (past due date). Observe their row. | The row shows a red "Suspended" badge (or equivalent red indicator). The row background or text is highlighted in red. | ⚪ |
| D-10 | Dashboard — Auto-refresh | After the dashboard loads, wait 60 seconds without interacting. | A background API refetch fires automatically. The "last refreshed" timestamp visible on the page updates to reflect the new fetch time. No full page reload occurs. | ⚪ |
| D-11 | Dashboard — Refresh indicator | During the background refetch (D-10), observe the UI. | A non-blocking loading indicator (spinner, shimmer, or similar) appears briefly during the background refetch without disrupting the visible data. | ⚪ |
| D-12 | Dashboard — API response time | Using the browser Network tab or a timing tool, record the time from request initiation to response complete for `GET /api/admin/v1/dashboard` on the live VPS. | API response time is ≤ 500 ms. Record the actual measured value here for the sprint record. | ⚪ |
| D-13 | Dashboard — Total load time | Measure the time from navigation start to the point where all KPI cards and the tenant table show real data (no skeleton). | Total initial load time is ≤ 2 seconds on a standard broadband connection. Record the measured value here. | ⚪ |

---

### 3. Tenant Management (FR-11 – FR-18)

| # | Area | Test case | Expected result | Status |
|---|------|-----------|-----------------|--------|
| TM-01 | Tenant list | Navigate to `/tenants`. | All tenants in the system are listed. Each row shows: farm name, owner name, plan name, plan status, renewal date, and a quick-action menu icon. | ⚪ |
| TM-02 | Tenant list — search | Type a partial name of a known tenant in the search input (e.g. "Shreeji"). | The list narrows to only tenants whose name matches the search string. Other tenants are hidden. Clearing the search restores the full list. | ⚪ |
| TM-03 | Tenant list — filter: Active | Use the plan status filter dropdown to select "Active". | Only tenants with an active plan assignment are shown. | ⚪ |
| TM-04 | Tenant list — filter: Grace | Select "Grace" in the plan status filter. | Only tenants currently in the 5-day grace period (overdue but not yet suspended) are shown. | ⚪ |
| TM-05 | Tenant list — filter: Suspended | Select "Suspended" in the plan status filter. | Only tenants with a fully suspended subscription (overdue > 5 days) are shown. | ⚪ |
| TM-06 | Tenant list — filter: No Plan | Select "No Plan" in the plan status filter. | Only tenants with no plan assignment are shown. | ⚪ |
| TM-07 | Tenant detail — profile | Click through to the detail page of a tenant (e.g. Shreeji Gir Gaushala). | The profile section shows: farm name, owner name, address, phone number — sourced from the existing `farm_owners` record. These fields are read-only (no edit controls). | ⚪ |
| TM-08 | Tenant detail — plan status card | On the tenant detail page, verify the plan status card is present. | The card shows: assigned plan name, plan status (active / paused / grace / suspended), subscription start date, next renewal date, and remaining days. | ⚪ |
| TM-09 | Tenant detail — usage vs limits | Verify the usage section shows customer count and active subscription count. | Customer count and active subscription count are displayed alongside the plan's `max_customers` and `max_subscriptions` limits. | ⚪ |
| TM-10 | Tenant detail — payment summary | Verify the payment summary is shown on the detail page. | Outstanding balance is displayed prominently. Total collected and total billed amounts are present. | ⚪ |
| TM-11 | Tenant detail — payment history | Verify the payment history section on the detail page. | A list of SaaS payments recorded for this tenant is shown, sorted by payment date descending, with all fields: amount, payment date, due date, method, paid-by, reference/notes. | ⚪ |
| TM-12 | Tenant detail — activity trail | Verify the activity trail section. | A chronological list of plan actions (assign, change, pause, resume) is displayed with timestamps and, where applicable, reasons. | ⚪ |
| TM-13 | Assign plan | Navigate to a tenant with no plan assigned. Open the quick-action menu or detail page and select "Assign Plan". | A modal opens with a plan dropdown (populated from active plans only) and a start date picker. | ⚪ |
| TM-14 | Assign plan — dropdown excludes archived | In the Assign Plan modal (TM-13), verify the plan dropdown. | No archived plans appear in the dropdown. Only active plans are listed. | ⚪ |
| TM-15 | Assign plan — submit | Select a plan and a start date, then submit the Assign Plan modal. | API call succeeds. The tenant detail page refreshes showing the new plan assignment with correct renewal date (start date + billing cycle). An activity trail entry for "plan assigned" appears. | ⚪ |
| TM-16 | Assign plan — renewal date calculation | Assign a monthly plan starting today. Verify the renewal date. | Renewal date = today + 30 days (or 1 calendar month). Verify the displayed renewal date is correct. | ⚪ |
| TM-17 | Change plan | On a tenant with an active plan, select "Change Plan" from the quick-action menu. | A modal opens with a new plan dropdown, start date, and a required reason text field. | ⚪ |
| TM-18 | Change plan — reason required | Leave the reason field empty and attempt to submit the Change Plan modal. | The form blocks submission and shows a validation error on the reason field. The API is not called. | ⚪ |
| TM-19 | Change plan — submit with reason | Fill in a reason and submit the Change Plan modal. | API call succeeds. Tenant detail page refreshes with the updated plan. An activity trail entry for "plan changed" is visible, including the reason text and timestamp. | ⚪ |
| TM-20 | Pause plan | On a tenant with an active plan, select "Pause Plan" from the quick-action menu and confirm. | API call succeeds. The plan status card on the tenant detail page shows "paused" state. The tenant row in the list shows "Paused" status. | ⚪ |
| TM-21 | Resume plan | On the paused tenant (TM-20), select "Resume Plan" from the quick-action menu and confirm. | API call succeeds. Plan status returns to "active". The plan status card shows the new renewal date (today + full billing cycle, per DECISIONS.md OQ-2 resolution). | ⚪ |
| TM-22 | Resume plan — due_date recalculation | Verify the new due date after resume (TM-21). | Due date = resume date + full billing cycle (not a carry-over of the remaining days before pause). This matches the DECISIONS.md decision for OQ-2. | ⚪ |

---

### 4. Plan Management (FR-19 – FR-22)

| # | Area | Test case | Expected result | Status |
|---|------|-----------|-----------------|--------|
| PM-01 | Plan list | Navigate to `/plans`. | All plans in the system are listed. Each row shows: name, price (INR), billing cycle, status, and tenant count. | ⚪ |
| PM-02 | Plan list — archived badge | Verify that archived plans in the list have a distinct visual indicator. | Archived plans show an "Archived" badge or are visually greyed out, clearly distinguishable from active plans. | ⚪ |
| PM-03 | Create plan — form validation | Click "Create Plan". Leave all fields empty and submit. | Form validation prevents submission. Required fields (name, price, billing cycle, max customers, max subscriptions) each show an error message. | ⚪ |
| PM-04 | Create plan — valid submission | Fill in all required fields: name "Test Plan", price "999", cycle "Monthly", max customers "50", max subscriptions "50". Add an optional description. Submit. | API call succeeds. The new plan appears in the plan list with the correct values. | ⚪ |
| PM-05 | Edit plan — no active assignments | Edit the plan created in PM-04 (which has no tenant assignments). Attempt to change price, max customers, max subscriptions, name, and description. | All fields are editable. Changes save successfully. | ⚪ |
| PM-06 | Edit plan — with active assignments | Assign the plan from PM-04 to a tenant (use TM-15). Then return to the plan edit form. | Price, max customers, and max subscriptions fields are rendered as disabled/read-only. An explanatory tooltip is shown on or near the disabled fields (e.g. "Cannot change while tenants are assigned"). Name and description remain editable. | ⚪ |
| PM-07 | Edit plan — frozen fields via API | While the plan has active assignments (PM-06), bypass the UI and send `PUT /api/admin/v1/plans/{id}` with `price` in the request body (using Postman or curl with a valid admin token). | API returns 422 Unprocessable Entity. The price is not updated. | ⚪ |
| PM-08 | Archive plan — confirmation dialog | On an active plan, click "Archive". | A confirmation dialog appears with a warning such as "This plan cannot be assigned to new tenants after archiving." The dialog requires explicit confirmation before proceeding. | ⚪ |
| PM-09 | Archive plan — submit | Confirm the archive action (PM-08). | API call succeeds. The plan row in the list shows "Archived" badge. The plan does not appear in the "Assign Plan" dropdown on the tenant management page. | ⚪ |
| PM-10 | Archive plan — existing assignments unaffected | Verify the tenant that was assigned this plan before archiving (from PM-06). | The tenant's existing plan assignment remains intact and shows the correct plan name and status. The archive only blocks new assignments; it does not change existing ones. | ⚪ |
| PM-11 | Unarchive plan | On an archived plan, click "Unarchive" (or equivalent restore action). | API call succeeds. Plan status returns to "active" in the list. The plan reappears in the "Assign Plan" dropdown. | ⚪ |

---

### 5. Payment Tracking (FR-23 – FR-27)

| # | Area | Test case | Expected result | Status |
|---|------|-----------|-----------------|--------|
| PT-01 | Record payment — validation | Open the "Record Payment" modal for a tenant. Leave all required fields blank and submit. | Form validation blocks submission. Required fields (amount, payment date, due date, payment method, paid-by name) each show an error. | ⚪ |
| PT-02 | Record payment — all fields | Fill in all 6 required fields: amount "5000", payment date (today), due date (today), method "UPI", paid-by "Test User", reference "REF-001". Submit. | API returns 201. The payment appears in the tenant's payment history list. A system-generated `created_at` timestamp is shown. | ⚪ |
| PT-03 | Record payment — method enum | Open the payment method dropdown in the record-payment form. | All 5 options are available: UPI, Cash, Credit, Bank Transfer, Other. | ⚪ |
| PT-04 | Outstanding balance update | Note the outstanding balance before recording a payment. Record a payment of INR 5,000 (PT-02). Observe the outstanding balance immediately after. | The outstanding balance decreases by 5,000 INR without requiring a full page reload. | ⚪ |
| PT-05 | Payment history — sort | On the per-tenant payment history list, verify the sort order. | Payments are displayed sorted by payment date in descending order (most recent first). | ⚪ |
| PT-06 | Global payments list | Navigate to the global payments list (`/payments`). | All payments across all tenants are listed. Each row shows the tenant name, amount, payment date, method, paid-by, and a system timestamp. | ⚪ |
| PT-07 | Global payments — date range filter | Apply a date range filter (e.g. this calendar month only). | Only payments with a payment date within the selected range are shown. Payments outside the range are hidden. Clearing the filter restores all payments. | ⚪ |
| PT-08 | Global payments — tenant filter | Apply a tenant filter by selecting a specific tenant. | Only payments for the selected tenant are shown. | ⚪ |
| PT-09 | Global payments — sort by date | Click the "Date" column header to sort ascending, then again for descending. | List re-orders correctly in both directions. | ⚪ |
| PT-10 | Global payments — sort by amount | Click the "Amount" column header to sort ascending, then descending. | List re-orders correctly by amount in both directions. | ⚪ |
| PT-11 | Global payments — sort by tenant | Click the "Tenant" column header to sort ascending, then descending. | List re-orders alphabetically by tenant name in both directions. | ⚪ |
| PT-12 | Edit payment | Click the edit icon on an existing payment. | The edit form opens pre-populated with all existing field values (amount, payment date, due date, method, paid-by, reference). | ⚪ |
| PT-13 | Edit payment — save | Change the amount to "6000" and save. | API call succeeds. The updated amount appears in the payment list. No duplicate record is created. | ⚪ |
| PT-14 | Delete payment — confirmation dialog | Click the delete icon on a payment. | An AlertDialog (or equivalent confirmation modal) appears showing the payment amount and the tenant name (e.g. "Delete payment of ₹5,000 for Shreeji Gir Gaushala?"). The dialog requires explicit confirmation. | ⚪ |
| PT-15 | Delete payment — soft delete | Confirm the deletion (PT-14). | The payment is removed from the visible list. The outstanding balance for the tenant increases by the deleted payment's amount immediately. No hard-delete: verify via DB or audit trail that the record exists with `deleted_at` populated and `deleted_by` set to the admin user ID. | ⚪ |
| PT-16 | Delete payment — excluded from balance | After soft-deleting a payment (PT-15), verify the outstanding balance calculation. | The deleted payment is excluded from the outstanding balance. The balance reflects the pre-payment state. | ⚪ |

---

### 6. Subscription Enforcement (T1-21 / T1-22 — OQ-2 / OQ-4 resolution)

These tests verify the middleware (T1-21) and Flutter app behaviour (T1-22) together.

| # | Area | Test case | Expected result | Status |
|---|------|-----------|-----------------|--------|
| SE-01 | Active tenant — no change | Make any owner API call (e.g. `GET /api/v1/owner/profile`) as a tenant with an active, paid-up subscription (not overdue). | Response returns 200 with normal business data. No `subscription_warning` key in the response body. No `X-Subscription-Warning` header. | ⚪ |
| SE-02 | Grace period — API header | Simulate a tenant overdue by 3 days (within the 5-day grace window). Make any owner API call for that tenant. | Response returns 200 (business data is included). Response body contains `subscription_warning: {status: "PAYMENT_OVERDUE", days_overdue: 3, grace_days_remaining: 2}`. | ⚪ |
| SE-03 | Grace period — Flutter amber banner | Log into the Flutter app as the grace-period tenant (SE-02). Navigate through any screen. | A persistent amber banner is visible at the top of every screen showing the message "Payment overdue — X days left to clear dues" and a "Pay Now" button. | ⚪ |
| SE-04 | Grace period — banner persistence | Dismiss the amber banner (if dismissible). Close and reopen the Flutter app. | The amber banner reappears on the next app launch. The banner is dismissible per session but not permanently. | ⚪ |
| SE-05 | Suspended tenant — API response | Simulate a tenant overdue by 6 days (past the 5-day grace window). Make any owner API call for that tenant. | API returns `403` with JSON body `{"error":"SUBSCRIPTION_SUSPENDED","due_since":"<date>"}`. No business data is returned. | ⚪ |
| SE-06 | Suspended tenant — Flutter screen | Log into the Flutter app as the suspended tenant (SE-05). | Regardless of the last screen the user was on, the `SubscriptionSuspendedPage` is pushed and blocks all navigation. No owner business screen (dashboard, customers, billing, etc.) is accessible behind the suspension page. | ⚪ |
| SE-07 | Suspended tenant — Pay Now CTA | On the `SubscriptionSuspendedPage` (SE-06), verify the "Pay Now" button. | If a UPI VPA is configured for the platform admin, tapping "Pay Now" opens a UPI deep link (`upi://pay?...`). If no UPI VPA is configured, a contact message (phone/WhatsApp) is shown instead. | ⚪ |
| SE-08 | Resume after admin payment | While the tenant is suspended (SE-05), log into the admin panel and record a payment for that tenant sufficient to clear the overdue balance. In the admin panel, confirm the assignment is reactivated. Then return to the Flutter app on the suspended tenant's device and trigger any API call. | The Flutter app's next API call returns 200 (no 403). The `SubscriptionSuspendedPage` is dismissed automatically. The user is returned to the normal owner dashboard. | ⚪ |
| SE-09 | Resume — no manual admin step | Verify in the Laravel code or by testing that no manual DB edit is required to resume; recording the payment via `POST /api/admin/v1/tenants/{id}/payments` is sufficient to trigger auto-resume. | After recording the payment via the admin panel API, the `TenantPlanAssignment` status is set to "active" automatically (per T1-12 auto-resume logic). Subsequent owner API calls pass through the middleware without 403. | ⚪ |
| SE-10 | Plan limit — customer creation | For a tenant on a plan with `max_customers = 2` (or whatever their current limit is), ensure their customer count is already at the limit. Attempt to create one more customer via `POST /api/v1/owner/customers`. | API returns `402` with body containing `{"error":"PLAN_LIMIT_EXCEEDED","current_count":<n>,"limit":<n>}`. The customer is not created. | ⚪ |
| SE-11 | Plan limit — subscription creation | For a tenant at their `max_subscriptions` limit, attempt to create one more active milk-delivery subscription via the relevant owner endpoint. | API returns `402 PLAN_LIMIT_EXCEEDED`. The subscription is not created. | ⚪ |
| SE-12 | Active tenant — no Flutter regression | Log into the Flutter app as a tenant with an active, paid-up subscription. Navigate through Home, Customers, Daily Orders, Billing, and Payments tabs. | No amber banner appears. No suspension page is shown. No change in app behaviour compared to the pre-T1-22 state. All tabs function normally. | ⚪ |

---

### 7. Security (NFR)

| # | Area | Test case | Expected result | Status |
|---|------|-----------|-----------------|--------|
| SEC-01 | PIN storage | On the VPS, query the `admin_users` table: `SELECT pin_hash FROM admin_users;` | The value in `pin_hash` starts with `$2y$` (bcrypt prefix). It is NOT the literal PIN `159874` or any plaintext value. | ⚪ |
| SEC-02 | PIN never returned | Send a valid `POST /api/admin/v1/auth/login` request and inspect the full JSON response body. | The response does not contain any field named `pin`, `pin_hash`, `password`, or any field whose value equals `159874`. | ⚪ |
| SEC-03 | No plain PIN in source | Search the Laravel source files (controllers, seeders, migrations, config) for the literal string `159874`. | No match found. The PIN only exists in the database as a bcrypt hash. | ⚪ |
| SEC-04 | Farm-owner token isolation — dashboard | Using a valid farm-owner Sanctum token, call `GET /api/admin/v1/dashboard` (Postman or curl, `Authorization: Bearer <owner_token>`). | Response is 401 or 403. No admin data is returned. | ⚪ |
| SEC-05 | Farm-owner token isolation — tenants | Same owner token → `GET /api/admin/v1/tenants`. | 401 or 403. No data returned. | ⚪ |
| SEC-06 | Farm-owner token isolation — plans | Same owner token → `GET /api/admin/v1/plans`. | 401 or 403. No data returned. | ⚪ |
| SEC-07 | Farm-owner token isolation — payments | Same owner token → `GET /api/admin/v1/payments`. | 401 or 403. No data returned. | ⚪ |
| SEC-08 | Unauthenticated access | Remove the `Authorization` header entirely and call any `POST /api/admin/v1/` endpoint. | Response is 401. No data is modified or returned. | ⚪ |
| SEC-09 | CSRF — state-changing endpoints | For a state-changing admin endpoint (e.g. `POST /api/admin/v1/plans`), remove the CSRF token from the request (or send a deliberately incorrect token) while keeping a valid admin Sanctum token. | API returns 401 or 419 (CSRF mismatch). The resource is not created. | ⚪ |
| SEC-10 | Lockout enforced server-side | After triggering the 5-attempt lockout via the UI (A-08), attempt the same `POST /api/admin/v1/auth/login` directly via curl with the correct PIN. | API still returns 423 (locked). The lockout is not bypassed by circumventing the React UI. | ⚪ |
| SEC-11 | HTTPS only | Navigate to `http://superadmin.lactosync.com` (non-TLS). | Browser is redirected to `https://superadmin.lactosync.com` (301 redirect). Confirm TLS certificate is valid (no browser warning). | ⚪ |

---

### 8. Performance (NFR)

| # | Area | Test case | Expected result | Measured value | Status |
|---|------|-----------|-----------------|----------------|--------|
| PF-01 | Dashboard API response | Using browser DevTools Network tab, record the response time of `GET /api/admin/v1/dashboard` on the live VPS with all 3 live tenant accounts loaded. | API response time ≤ 500 ms. | _record here_ | ⚪ |
| PF-02 | Dashboard total load | Measure time from browser navigation start to all KPI cards and the tenant table showing real data (no skeleton), using browser DevTools Performance tab or Lighthouse. | Total load time ≤ 2 seconds on a standard broadband connection. | _record here_ | ⚪ |
| PF-03 | Tenant list render | With all 3 live tenant accounts, navigate to `/tenants` and record render time to first meaningful content. | Tenant list renders within 1 second. | _record here_ | ⚪ |
| PF-04 | Build size — JS bundle | Run `npm run build` in `admin-web/`. Check `dist/assets/index.js` gzip size (use `gzip -c dist/assets/index.js | wc -c` or a Vite bundle analyser). | Gzip-compressed JS bundle < 500 KB. | _record here_ | ⚪ |
| PF-05 | Build — no TypeScript errors | Run `npm run build` and observe the terminal output. | Build completes with zero TypeScript errors. Exit code 0. | — | ⚪ |

---

## Summary counts

| Category | Total cases | ✅ Pass | ❌ Fail | ⚠️ Partial | ⚪ Pending |
|----------|------------|---------|---------|-----------|-----------|
| Auth (A) | 14 | 0 | 0 | 0 | 14 |
| Dashboard (D) | 13 | 0 | 0 | 0 | 13 |
| Tenant Management (TM) | 22 | 0 | 0 | 0 | 22 |
| Plan Management (PM) | 11 | 0 | 0 | 0 | 11 |
| Payment Tracking (PT) | 16 | 0 | 0 | 0 | 16 |
| Subscription Enforcement (SE) | 12 | 0 | 0 | 0 | 12 |
| Security (SEC) | 11 | 0 | 0 | 0 | 11 |
| Performance (PF) | 5 | 0 | 0 | 0 | 5 |
| **Total** | **104** | **0** | **0** | **0** | **104** |

---

## FR coverage matrix

| Requirement | Test cases |
|-------------|-----------|
| FR-01 (login screen — email + PIN) | A-01, A-02 |
| FR-02 (bcrypt hashed PIN, server-side) | A-03, SEC-01, SEC-02, SEC-03 |
| FR-03 (JWT / Sanctum token, not store PIN) | A-03, A-04 |
| FR-04 (redirect unauthenticated to /login) | A-05, A-06 |
| FR-05 (logout invalidates token) | A-11, A-12 |
| FR-06 (5-attempt lockout, 15 min) | A-08, A-09, A-10, SEC-10 |
| FR-07 (7 dashboard KPIs) | D-02, D-03, D-04, D-05 |
| FR-08 (tenant summary table columns) | D-06 |
| FR-09 (amber / red renewal badges) | D-07, D-08, D-09 |
| FR-10 (60-second auto-refresh + timestamp) | D-10, D-11 |
| FR-11 (tenant list, search, filter) | TM-01, TM-02, TM-03, TM-04, TM-05, TM-06 |
| FR-12 (tenant row columns) | TM-01 |
| FR-13 (tenant detail — all sections) | TM-07, TM-08, TM-09, TM-10, TM-11, TM-12 |
| FR-14 (assign plan) | TM-13, TM-14, TM-15, TM-16 |
| FR-15 (change plan with reason) | TM-17, TM-18, TM-19 |
| FR-16 (pause plan) | TM-20 |
| FR-17 (resume plan) | TM-21, TM-22 |
| FR-18 (activity trail on plan changes) | TM-15, TM-19 |
| FR-19 (create plan — all fields) | PM-03, PM-04 |
| FR-20 (edit plan — frozen fields on active assignments) | PM-05, PM-06, PM-07 |
| FR-21 (archive plan) | PM-08, PM-09, PM-10 |
| FR-22 (plan list columns) | PM-01, PM-02 |
| FR-23 (record payment — all 6 fields) | PT-01, PT-02, PT-03 |
| FR-24 (payment history — sorted descending) | PT-05 |
| FR-25 (outstanding balance per tenant) | PT-04, PT-16 |
| FR-26 (global payments list — sort + filter) | PT-06, PT-07, PT-08, PT-09, PT-10, PT-11 |
| FR-27 (edit / soft-delete payment) | PT-12, PT-13, PT-14, PT-15 |
| OQ-2 / T1-21 (grace period + suspension middleware) | SE-01 through SE-12 |
| NFR Security | SEC-01 through SEC-11, A-13, A-14 |
| NFR Performance | PF-01 through PF-05 |

---

## Bug log

> Log every failure found during test execution here. One entry per bug.

Format:
```
### BUG-<NNN>
- Test case: <ID>
- Severity: Critical | High | Medium | Low
- Title: <one-line description>
- Steps to reproduce:
  1. ...
  2. ...
- Expected: ...
- Actual: ...
- Status: Open | Fixed | Won't Fix
```

_(No bugs logged yet — checklist is pending execution.)_
