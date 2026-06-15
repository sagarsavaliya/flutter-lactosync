# TECHNICAL TASKS — LactoSync
# Updated: 2026-06-15 | Customer app redesign active

## Core platform ✅
- [x] Auth, onboarding, owner module, billing, payments, WhatsApp
- [x] Customer app APIs + Flutter shell
- [x] Delivery boy module + forgot-PIN API
- [x] AppSnackBar global toasts + invoice print/share (web)

## Owner polish ✅ (2026-06-15)
- [x] Billing history month aggregates
- [x] Bill generate sheet lifecycle fix
- [x] Invoice detail regenerate/print/share
- [x] Add/edit customer form + farm prefill
- [x] `short_address` on daily orders API

## Git ✅
- [x] Polish commit on `main`
- [x] Synced with `origin/main`

## Customer redesign ⏳
- [ ] Chrome debug launch config (`.vscode/launch.json` — Flutter dart type)
- [ ] Screen-by-screen Flutter updates under `lib/features/customer/`
- [ ] Verify customer API base (`AppConfig.apiBaseUrlCustomer`) on web
- [ ] Hot-restart test each screen after polish batch

## Deploy 🔲
- [ ] Rebuild APK after customer redesign batch
- [ ] VPS deploy only if API changes needed
