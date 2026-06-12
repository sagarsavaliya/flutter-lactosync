# Sprint Plan — Tenant Admin Web App

> Author: Project Manager · Source: `briefs/requirements/tenant-admin-webapp.md` · Date: 2026-06-05
> **Status: APPROVED — pipeline running**

---

## Sprint goal

Ship a standalone React SPA + extended Laravel API that lets the single super-admin log in, govern all tenant accounts, manage SaaS plans, and record payments — with no changes to the existing Flutter app or its API routes.

---

## Open questions — RESOLVED (2026-06-05, human-approved)

All four OQs are resolved. See `briefs/DECISIONS.md` for the full log.

| OQ | Resolution |
|----|-----------|
| OQ-2 | Overdue → auto-pause + 5-day grace period. During grace: tenant sees "clear dues" alert in Flutter app with payment redirect. After 5 days: full suspension (API blocks all owner calls). On payment confirmation: immediate resume. |
| OQ-4 | 5-day grace period, then full suspension of all operations. No auto-suspend before grace expires. |
| OQ-6 | Plan feature limits **enforced by the API**. Laravel middleware checks limits on relevant endpoints. |
| OQ-7 | Served at `superadmin.lactosync.com` (human adds DNS subdomain). Same Hostinger VPS, new Nginx server block. |

Two new stories added as a result: **T1-21** (Laravel subscription enforcement middleware) and **T1-22** (Flutter suspension screen).

---

## Stories

Stories are numbered **T1-NN** (Tenant Admin, Sprint 1).

---

### Phase 1 — Producers (run in PARALLEL)

---

### T1-01 — Schema spec: admin_users, subscription_plans, tenant_plan_assignments, saas_payments

- **Owner:** DBMS Architect
- **Satisfies:** PRD §4.1–4.5, §8 (backend data model); constraints C1–C4
- **Depends on:** none
- **Description:** Produce a complete MySQL schema spec for the four new tables. Cover all columns, data types, indexes, constraints, foreign keys, and enum values. Include a note on which existing tables are read-only from admin context (owners, customers, subscriptions, orders, invoices). Leave room for OQ-1 (future tenant provisioning from admin panel).
- **Acceptance criteria:**
  - [ ] `briefs/specs/schema-tenant-admin.md` exists and defines all four tables with columns, types, nullability, defaults, and indexes.
  - [ ] `admin_users` stores email + bcrypt-hashed PIN; no plain-text PIN column exists.
  - [ ] `tenant_plan_assignments` references `owner_id` (nullable, per PRD §8 data separation principle) and captures start date, renewal date, status enum, and a pause/resume audit trail.
  - [ ] `saas_payments` stores all fields from FR-23 plus a `deleted_at` (soft delete) and a `created_by` audit column.
- **Spec output:** `briefs/specs/schema-tenant-admin.md`

---

### T1-02 — UX spec: Auth screens (login, lockout)

- **Owner:** UX/UI Designer
- **Satisfies:** FR-01–06
- **Depends on:** none
- **Description:** Produce screen specs for the login page (email + 6-digit PIN input) and the lockout state (5 failed attempts → 15-minute lock message). Desktop-first layout. shadcn/ui component vocabulary. Include field validation states and error messages.
- **Acceptance criteria:**
  - [ ] `briefs/specs/ux-admin-auth.md` exists with annotated wireframes or screen descriptions for login and lockout states.
  - [ ] PIN input is specified as 6 individual numeric digit boxes (not a plain password field).
  - [ ] Error states are defined: wrong credentials, account locked with countdown, network error.
  - [ ] Redirect behaviour on successful auth (goes to Dashboard) is documented.
- **Spec output:** `briefs/specs/ux-admin-auth.md`

---

### T1-03 — UX spec: Dashboard (KPI cards + tenant summary table)

- **Owner:** UX/UI Designer
- **Satisfies:** FR-07–10
- **Depends on:** none
- **Description:** Produce screen spec for the main dashboard. KPI card grid, per-tenant summary table, amber/red renewal-warning badges, auto-refresh indicator. Desktop-first, shadcn/ui.
- **Acceptance criteria:**
  - [ ] `briefs/specs/ux-admin-dashboard.md` exists with layout, KPI card list (all 7 KPIs from FR-07), and column definitions for the tenant summary table (FR-08).
  - [ ] Amber (≤7 days) and red (overdue) badge specs are defined with exact trigger conditions matching FR-09.
  - [ ] Auto-refresh indicator placement and copy are specified (default 60 s, FR-10).
  - [ ] Empty state (no tenants yet) and loading skeleton are specified.
