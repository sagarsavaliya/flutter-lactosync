# STATUS — LactoSync

> **Where we are / what's next:** Critical hotfix v4.9.1+15 ready — fixes 4 reported bugs (settings 500, dashboard milk_preparation null, customer auth 404, all customer screens broken). PHP already updated locally; needs VPS deploy. Flutter APK needs rebuild. See Next Actions below.
>
> _Last updated: 2026-06-10 by CEO_

---

## Project snapshot

| Item | Value |
| ---- | ----- |
| App version | `4.9.1+15` |
| APK path | `build/app/outputs/flutter-apk/app-release.apk` (rebuild needed) |
| API | Deployed on Hostinger VPS — live |
| Admin Web | https://superadmin.lactosync.com — live |
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
| **Home (Dashboard)** | KPI cards; quick actions; milk preparation panel; owner greeting |
| **Customers** | Search + sort; active/inactive mini-toggle; vacation sheet; tap → Customer Detail |
| **Customer Detail** | Cards A–D; edit sheets; delete (blocked on unpaid balance only); generate bill; send milk log; restore activity |
| **Daily Orders** | Order rows; skip button; mark delivered / adjust qty; generate orders button |
| **Billing** | Per-customer Billed / Collected / Outstanding grid; bulk-send invoices; tap → Invoice Detail |
| **Invoice Detail** | Line items; record payment (cash/UPI); send invoice via WhatsApp |
| **Payments** | Payment history with search + sort |
| **Settings** | Farm name, address, UPI VPA/payee, milk types, container sizes, product management, delivery slot times, WhatsApp toggle |
| **Activity Log** | `GET /owner/activities`; restore action |

### WhatsApp delivery ✅
- Server-side PNG generation for milk log and bill images
- 6 template notifications: bill ready, order log, payment confirmed, vacation set, vacation ended, qty/product change
- All template names configured via env vars on VPS (`.env` + container restart verified)
- OTP delivery working

### Tenant Admin Web ✅ (superadmin.lactosync.com)
- Login with PIN · Dashboard KPIs · Tenant list + detail
- Plan management (create/edit/archive) — max_subscriptions hidden from UI
- Payment tracking (record/edit/delete)
- Tenant profile editing (name, mobile, farm, address, GST, PIN reset, active toggle)
- Coupon / promotional offer system (create, enable/disable, apply to tenant)
- Top navbar layout; modern dashboard design

---

## Open items

| Item | Blocking? |
| ---- | --------- |
| `lacto_sync_monthly_bill` under Meta review | No — other 5 templates work |
| 4 manual WhatsApp verifications (MV-CA-01 to MV-CA-04) | Human action after APK install |
| **Hotfix VPS PHP deploy** | ⚠️ Required — 11 PHP files changed, run deploy commands below |
| **Hotfix APK build** | ⚠️ Required — build v4.9.1+15 |
| **VPS migrations** | ✅ All ran (Steps 1–3 already applied, customers auth migration applied) |

---

## Next actions

1. **Human (DevOps):** Deploy hotfix PHP to VPS:
   ```bash
   docker exec lactosync_flutter_app_api cp -r /var/www/app/app/Models/ProductOfferedSize.php /var/www/html/app/Models/
   # Copy all changed files (see hotfix file list in DECISIONS.md)
   docker exec lactosync_flutter_app_api php artisan config:clear && php artisan cache:clear && php artisan route:clear
   ```
   Or use the full rsync approach: `rsync -avz lactosync/src/app/ vps:/var/www/html/app/`

2. **Human (DevOps):** Run `flutter pub get && flutter build apk --release` from `d:\App_LactoSync` to produce APK v4.9.1+15

3. **Human:** Install APK v4.9.1+15 on all farms — verify: settings loads (not retry), dashboard shows milk prep, customer login works, customer screens load

4. **Human:** Run 4 manual verifications: scheduler clears vacation at 07:00, WhatsApp on vacation set, owner notified on address change, WhatsApp suppressed when toggle off

5. **Human:** Confirm `lacto_sync_monthly_bill` once Meta approves, then test bill send

6. **CEO (after testing):** Legal/compliance pass + public rollout plan

---

## Sprint CA — Customer App

**Status:** ✅ Complete — all 19 stories done, APK v4.8.7+13 built

**Sprint plan:** `briefs/sprints/sprint-customer-app.md`

