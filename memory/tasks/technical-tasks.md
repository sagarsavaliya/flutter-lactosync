# TECHNICAL TASKS — LactoSync
# Updated: 2026-06-14 | Device-test ready v4.10.15+37

## Core platform ✅
- [x] Auth, onboarding, owner module (6 tabs), billing, payments, WhatsApp
- [x] Customer app APIs + Flutter shell (Sprint CA)
- [x] Delivery boy module + route sheet
- [x] Superadmin web live

## Owner redesign sprint ✅ (2026-06)
- [x] Frames 1–14 aligned to redesign HTML
- [x] `RedesignScaffold`, `CustomerDetailColors`, owner design system
- [x] Route sheet redesign + skip/qty API fixes
- [x] Settings schedule `H:i` format fix

## Bug-fix batch ✅ (CEO approved 2026-06-14)
- [x] MTD consumption — `DeliveryLogPresenter::logsThroughDate()` + `ConsumptionAggregator`
- [x] Billing hero PENDING scoped to selected month
- [x] Calendar line fallback (no subscription-level merge)
- [x] Route sheet `customer_id` + `quantity` field
- [x] Payments `invoice_number` on API + Flutter model
- [x] PDF as default document share format

## Deploy ✅
- [x] VPS Docker rebuild (`lactosync_flutter_app_api` + queue + scheduler)
- [x] APK v4.10.15+37 built

## Next ⏳
- [ ] Farenidham device test (CEO)
- [ ] Commit + push WIP when approved
- [ ] `customer_bills_page` redesign (low — unrouted)
- [ ] Meta approval: `lacto_sync_monthly_bill` WhatsApp template