- **Spec output:** `briefs/specs/ux-admin-dashboard.md`

---

### T1-04 — UX spec: Tenant Management (list + detail + plan actions)

- **Owner:** UX/UI Designer
- **Satisfies:** FR-11–18
- **Depends on:** none
- **Description:** Produce screen specs for the tenant list page (search, filter, quick-action menu) and the tenant detail page (profile, plan status, subscription timeline, payment history sub-section, customer/subscription counts). Include all plan-action modals: assign plan, change plan (upgrade/downgrade with reason field), pause, resume.
- **Acceptance criteria:**
  - [ ] `briefs/specs/ux-admin-tenants.md` exists covering list page and detail page layouts.
  - [ ] All six plan-action states are specified (no plan assigned, active, paused, expired, upgrade, downgrade) with their respective CTAs and confirmation modals.
  - [ ] Tenant detail shows all sections from FR-13 in documented layout order.
  - [ ] Search and filter controls (FR-11) are specified with placeholder text and filter options.
- **Spec output:** `briefs/specs/ux-admin-tenants.md`

---

### T1-05 — UX spec: Plan Management (list + create/edit/archive)

- **Owner:** UX/UI Designer
- **Satisfies:** FR-19–22
- **Depends on:** none
- **Description:** Produce screen specs for the plan list page and the create/edit plan form. Include the archive action with confirmation. Show the frozen-fields behaviour (FR-20: price + limits are read-only when active assignments exist).
- **Acceptance criteria:**
  - [ ] `briefs/specs/ux-admin-plans.md` exists covering list, create form, edit form, and archive confirmation.
  - [ ] Edit form specifies which fields are editable vs read-only when the plan has active tenant assignments (FR-20).
  - [ ] Plan list columns match FR-22 (name, price, cycle, status, tenant count).
  - [ ] Archived plans are visually distinguished and excluded from the "assign plan" dropdown on tenant pages.
- **Spec output:** `briefs/specs/ux-admin-plans.md`

---

### T1-06 — UX spec: Payment Tracking (record + history + global list)

- **Owner:** UX/UI Designer
- **Satisfies:** FR-23–27
- **Depends on:** none
- **Description:** Produce screen specs for the record-payment modal, per-tenant payment history list, outstanding balance display, and the global payments list with sort and date-range filter. Include edit and soft-delete flows with audit trail note.
- **Acceptance criteria:**
  - [ ] `briefs/specs/ux-admin-payments.md` exists covering record-payment modal, per-tenant history, outstanding balance widget, and global list.
  - [ ] Record-payment form fields match FR-23 exactly (amount, payment date, due date, method enum, paid-by, reference/notes).
  - [ ] Global payments list sort options and date-range filter are specified (FR-26).
  - [ ] Edit and soft-delete flows are specified with confirmation step (FR-27).
- **Spec output:** `briefs/specs/ux-admin-payments.md`

---

### Phase 2 — Laravel backend (depends on schema spec)

---

### T1-07 — Laravel: Admin auth guard + middleware + seeder

- **Owner:** Laravel Engineer
- **Satisfies:** FR-01–06; NFR Security
- **Depends on:** T1-01 (schema spec)
- **Description:** Implement the `admin` Sanctum guard, `admin_users` migration, `SuperAdmin` Eloquent model, `AdminAuthController` (login, logout), rate-limiter (5 attempts → 15-minute lock), and a database seeder that creates the single super-admin record with a bcrypt-hashed PIN. All routes under `/api/admin/v1/` must be protected by `auth:admin` middleware.
- **Acceptance criteria:**
  - [ ] `POST /api/admin/v1/auth/login` returns a Sanctum token on valid email + PIN; returns 401 on wrong credentials; returns 423 (or 429) with a retry-after header after 5 failed attempts.
  - [ ] `POST /api/admin/v1/auth/logout` invalidates the token server-side; subsequent requests with the same token return 401.
  - [ ] A farm-owner Sanctum token does NOT grant access to any `/api/admin/v1/` route (returns 401/403).
  - [ ] Seeder creates the admin record; PIN is stored as a bcrypt hash; no plain-text PIN appears in any migration, seeder, or config file.
