# PROJECT CONTEXT — App_LactoSync
# Production-grade dairy farm management SaaS (Akshara Internal)

---

## Project Identity
- **Project Name:** LactoSync (App_LactoSync)
- **Client / Product:** Akshara Internal SaaS
- **Type:** [x] SaaS Product
- **Start Date:** 2026-05-30
- **Target MVP:** Phase 1–3 (Auth + Customers + Orders)
- **Priority:** [x] High

---

## Project Summary
Mobile-first SaaS for **dairy farm owners** in India. Owners manage customer subscriptions, daily milk delivery order logs, vacation pauses, monthly billing, and customer communication via **WhatsApp** (OTP + PDF statements). **Flutter app only** — no web admin. **Laravel API** backend with scheduled jobs and queue workers. Multi-tenant: each farm is isolated by `farm_id`.

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
- **Frontend:** Flutter 3 · Riverpod · go_router · Dio
- **Backend:** Laravel 13 · PHP 8.4 · Sanctum (mobile tokens)
- **Database:** MySQL 8
- **Cache / Queue:** Redis 7
- **Auth:** Mobile + 4-digit PIN · WhatsApp OTP for reset
- **PDF:** dompdf (Laravel)
- **Messaging:** WhatsApp Cloud API (`lacto_sync_otp` + document template TBD)
- **Dev infra:** Docker (`lactosync/`)
- **Prod target:** Hostinger VPS
- **App name:** lactosync_Flutter App
- **Tenant:** One farm = one owner (subscription plans on farm later)

---

## End Users
- **Who:** Dairy farm owners, 30–55, low–medium tech comfort
- **Devices:** Android primary, iOS secondary
- **Technical level:** Non-technical
- **Industry:** Dairy / milk delivery
- **Special needs:** Plain Hindi/English copy, 4G-friendly, large tap targets

---

## Key Modules
1. **Auth** — PIN login, WhatsApp OTP reset, session tokens
2. **Farm profile** — farm name, delivery slots, pricing defaults
3. **Customers** — name, mobile, address, active/inactive
4. **Subscriptions** — product, qty, frequency, vacation dates
5. **Daily order log** — auto-generated AM/PM lines, mark delivered/adjust qty
6. **Billing** — monthly bill generation (1st), PDF, WhatsApp send
7. **Notifications** — OTP, bills, optional delivery reminders

---

## Performance (Production targets)
- API read p95 < 500ms on 4G
- Login < 2s
- Order log load < 3s for 500 customers/farm
- Concurrent farms year 1: ~500; scale to 5K with queue workers + read replica

---

## Integrations
- WhatsApp Cloud API — OTP + document delivery
- (Future) UPI payment links — post-MVP

---

## Critical Business Rules
1. Every DB row scoped to `farm_id` — no cross-farm data leaks
2. OTP: 6 digits, 10 min expiry, max 3 sends/hour/mobile
3. PIN stored hashed (bcrypt) — never plain text
4. Vacation: no order lines while active; auto-resume day after `vacation_end`
5. Order log generation idempotent per farm + date + slot (morning/evening)
6. Monthly bill idempotent per customer + `YYYY-MM`
7. All writes accept `Idempotency-Key` header
8. Soft deletes only on business entities
9. Audit log on auth, billing, subscription changes
10. WhatsApp tokens server-side only — never in Flutter

---

## Requirement Document
- **Status:** No formal brief in repo — rules captured here + DECISIONS.md

---
*Last updated: CEO Agent | 2026-05-30*
