# PROJECT CONTEXT — App_LactoSync
# Production-grade dairy farm management SaaS (Akshara Internal)

---

## Project Identity
- **Project Name:** LactoSync (App_LactoSync)
- **Client / Product:** Akshara Internal SaaS
- **Type:** [x] SaaS Product
- **Start Date:** 2026-05-30
- **Target MVP:** Phase 1–3 (Auth + Customers + Orders) · **Rollout target:** mid-June 2026
- **Priority:** [x] High
- **Current build:** v4.11.1+39 (full redesign committed; device-test ready)

---

## Project Summary
Mobile-first SaaS for **dairy farm owners** in India. Owners manage customer subscriptions, daily milk delivery order logs, vacation pauses, monthly billing, and customer communication via **WhatsApp** (OTP + PDF statements). **Flutter app** (owner + customer + delivery boy roles) · **React admin** (superadmin.lactosync.com) · **Laravel API** on Hostinger VPS with scheduled jobs and queue workers. Multi-tenant: each farm isolated by `farm_id`.

**Design source:** `briefs/redesign app screen - lactosync/LactoSync Routes Redesign.dc.html`

---

## Active Departments
- [x] Technical
- [x] Product & Design
- [ ] Sales
- [ ] Marketing
- [ ] Legal (before public launch)
- [ ] Data & Analytics

---

## Tech Stack
- **Frontend:** Flutter 3 · Riverpod · go_router · Dio · lucide_icons
- **Admin web:** React · superadmin.lactosync.com
- **Backend:** Laravel 13 · PHP 8.4 · Sanctum
- **Database:** MySQL 8 · Redis 7
- **Auth:** Mobile + 4-digit PIN · WhatsApp OTP reset
- **PDF:** dompdf · **Messaging:** WhatsApp Cloud API
- **Prod:** Hostinger VPS · Docker (`lactosync_flutter_app` stack)
- **API URL:** https://flutterapi.lactosync.com

---

## End Users
- **Who:** Dairy farm owners, 30–55, low–medium tech comfort
- **Devices:** Android primary, iOS secondary
- **Technical level:** Non-technical
- **Live test farm:** Farenidham Gaushala (9998866008 / PIN 1234)

---

## Key Modules (status)
| Module | Status |
|--------|--------|
| Auth + onboarding | ✅ |
| Owner (6 tabs + routes + settings) | ✅ redesigned |
| Customer app | ✅ shell + APIs; coming-soon gate for some flows |
| Delivery boy | ✅ home + route sheet |
| Billing + payments + WhatsApp | ✅ |
| Superadmin | ✅ live |

---

## Critical Business Rules
1. Every DB row scoped to `farm_id` — no cross-farm leaks
2. OTP: 6 digits, 10 min expiry, max 3 sends/hour/mobile
3. PIN hashed (bcrypt) — never plain text
4. Vacation: no order lines while active; auto-resume after `vacation_end`
5. Order log idempotent per farm + date + slot
6. Monthly bill idempotent per customer + `YYYY-MM`
7. **THIS MONTH consumption:** billable logs from month start through **today** (pending + delivered) — not future days
8. Coupon = flat amount off rate (`effective_rate = rate − coupon`)
9. WhatsApp tokens server-side only
10. Long-press subscription calendar → edit order log / send to customer

---

## Requirement Document
- **Status:** Redesign brief in `briefs/`; gaps logged in `briefs/REDESIGN_GAPS.md`
- **Checkpoint:** full redesign committed at `62d3549` (Sprint 11, v4.11.0); pre-redesign checkpoint was `4e603ee`

---
*Last updated: CEO Agent | 2026-06-15*