- **Spec:** `briefs/specs/schema-tenant-admin.md`

---

### T1-08 — Laravel: Migrations + Eloquent models (plans, assignments, payments)

- **Owner:** Laravel Engineer
- **Satisfies:** FR-19–27; PRD §8 data model
- **Depends on:** T1-01 (schema spec)
- **Description:** Write and run migrations for `subscription_plans`, `tenant_plan_assignments`, and `saas_payments`. Create Eloquent models with relationships, casts, and scopes. Migrations must be strictly additive — no alterations to existing tables.
- **Acceptance criteria:**
  - [ ] All three migrations run cleanly on a fresh `migrate` and roll back cleanly on `migrate:rollback`.
  - [ ] `SubscriptionPlan` model has an `isEditable()` method that returns `false` when active tenant assignments exist (price + limits frozen per FR-20).
  - [ ] `TenantPlanAssignment` model tracks status enum (`active`, `paused`, `expired`), pause/resume timestamps, and plan-change log (JSON or separate audit table per schema spec).
  - [ ] `SaasPayment` model uses `SoftDeletes`; a `deleted_by` column is populated on soft delete for the audit trail (FR-27).
- **Spec:** `briefs/specs/schema-tenant-admin.md`

---

### T1-09 — Laravel: Admin Dashboard API endpoint

- **Owner:** Laravel Engineer
- **Satisfies:** FR-07–10
- **Depends on:** T1-07, T1-08
- **Description:** Implement `GET /api/admin/v1/dashboard` returning all aggregate KPIs (FR-07) and the per-tenant summary rows (FR-08) in a single response. Query existing tables (owners, customers, subscriptions, orders, invoices) read-only; join with new admin tables for plan/payment data.
- **Acceptance criteria:**
  - [ ] Response includes all 7 KPI fields from FR-07 with correct values against seed/test data.
  - [ ] Response includes per-tenant rows with all columns from FR-08 (tenant name, plan name, status, renewal date, days until renewal, last payment date, outstanding balance).
  - [ ] Endpoint responds within 500 ms on the live VPS with 3 tenant accounts.
  - [ ] Route is inaccessible without a valid admin token (returns 401).
- **Spec:** `briefs/specs/schema-tenant-admin.md`

---

### T1-10 — Laravel: Tenant Management API endpoints

- **Owner:** Laravel Engineer
- **Satisfies:** FR-11–18
- **Depends on:** T1-07, T1-08
- **Description:** Implement CRUD admin-scoped endpoints for tenant management: list tenants (with search + filter), tenant detail (profile + plan status + timeline + payment history + customer/subscription counts), assign plan, change plan (with reason), pause plan, resume plan. Log all plan actions to a tenant activity trail.
- **Acceptance criteria:**
  - [ ] `GET /api/admin/v1/tenants` supports `?search=` (name) and `?plan_status=` filter; returns paginated results.
  - [ ] `GET /api/admin/v1/tenants/{id}` returns all fields specified in FR-13 including customer count and active subscription count sourced from existing tables.
  - [ ] `POST /api/admin/v1/tenants/{id}/plan-assign`, `/plan-change`, `/plan-pause`, `/plan-resume` all write to `tenant_plan_assignments` with timestamp and (where applicable) reason; activity trail entry is created for each action (FR-18).
  - [ ] All routes return 401 without a valid admin token and 404 for a non-existent tenant.
- **Spec:** `briefs/specs/schema-tenant-admin.md`

---

### T1-11 — Laravel: Plan Management API endpoints

- **Owner:** Laravel Engineer
- **Satisfies:** FR-19–22
- **Depends on:** T1-07, T1-08
- **Description:** Implement admin endpoints for SaaS plan lifecycle: list plans, create plan, edit plan (with frozen-field enforcement), archive plan. Include the tenant-count-per-plan field in list response.
- **Acceptance criteria:**
  - [ ] `GET /api/admin/v1/plans` returns all plans with name, price, cycle, status, and active tenant count.
  - [ ] `POST /api/admin/v1/plans` creates a plan with all fields from FR-19; validation rejects missing required fields.
  - [ ] `PUT /api/admin/v1/plans/{id}` returns 422 if price or feature-limit fields are sent for a plan with active assignments (FR-20 enforcement).
  - [ ] `POST /api/admin/v1/plans/{id}/archive` sets status to `archived`; subsequent `plan-assign` attempts referencing an archived plan return 422.