| Story | Title | Status | Owner |
|---|---|---|---|
| PRD | Requirements document | Done | BA |
| Sprint plan | 19-story breakdown (CA-01–CA-19) | Written — awaiting approval | PM |
| CA-01 | DB schema — customers auth columns | **✅ Done — migration + model written, ready to migrate on VPS** | Laravel Engineer |
| CA-02 | Customer Sanctum guard + auth API | **✅ Done — guard, auth controller, and routes written.** | Laravel Engineer |
| CA-03 | Dashboard API | **✅ Done.** | Laravel Engineer |
| CA-04 | Order log API | **✅ Done — OrderController index() written.** | Laravel Engineer |
| CA-05 | Bills + payments APIs | **✅ Done.** | Laravel Engineer |
| CA-06 | Profile + farm-contact APIs | **✅ Done.** | Laravel Engineer |
| CA-07 | Qty change endpoint | **✅ Done — OrderController updateQty() written.** | Laravel Engineer |
| CA-08 | Single-day skip endpoint | **✅ Done — OrderController skip() written.** | Laravel Engineer |
| CA-09 | Vacation CRUD endpoints | **✅ Done.** | Laravel Engineer |
| CA-10 | Vacation auto-clear scheduler | **✅ Done — scheduler command written.** | Laravel Engineer |
| CA-11 | Flutter: customer auth screens | **✅ Done — auth screens, shell, and routes wired.** | Flutter Engineer |
| CA-12 | Flutter: dashboard screen | **✅ Done.** | Flutter Engineer |
| CA-13 | Flutter: order log + qty + skip | **✅ Done — repository, provider, and full orders page written.** | Flutter Engineer |
| CA-14 | Flutter: vacation screen | **✅ Done.** | Flutter Engineer |
| CA-15 | Flutter: bills screen | **✅ Done.** | Flutter Engineer |
| CA-16 | Flutter: payments screen | **✅ Done.** | Flutter Engineer |
| CA-17 | Flutter: profile screen | **✅ Done.** | Flutter Engineer |
| CA-18 | QA test plan | **✅ Done — test plan written (`briefs/sprints/qa-customer-app.md`).** | QA Engineer |
| CA-19 | APK build + VPS deploy | **✅ Done — APK built, VPS deploy instructions ready for human** | DevOps Engineer |

**Spec prerequisites (block all implementation):**

| Spec | Producer | Status |
|---|---|---|
| `briefs/specs/schema-customer-app.md` | DBMS Architect | **Complete** |
| `briefs/specs/ux-customer-app.md` | UX/UI Designer | **UX spec complete — awaiting Flutter implementation** |

**PM decisions resolved (logged here for the team):**
- Scheduler: new `customer:clear-ended-vacations` Artisan command (not extending the owner scheduler) — keeps concerns separate.
- `Customer` model upgrade to `Authenticatable` is additive; owner-side Eloquent usage unaffected — confirm in CA-02 AC.
- `customer` Sanctum guard added to `config/auth.php`; `farm_owner` and `admin` guards unchanged.
- No `customer_day_skips` table — PRD uses `daily_order_logs` upsert for skips (`qty=0, status=skipped`).

---

## Sprint OR — Owner Redesign

**Status:** ✅ Complete — APK v4.9.0+14 built (pubspec bumped), awaiting VPS deploy (human action)

**PRD:** `briefs/requirements/sprint-owner-redesign.md`

| Area | Summary |
|---|---|
| Container type + size schema redesign | New `container_types` / `container_type_sizes` tables; system defaults seeded; farm-custom containers supported; migration from flat `size_ml` required |
| Milk type defaults | 4 confirmed defaults; 3 extra defaults removed from seed (data preserved) |
| Product schema | Product = milk type + container type + rate; `product_offered_sizes` table; auto-generated name |
| Subscription line | New `container_size` column; container size dropdown in subscription form |
| Standardised quantity list | `milk_quantities` table (20 values 0.5–10 L); replaces all free-form qty inputs |
| Farm address prefill toggle | New `prefill_customer_address` boolean on `farms`; toggle in Owner Settings |
| Bug fixes (B-01–B-04) | Customer sign-in link; customer pre-selection in subscription form; qty label format; uniform input height |

| Artifact | Producer | Status |
|---|---|---|
| PRD | BA | **Complete** |
| Sprint plan | PM | Pending |
| DB schema spec | DBMS Architect | **Complete — see briefs/specs/schema-sprint-or.md** |
| UX spec | UX/UI Designer | **Complete — see briefs/specs/ux-sprint-or.md** |
| QA test plan | QA Engineer | **Complete — see briefs/sprints/qa-sprint-or.md** |
