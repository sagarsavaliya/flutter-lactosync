# Requirement Document (PRD) — Tenant Management Web App

> Author: Business Analyst · Source: `briefs/client-input/tenant-admin-webapp.md` · Date: 2026-06-05
> Consumed by: UX/UI Designer, DBMS Architect, PM

---

## 1. Business problem & goals

LactoSync currently has three live farm accounts (Shreeji Gir Gaushala, Farenidham Gaushala, Gokul Dairy Farm) using the platform at no tracked cost. The platform operator (Sagar Savaliya, Aksharatech) has no tooling to:

- See the operational health of all farms in one place.
- Define and enforce SaaS pricing tiers (plans) for each farm.
- Track whether a farm's subscription has been paid, is overdue, or needs renewal.
- Manage the commercial lifecycle of each tenant: onboard, assign a plan, pause, upgrade, downgrade.

**Goals:**

1. Give the platform operator a single web interface to govern all tenant accounts.
2. Introduce a formal plan/pricing model so the platform can generate recurring revenue.
3. Track SaaS payments per tenant (amount, method, dates) independently of the milk-delivery billing that already exists in the Flutter app.
4. Surface aggregate health KPIs across all tenants on a single dashboard.

**Success criteria:**

- The operator can log in, view the state of all tenants, create a plan, assign it to a tenant, and record a payment — without touching the database directly.
- Every tenant's renewal date and payment status are visible at a glance.

---

## 2. Scope

**In scope:**

- React SPA (web only) — a new, standalone frontend application.
- Super-admin authentication (single user, email + 6-digit PIN).
- Dashboard with aggregate KPIs across all tenants.
- Tenant listing and tenant detail view (read-only profile from existing owner records).
- SaaS plan management: create, edit, archive plans (name, price, billing cycle, feature limits).
- Plan assignment to a tenant (assign, upgrade, downgrade, pause, resume).
- SaaS subscription payment tracking per tenant (record a payment, view history).
- Extension of the existing Laravel API with new admin-only routes covering the above.
- New database tables for: plans, tenant-plan assignments, and SaaS payment records.

**Out of scope:**

- Milk-delivery subscriptions (the farmer → customer subscription model already in the Flutter app) — these are untouched.
- Milk-delivery billing and payment records (the existing `invoices` / `payments` tables) — read-only at most via existing endpoints; no modifications.
- Customer management inside a tenant's account.
- Daily order management, WhatsApp delivery, or any Flutter app feature.
- Multi-admin accounts or role-based access control (single operator only).
- A customer-facing portal or tenant self-service interface.
- Automated payment gateway integration (Razorpay, Stripe, etc.) — payments are recorded manually by the admin.
- Automated renewal emails or push notifications (may be a future sprint).
- Any SharePoint, SPFx, or Power Automate component.

---

## 3. Users & roles

| Role | What they need to do |
| ---- | -------------------- |
| **Super Admin** (single user: `savaliya.sagar@aksharatech.com`) | Log in with email + 6-digit PIN. View all-tenant dashboard. Manage tenant records (view detail, assign/change/pause plan). Define and manage SaaS plans. Record and view SaaS payment history per tenant. |

There is no other user role. No tenant self-login. No multi-admin setup.

---

## 4. Functional requirements

### 4.1 Authentication

- **FR-01:** The system shall present a login screen accepting an email address and a 6-digit numeric PIN.
- **FR-02:** The system shall authenticate the credentials against a super-admin record stored server-side (hashed PIN). Hard-coded credentials are not acceptable.
- **FR-03:** On successful login the system shall issue a JWT (or Laravel Sanctum token) and store it in memory / `httpOnly` cookie; it shall not store the PIN.
- **FR-04:** The system shall redirect any unauthenticated request to the login screen.
- **FR-05:** The system shall provide a logout action that invalidates the token server-side.
- **FR-06:** After five consecutive failed PIN attempts the system shall lock the session for 15 minutes and display a clear error.

### 4.2 Dashboard

- **FR-07:** The dashboard shall display the following aggregate KPIs across all active tenants:
  - Total tenant count (active / inactive / paused breakdown).
  - Total customer count across all tenants.
  - Total active milk-delivery subscription count across all tenants.
  - Total daily orders for today across all tenants.
  - Total collected SaaS payments (all time) and for the current calendar month.
  - Total outstanding SaaS payment amount (sum of overdue tenant balances).
  - Total generated milk-delivery bills (count + amount) across all tenants.