- **Spec:** `briefs/specs/schema-tenant-admin.md`

---

### T1-12 — Laravel: Payment Tracking API endpoints

- **Owner:** Laravel Engineer
- **Satisfies:** FR-23–27
- **Depends on:** T1-07, T1-08
- **Description:** Implement admin endpoints for SaaS payment records: record payment (per tenant), list payments per tenant, global payments list (with sort + date-range filter), edit payment, soft-delete payment with audit trail.
- **Acceptance criteria:**
  - [ ] `POST /api/admin/v1/tenants/{id}/payments` accepts all fields from FR-23 and returns the created record with a system timestamp.
  - [ ] `GET /api/admin/v1/tenants/{id}/payments` returns payment history sorted by payment date descending.
  - [ ] `GET /api/admin/v1/payments` supports `?sort_by=`, `?tenant_id=`, `?from=`, `?to=` query parameters (FR-26).
  - [ ] `DELETE /api/admin/v1/payments/{id}` soft-deletes the record and records `deleted_by` (admin user ID) and timestamp; the record is excluded from outstanding-balance calculations after deletion.
- **Spec:** `briefs/specs/schema-tenant-admin.md`

---

### Phase 3 — React SPA (depends on UX specs + Laravel API contract)

---

### T1-13 — React: Project scaffold + admin auth (login, PIN input, token management)

- **Owner:** React Engineer
- **Satisfies:** FR-01–06
- **Depends on:** T1-02 (UX auth spec), T1-07 (Laravel auth endpoints live)
- **Description:** Scaffold the Vite + React 18 + Zustand + React Router v6 + shadcn/ui project. Implement the login page (email + 6-digit PIN input boxes), auth Zustand store (token in memory, not localStorage), protected-route wrapper that redirects unauthenticated users to `/login`, and logout action.
- **Acceptance criteria:**
  - [ ] Running `npm run dev` serves the app at localhost; `npm run build` produces a dist folder with no TypeScript errors.
  - [ ] Login page renders 6 individual digit input boxes; submitting valid credentials stores the Sanctum token in Zustand memory state and navigates to `/dashboard`.
  - [ ] Navigating to any protected route without a token redirects to `/login`.
  - [ ] After 5 failed attempts the login form shows the lockout message and disables the submit button for 15 minutes (mirrors server-side lock from T1-07).
  - [ ] Logout clears the in-memory token and calls `POST /api/admin/v1/auth/logout`.
- **Spec:** `briefs/specs/ux-admin-auth.md`

---

### T1-14 — React: Dashboard page (KPI cards + tenant summary table + auto-refresh)

- **Owner:** React Engineer
- **Satisfies:** FR-07–10
- **Depends on:** T1-03 (UX dashboard spec), T1-09 (Laravel dashboard endpoint live)
- **Description:** Implement the dashboard page: KPI card grid (all 7 KPIs), per-tenant summary table with amber/red renewal badges, and a 60-second polling interval for auto-refresh. Loading skeletons while data is in-flight.
- **Acceptance criteria:**
  - [ ] All 7 KPI cards from FR-07 render with correct labels and live data from the API.
  - [ ] Tenant summary table shows all columns from FR-08; rows with renewal ≤7 days show an amber badge; rows with overdue payment show a red badge (FR-09).
  - [ ] Data refetches automatically every 60 seconds; a visible "last refreshed" timestamp updates on each successful fetch (FR-10).
  - [ ] A loading skeleton is shown on initial load and a non-blocking refresh indicator appears during background refetches.
- **Spec:** `briefs/specs/ux-admin-dashboard.md`

---

### T1-15 — React: Tenant Management pages (list + detail + plan-action modals)

