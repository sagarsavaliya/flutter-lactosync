# STATUS — LactoSync

> **Where we are / what's next:** S6-11 through S6-15 implemented on two feature branches. Branch `feature/s6-11-12-settings-profile-cards` delivers farm + owner profile read cards with edit bottom sheets and ZIP pincode auto-fill. Branch `feature/s6-13-15-dynamic-types-ui` delivers milk types + container types management sections and dynamic dropdowns in the product edit form. Both pushed; awaiting PR review + Laravel branch merge for full end-to-end.
>
> _Last updated: 2026-06-04 by Flutter Engineer_

---

## Project snapshot

| Item | Value |
| ---- | ----- |
| App version | `4.8.4+8` |
| APK path | `build/app/outputs/flutter-apk/app-release.apk` |
| API | Deployed on Hostinger VPS — 2026-05-30 |
| Stack | Flutter 3 · Riverpod · go_router · Dio / Laravel 13 · PHP 8.4 · MySQL 8 · Redis |
| Live farm accounts | 3 (Shreeji Gir Gaushala · Farenidham Gaushala · Gokul Dairy Farm) |
| Git remote | https://github.com/sagarsavaliya/flutter-lactosync.git |
| Default branch | `main` — **never commit directly; feature branches + PR + human approval required** |

---

## What is built — confirmed against code

### Auth & Onboarding ✅
- Sign up → OTP → Role picker → Set PIN
- Sign in · Forgot PIN → OTP → Reset PIN
- Splash with resume routing (signed out / onboarding step / dashboard)
- Farm details · Product setup · Add customer · Subscription · Onboarding checklist dashboard

### Owner Module — all 6 tabs ✅
| Tab | What exists |
| --- | ----------- |
| **Home (Dashboard)** | KPI cards; quick actions (Find Customer, Gen Bill, Record Payment, View QR / UPI share); milk preparation panel; owner greeting |
| **Customers** | Search + sort (44px targets); active/inactive mini-toggle; vacation sheet; tap → Customer Detail |
| **Customer Detail** | Cards A–D (info, subscriptions, billing summary, activity log); edit sheets; delete (blocked on unpaid balance only); generate bill; send milk log; restore activity |
| **Daily Orders** | Order rows with no vertical text wrap; skip button; mark delivered / adjust qty; generate orders button |
| **Billing** | Per-customer Billed / Collected / Outstanding grid; bulk-send invoices; tap → Invoice Detail |
| **Invoice Detail** | Line items; record payment (cash/UPI); send invoice via WhatsApp |
| **Payments** | Payment history with search + sort |
| **Settings** | Farm name, address, UPI VPA/payee, product management (edit/delete), delivery slot times, WhatsApp delivery toggle |
| **Activity Log** | `GET /owner/activities`; restore action |

### WhatsApp delivery ✅
- Server-side PNG generation (DejaVu fonts) for milk log and bill
- Payment receipt as text message
- UPI QR share via WhatsApp
- All credentials server-side only; 24h Meta session window handled; errors surfaced in-app

### Backend ✅
- Activity table + delete logic live
- Bill generation idempotent (recalculates existing month, no duplicate invoices)
- Customer delete: blocked on unpaid balance only; subscriptions delete without log-block
- `GET /owner/activities`, `POST /owner/activities/{id}/restore`

### Design system ✅
- Token-driven: `AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppSizes`
- Green borders on inputs/search/sort; mint customer cards; global `OwnerTopBar`
- Shared widget library: `AppCard`, `AppButton`, `AppTextField`, `AppBottomSheet`, `AppChip`, `AppGap`, `AppSection`

---

## Decisions (key, non-obvious)
Full log → `memory/DECISIONS.md`

- No PDF in-app — image-only WhatsApp delivery; `pdf` package removed
- Customer delete blocked only on unpaid balance (`CUSTOMER_HAS_UNPAID_BILLS`); subscriptions delete cleanly
- Coupon = flat amount off rate (not %)
- One invoice per customer per month (all subscriptions aggregated)
- Bill generation on 1st of month from prior month's delivered order logs
- Customer app (Phase 4) deferred — owner-first strategy

---

## Current sprint: Sprint 5 — Field validation

| Story | Owner | Status | Notes |
| ----- | ----- | ------ | ----- |
| S5-01 — Install & smoke-test v4.8.4+8 on live farms | QA / Human | ⚪ pending | Test bill recalc, Send button on invoice detail, WhatsApp delivery to a customer who messaged in last 24 h |
| S5-02 — Decide next feature sprint | CEO / Human | ⚪ pending | Options: Customer app (Phase 4), QA harness, new owner features |

---

## Current sprint: Sprint 6 — Dynamic data model

| Story | Owner | Status | Notes |
| ----- | ----- | ------ | ----- |
| S6-01 — Pincode lookup table | DBMS Architect → Laravel Engineer | ✅ done | Schema spec at `briefs/specs/schema-s6-01-pincode.md`; seeding Gujarat first |
| S6-02 — Dynamic milk types + container types + products migration | DBMS Architect → Laravel Engineer | ✅ done | Schema spec at `briefs/specs/schema-s6-02-dynamic-milk-containers.md`; data migration mapping documented; old VARCHAR columns kept nullable |
| S6-03 — Settings: Farm profile card + Owner profile card redesign | UX/UI Designer → Flutter Engineer | ✅ done | UX spec at `briefs/specs/ux-s6-03-settings-profile-cards.md` |
| S6-04 — Settings: Milk types + Container types management sections | UX/UI Designer → Flutter Engineer | ✅ done | UX spec at `briefs/specs/ux-s6-04-milk-container-management.md` |
| S6-11 — Settings: Farm profile card (read view + edit sheet + ZIP lookup) | Flutter Engineer | ✅ done | Branch `feature/s6-11-12-settings-profile-cards` |
| S6-12 — Settings: Owner profile card (read view + edit sheet) | Flutter Engineer | ✅ done | Branch `feature/s6-11-12-settings-profile-cards` |
| S6-13 — Milk types management section | Flutter Engineer | ✅ done | Branch `feature/s6-13-15-dynamic-types-ui` |
| S6-14 — Container types management section | Flutter Engineer | ✅ done | Branch `feature/s6-13-15-dynamic-types-ui` |
| S6-15 — Product form dynamic dropdowns | Flutter Engineer | ✅ done | Branch `feature/s6-13-15-dynamic-types-ui` |

---

## Open blockers

None.

---

## Next actions

1. **Human:** Install APK v4.8.4+8 on a test device, log into each live farm account, and validate: (a) bill recalc button, (b) invoice detail Send button, (c) WhatsApp delivery within the 24 h Meta session window.
2. **CEO (after testing):** Get sign-off on what the next sprint covers — Customer app Phase 4, QA/test coverage, or new owner features.