- **FR-08:** The dashboard shall display a per-tenant summary table with the following columns: tenant name, plan name, plan status (active / paused / expired), renewal date, days until renewal, last payment date, and outstanding balance.
- **FR-09:** Tenants with renewal within 7 days or with an overdue payment shall be visually flagged (e.g. amber / red badge).
- **FR-10:** KPI cards shall refresh automatically at a configurable interval (default: 60 seconds) without a full page reload.

### 4.3 Tenant Management

- **FR-11:** The system shall list all tenants (farm owner accounts) with search by name and filter by plan status.
- **FR-12:** Each tenant row shall show: farm name, owner name, plan name, plan status, renewal date, and a quick-action menu.
- **FR-13:** The system shall provide a tenant detail page showing:
  - Farm profile (name, address, phone — read from existing owner record; not editable here).
  - Assigned plan and its current status.
  - Subscription timeline: start date, next renewal date, remaining days.
  - Payment history (SaaS payments only).
  - Customer count and active milk-delivery subscription count (read from existing data).
- **FR-14:** The system shall allow the admin to assign a plan to a tenant (when no plan is currently assigned).
- **FR-15:** The system shall allow the admin to change a tenant's plan (upgrade or downgrade), recording the change with a timestamp and reason.
- **FR-16:** The system shall allow the admin to pause a tenant's plan, which suspends the renewal clock and optionally flags the tenant account.
- **FR-17:** The system shall allow the admin to resume a paused plan.
- **FR-18:** Plan changes shall take effect immediately and be logged in a tenant activity trail.

### 4.4 Plan Management

- **FR-19:** The system shall allow the admin to create a subscription plan with the following attributes: name, description, price (INR), billing cycle (monthly / quarterly / half-yearly / yearly), and at least the following feature limits: max customers, max active milk-delivery subscriptions.
- **FR-20:** The system shall allow the admin to edit any attribute of a plan that has no active tenant assignments; for plans with active assignments, only name and description may be changed (price and limits are frozen to avoid retroactive changes).
- **FR-21:** The system shall allow the admin to archive a plan. Archived plans cannot be assigned to new tenants but existing tenant assignments continue unaffected until renewal.
- **FR-22:** The plans list shall show each plan's name, price, billing cycle, status (active / archived), and the count of tenants currently on that plan.

### 4.5 Payment Tracking

- **FR-23:** The system shall allow the admin to record a SaaS payment against a tenant with the following fields: amount (INR), payment date, due date, payment method (UPI / Cash / Credit / Bank Transfer / Other), paid-by name, and optional reference/notes.
- **FR-24:** The system shall display a payment history list per tenant, sorted by payment date descending, showing all fields from FR-23 plus a system-generated record timestamp.
- **FR-25:** The system shall calculate and display an "outstanding balance" per tenant: the sum of plan fees due since plan assignment minus total recorded payments.
- **FR-26:** The system shall display a global payments list (all tenants) sortable by date, tenant, and amount, with a date-range filter.
- **FR-27:** The system shall allow editing or deleting a payment record (soft delete with audit trail).

---

## 5. Non-functional requirements

- **Performance:** Dashboard KPIs shall load within 2 seconds on a standard broadband connection. The tenant list with up to 100 tenants shall render within 1 second. API responses for admin endpoints shall complete within 500 ms under normal load (3 live farms + admin).
- **Security:**
  - All admin API routes shall be protected by a server-side middleware that validates the admin JWT / Sanctum token. No admin route is publicly accessible.
  - The 6-digit PIN shall be stored as a bcrypt hash; it is never returned in any API response.
  - HTTPS is mandatory in production (existing Hostinger VPS already serves TLS).
  - CSRF protection shall be applied to all state-changing requests.
  - Admin endpoints are completely separate from the owner-facing API endpoints; a farm-owner token must not grant access to any admin route.
- **Platform:** Web SPA, desktop-first layout (admin works on a laptop/desktop). Minimum supported browsers: Chrome 120+, Firefox 120+, Edge 120+. Mobile responsiveness is a nice-to-have, not a launch requirement.
- **Scale:** Designed for up to 50 tenant accounts with no architectural change. Beyond 50 tenants a pagination / virtual-scroll review is required.
- **Availability:** Same VPS as the existing API; no additional uptime SLA beyond what is already in place.

---

## 6. Constraints & assumptions

**Constraints:**