- **Owner:** React Engineer
- **Satisfies:** FR-11–18
- **Depends on:** T1-04 (UX tenant spec), T1-10 (Laravel tenant endpoints live)
- **Description:** Implement the tenant list page (search, plan-status filter, quick-action menu) and the tenant detail page (all FR-13 sections). Implement all four plan-action modals: assign, change (with reason field), pause, resume. Each action calls the corresponding Laravel endpoint and refreshes the detail page on success.
- **Acceptance criteria:**
  - [ ] Tenant list renders with search (filters by name client-side or server-side) and plan-status filter; quick-action menu shows context-appropriate actions based on current plan state.
  - [ ] Tenant detail page shows all sections from FR-13 in the layout specified by `briefs/specs/ux-admin-tenants.md`.
  - [ ] Assign-plan modal populates plan dropdown from the plans API (archived plans excluded).
  - [ ] Change-plan modal requires a non-empty reason field before submission; success triggers an activity trail entry visible on re-fetch.
- **Spec:** `briefs/specs/ux-admin-tenants.md`

---

### T1-16 — React: Plan Management pages (list + create/edit/archive)

- **Owner:** React Engineer
- **Satisfies:** FR-19–22
- **Depends on:** T1-05 (UX plan spec), T1-11 (Laravel plan endpoints live)
- **Description:** Implement the plan list page and the create/edit plan form. Enforce the read-only frozen-fields state in the edit form when the plan has active assignments. Implement the archive confirmation dialog.
- **Acceptance criteria:**
  - [ ] Plan list shows all columns from FR-22; archived plans are visually distinguished.
  - [ ] Create form validates all required fields (name, price, cycle, max customers, max subscriptions) before submission.
  - [ ] Edit form renders price and feature-limit fields as disabled/read-only when the plan has active assignments; an explanatory tooltip is shown.
  - [ ] Archive confirmation dialog warns "This plan cannot be assigned to new tenants" and requires explicit confirmation before calling the archive endpoint.
- **Spec:** `briefs/specs/ux-admin-plans.md`

---

### T1-17 — React: Payment Tracking pages (record modal + per-tenant history + global list)

- **Owner:** React Engineer
- **Satisfies:** FR-23–27
- **Depends on:** T1-06 (UX payment spec), T1-12 (Laravel payment endpoints live)
- **Description:** Implement the record-payment modal (accessible from tenant detail), the per-tenant payment history list with outstanding balance display, and the global payments list with sort and date-range filter. Implement edit and soft-delete flows with confirmation.
- **Acceptance criteria:**
  - [ ] Record-payment modal includes all fields from FR-23; submission creates the record and refreshes outstanding balance without a full page reload.
  - [ ] Per-tenant payment history is sorted by payment date descending; outstanding balance is displayed prominently above the list (FR-25).
  - [ ] Global payments list supports sort by date, tenant, and amount; date-range filter narrows the results without a full page reload (FR-26).
  - [ ] Soft-delete shows a confirmation dialog; deleted records disappear from the list and outstanding balance updates immediately (FR-27).
- **Spec:** `briefs/specs/ux-admin-payments.md`

---

### Phase 4 — Quality assurance

---

### T1-18 — QA: Test suite against all acceptance criteria

- **Owner:** QA / Test Engineer
- **Satisfies:** All FR-01–27; NFR Security, Performance
- **Depends on:** T1-07 through T1-17 (all backend + frontend stories complete)
- **Description:** Write and execute a test plan covering all functional requirements. Test authentication security (guard isolation, lockout), all CRUD flows for plans/payments/assignments, dashboard KPI accuracy, and performance thresholds from the NFR section.
- **Acceptance criteria:**
  - [ ] A test checklist in `briefs/specs/qa-tenant-admin.md` maps every FR to at least one test case; each test case has pass/fail status.
  - [ ] The farm-owner token isolation test (FR guard separation) has an explicit test case with an expected 401/403 result, and it passes.
  - [ ] Dashboard KPI response time is measured against the live VPS and recorded as ≤2 seconds for initial load and ≤500 ms for API response (NFR Performance).
  - [ ] Zero critical bugs remain open at sign-off; all found bugs are logged with severity and reproduction steps.
- **Spec:** `briefs/requirements/tenant-admin-webapp.md`, all `briefs/specs/ux-admin-*.md`, `briefs/specs/schema-tenant-admin.md`

---

### Phase 5 — Code review

---

### T1-19 — Code Review: Security + correctness review

