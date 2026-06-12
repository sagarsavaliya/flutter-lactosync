# Client Input — Tenant Management Web App

> Captured: 2026-06-05 by CEO

## Raw request (verbatim)

"i want you to create react base web app for frontend and use flutter apk's backend to create tenant management webapp, which includes governance of subscriptions, complete tenant management - assign plan, pause plan, upgrade/downgrade plan, payment info like due date, paid date, amount paid, paid via upi, cash, credit, etc, paid by, create subscription plans, assign subscritiption plan to tenant.

dashboard should show all the information about tenants, like customers count subscription count, total daily orders, total collected payments, total geenrated bill along with number of bills/payment and amount as well, remaining days to next renewal, plan type, etc..

use login id as my email id and 6 digit pin, savaliya.sagar@aksharatech.com 159874"

## Clarifications / interpretation

- **Platform:** React (web, SPA or SSR TBD) — separate app from the Flutter mobile app
- **Backend:** Reuse the existing Laravel API (same Hostinger VPS) — extend it for tenant/plan management
- **Auth:** Single super-admin login; email = `savaliya.sagar@aksharatech.com`, PIN = `159874` (6-digit)
- **Tenants:** Each "tenant" is a farm/owner account already in the system (e.g. Shreeji Gir Gaushala, Farenidham Gaushala, Gokul Dairy Farm)
- **Plans:** New concept — need to define what a subscription plan consists of (price, duration, features/limits)

## Key features requested

1. **Dashboard** — aggregate KPIs across all tenants:
   - Customer count (per tenant + total)
   - Subscription count
   - Total daily orders
   - Total collected payments
   - Total generated bills (count + amount)
   - Remaining days to next renewal (per tenant)
   - Plan type (per tenant)

2. **Tenant management**
   - List all tenants with status, plan, renewal date
   - View tenant detail
   - Assign plan to tenant
   - Pause plan
   - Upgrade / downgrade plan

3. **Subscription plan management**
   - Create plans (name, price, duration, feature limits)
   - Edit / archive plans
   - Assign plan to tenant

4. **Payment tracking** (per tenant)
   - Due date
   - Paid date
   - Amount paid
   - Payment method: UPI / Cash / Credit
   - Paid by (who paid)
   - Payment history

## Existing backend context

- Stack: Laravel 13 · PHP 8.4 · MySQL 8 · Redis on Hostinger VPS
- Deployed API — owners, customers, subscriptions (milk delivery), billing, payments already exist
- These are **milk-delivery** subscriptions (farmer → customer). The new "tenant subscriptions" are **SaaS plans** (platform admin → farm owner/tenant) — a different concept.