- The React SPA must share the existing Laravel backend (same Hostinger VPS, same MySQL instance). No separate backend service will be introduced.
- Admin routes must be namespaced and middlewared separately from the owner API routes (e.g. `/api/admin/v1/...`).
- There is exactly one super-admin user. Multi-admin support is explicitly out of scope and must not be designed in, to avoid premature complexity.
- The Flutter mobile app and its existing API routes are not to be changed as part of this work. New migrations must not alter existing table structure — additive only.
- The React app will be deployed as a static build (e.g. served from the same VPS via Nginx) or on a CDN. No SSR framework (Next.js) is required unless the PM and architect agree otherwise.

**Assumptions:**

- [A1] The existing `users` / `owners` tables hold the tenant account records. Tenant identity in the new admin panel maps 1:1 to an existing owner account.
- [A2] There is no need to provision or delete tenant accounts from the admin panel at launch — tenants are created via the existing Flutter onboarding flow. This may change in a future sprint.
- [A3] Milk-delivery KPIs on the dashboard (customer count, daily orders, bill totals) will be derived by querying existing tables via new admin-scoped read endpoints. No data duplication.
- [A4] "Days until renewal" is calculated from the plan-assignment start date plus the billing cycle duration, rolling forward on each renewal.
- [A5] The admin panel itself does not need multi-tenant data isolation — the super-admin sees all data across all tenants by design.
- [A6] A plan "pause" does not extend the renewal date; it freezes it. The parties agree on the new date manually and the admin records it. This is an assumption and should be confirmed (see OQ-2).

---

## 7. Open questions

- **OQ-1 — Tenant provisioning:** Should the admin panel eventually allow creating a new tenant account (farm owner) from scratch, bypassing the Flutter onboarding flow? Not required at launch per A2, but the schema should leave room for it.
- **OQ-2 — Plan pause behaviour:** When a plan is paused, does the renewal clock freeze (renewal date shifts forward by the paused duration) or does it continue running? Assumption A6 says it freezes — confirm with the client.
- **OQ-3 — Plan price change on existing tenants:** If the admin edits a plan's price, should existing tenants on that plan be grandfathered at the old price, or should the next renewal use the new price? FR-20 conservatively freezes price on active assignments — confirm this is the desired behaviour.
- **OQ-4 — Overdue handling:** When a payment is overdue, should the system only flag it visually, or should it also restrict tenant access to the Flutter app (e.g. a server-side `is_suspended` flag)? This has a significant backend impact and must be decided before the Laravel Engineer begins work.
- **OQ-5 — Bill total KPI source:** The "total generated bills" KPI on the dashboard refers to milk-delivery invoices (already in the `invoices` table). Confirm that the admin reading this data cross-tenant is acceptable (no GDPR / privacy concern for farm owners).
- **OQ-6 — Plan feature enforcement:** Should the API enforce plan limits (e.g. block a tenant from adding a customer if they are over the plan's customer limit), or are limits informational only for now? Enforcement adds significant backend complexity; informational-only is faster to ship.
- **OQ-7 — React build deployment:** Should the React SPA be served from the existing Nginx on the VPS (e.g. `admin.lactosync.in`), or from a separate CDN/hosting (Vercel, Netlify)? This affects the DevOps story.

---

## 8. Proposed solution direction

**Frontend:** React 18+ SPA using Vite as the build tool. State management via Zustand (lightweight, sufficient for single-user admin). Routing via React Router v6. UI component library: shadcn/ui (Tailwind-based, consistent with modern admin aesthetics). No SSR required.

**Backend:** Existing Laravel 13 API extended with:
- A new `Admin` middleware group protecting all routes under `/api/admin/v1/`.
- A dedicated `SuperAdmin` model / guard (separate from the `Owner` guard) with email + bcrypt-hashed PIN, seeded once.
- New migrations (additive): `subscription_plans`, `tenant_plan_assignments`, `saas_payments`, `admin_users`.
- New controllers: `AdminAuthController`, `AdminDashboardController`, `AdminTenantController`, `AdminPlanController`, `AdminPaymentController`.

**Authentication flow:** Admin submits email + PIN → Laravel validates against `admin_users` table → returns a Sanctum token scoped to the `admin` guard → React stores token in memory and sends it as `Authorization: Bearer` on every subsequent request.

**Data separation principle:** SaaS plan / payment data lives in new tables; existing milk-delivery tables are read-only from admin endpoints. No foreign-key coupling between the new admin tables and the existing subscription/payment tables, other than a nullable `owner_id` reference on `tenant_plan_assignments`.