- **Owner:** Code Reviewer & Security
- **Satisfies:** NFR Security (all items); PRD §5
- **Depends on:** T1-18 (QA sign-off)
- **Description:** Read-only review of all new Laravel routes, middleware, models, and React auth/token-handling code. Focus: guard isolation, bcrypt PIN handling, CSRF protection, soft-delete audit integrity, no secrets in source, and no admin route accessible via owner token.
- **Acceptance criteria:**
  - [ ] Review findings document exists in `briefs/specs/review-tenant-admin.md`; each finding has severity (critical / high / medium / low) and a resolution.
  - [ ] Zero critical or high-severity unresolved findings at sign-off.
  - [ ] PIN is confirmed stored as bcrypt hash and never returned in any API response (confirmed by reading model and controller code).
  - [ ] CSRF protection is confirmed applied to all state-changing admin endpoints.
- **Spec:** `briefs/requirements/tenant-admin-webapp.md`, all Laravel + React source files

---

### Phase 2b — New stories from OQ resolutions

---

### T1-21 — Laravel: Subscription enforcement middleware

- **Owner:** Laravel Engineer
- **Satisfies:** OQ-2, OQ-4, OQ-6 decisions; NFR Security
- **Depends on:** T1-07, T1-08
- **Description:** Implement a `CheckTenantSubscription` middleware attached to all `api/v1/owner/*` routes. Logic: (1) look up the tenant's active `TenantPlanAssignment`; (2) if payment is overdue but within the 5-day grace window, allow the request through but attach an `X-Subscription-Warning: PAYMENT_OVERDUE` header and include a `subscription_warning` payload key; (3) if overdue > 5 days, return `403 SUBSCRIPTION_SUSPENDED` with structured JSON (`{"error":"SUBSCRIPTION_SUSPENDED","due_since":"<date>","payment_url":"<url>"}`); (4) enforce feature limits — if a request would exceed the plan's `max_customers` or `max_subscriptions`, return `402 PLAN_LIMIT_EXCEEDED`. Auto-resume: when a SaaS payment is recorded via the admin panel and the assignment is re-activated, the middleware immediately allows through on the next request (no cache TTL).
- **Acceptance criteria:**
  - [ ] A request from a tenant with an active, paid-up subscription passes through the middleware with no extra headers.
  - [ ] A request from a tenant overdue by 3 days (within grace) returns the normal response body PLUS `subscription_warning: {status: "PAYMENT_OVERDUE", days_overdue: 3, grace_days_remaining: 2}`.
  - [ ] A request from a tenant overdue by 6 days returns `403` with `{"error":"SUBSCRIPTION_SUSPENDED"}` — no business data is returned.
  - [ ] After the admin records a payment and marks the assignment active, the next request from that tenant passes through without the 403.
  - [ ] A create-customer request that would push the tenant over their plan's `max_customers` limit returns `402 PLAN_LIMIT_EXCEEDED` with the current count and limit in the response body.
- **Spec:** `briefs/specs/schema-tenant-admin.md`, `briefs/DECISIONS.md`

---

### T1-22 — Flutter: Subscription overdue / suspended screen

- **Owner:** Flutter Engineer
- **Satisfies:** OQ-2 decision; Flutter app UX for suspended tenants
- **Depends on:** T1-21 (Laravel middleware live and returning the correct error shapes)
- **Description:** Add a Dio interceptor in the Flutter app that catches `subscription_warning` in any successful response and `403 SUBSCRIPTION_SUSPENDED` error responses. For warnings (grace period): show a persistent amber banner at the top of every screen with "Payment overdue — X days left to clear dues" and a "Pay Now" button. For suspended (`403`): intercept navigation, push a full-screen `SubscriptionSuspendedPage` that shows the due amount, due date, and a "Pay Now" CTA. "Pay Now" redirects to the payment screen (UPI/cash — reuse existing payment UI or open UPI deep link). On app resume after the admin confirms payment, poll `/api/v1/owner/profile` for subscription status; dismiss the screen as soon as the next request succeeds without a `403`.
- **Acceptance criteria:**
  - [ ] A tenant whose API response includes `subscription_warning` sees the amber banner on every screen; banner is dismissible per session but reappears on app restart.
  - [ ] A tenant whose API returns `403 SUBSCRIPTION_SUSPENDED` is redirected to `SubscriptionSuspendedPage` regardless of which screen they were on; no business data screen is accessible behind the gate.
  - [ ] "Pay Now" CTA on the suspended screen opens the payment flow; if a UPI VPA is configured for the platform admin it opens UPI deep link (`upi://pay?...`), otherwise shows a contact message.
  - [ ] After the admin records payment and the middleware resumes the tenant, the next successful API call from the Flutter app dismisses the suspended screen and returns the user to the dashboard.
  - [ ] No regression on tenants with active, paid-up subscriptions — they see no banner, no redirect, no change in app behaviour.
- **Spec:** `briefs/DECISIONS.md` (OQ-2 resolution)

---

### Phase 6 — DevOps

---

### T1-20 — DevOps: React project scaffold + Nginx deployment config

- **Owner:** DevOps / Release Engineer
- **Satisfies:** PRD §8 (React SPA, Vite, static build); OQ-7
- **Depends on:** T1-13 (React scaffold exists), T1-19 (review complete)
- **Description:** Scaffold the React project directory structure (if not already done by T1-13), write the Nginx server block for the admin SPA (serving the dist folder, SPA fallback rewrite, HTTPS redirect), and document the deployment steps. Resolve OQ-7 (VPS vs CDN) in line with the human's answer before this story runs.
- **Acceptance criteria:**
  - [ ] `admin.lactosync.in` (or the agreed subdomain) serves the built React SPA over HTTPS with a valid TLS certificate.
  - [ ] All routes (e.g. `/dashboard`, `/tenants/1`) return the `index.html` SPA shell (Nginx `try_files` rewrite confirmed working).
  - [ ] `npm run build && rsync` (or equivalent deploy script) is documented in `briefs/specs/devops-tenant-admin.md` so any future deploy is one command.
  - [ ] Admin SPA is completely isolated from the existing Flutter API paths — no cross-contamination of Nginx rules.
- **Spec:** `briefs/specs/devops-tenant-admin.md` (produced by this story)

---

## Sequencing notes

```
Phase 1 (PARALLEL — no dependencies between any of these):
  T1-01  DBMS Architect — schema spec
  T1-02  UX Designer    — auth screens
  T1-03  UX Designer    — dashboard screens
  T1-04  UX Designer    — tenant management screens
  T1-05  UX Designer    — plan management screens
  T1-06  UX Designer    — payment tracking screens

Phase 2 (Laravel — all depend on T1-01; T1-09/10/11/12 also depend on T1-07+T1-08):
  T1-07  Laravel — admin auth guard + seeder          (depends on T1-01)
  T1-08  Laravel — migrations + Eloquent models        (depends on T1-01)
  T1-09  Laravel — dashboard API                       (depends on T1-07, T1-08)
  T1-10  Laravel — tenant management API               (depends on T1-07, T1-08)
  T1-11  Laravel — plan management API                 (depends on T1-07, T1-08)
  T1-12  Laravel — payment tracking API                (depends on T1-07, T1-08)
  Note: T1-07 and T1-08 can run in PARALLEL (both depend only on T1-01).
  Note: T1-09, T1-10, T1-11, T1-12 can run in PARALLEL once T1-07 and T1-08 are done.

Phase 3 (React — each story depends on its UX spec + its corresponding Laravel endpoint):
  T1-13  React — scaffold + auth      (depends on T1-02, T1-07)
  T1-14  React — dashboard            (depends on T1-03, T1-09)
  T1-15  React — tenant management    (depends on T1-04, T1-10)
  T1-16  React — plan management      (depends on T1-05, T1-11)
  T1-17  React — payment tracking     (depends on T1-06, T1-12)
  Note: All five React stories can run in PARALLEL once their respective deps are met.

Phase 4:
  T1-18  QA — test suite              (depends on T1-07 through T1-17)

Phase 5:
  T1-19  Code Review                  (depends on T1-18)

Phase 6:
  T1-20  DevOps — deployment          (depends on T1-13, T1-19)
```

**Critical path:** T1-01 → T1-07/T1-08 → T1-09–12 → T1-13–17 → T1-18 → T1-19 → T1-20

**Recommended first dispatch (after human approval):**
Dispatch T1-01 (DBMS Architect) and T1-02 through T1-06 (UX Designer) simultaneously — they are fully independent and can produce their specs in parallel, unblocking the entire implementation pipeline.
