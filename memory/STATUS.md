# PROJECT STATUS — LactoSync
**Last Updated:** 2026-06-06 (EOD) | **Overall:** 🟢 v4.8.7+13 — Sprint CA complete; APK built; VPS deploy instructions ready for human

---

### 🏗️ Technical
- **App:** v4.8.7+13 · APK `build/app/outputs/flutter-apk/app-release.apk` (55.6 MB)
- **API:** Production live · https://flutterapi.lactosync.com/api/v1
- **Admin Web:** https://superadmin.lactosync.com — fully live (Sprint T1 complete + post-sprint additions)
- **Git:** Sprint CA complete; APK v4.8.7+13 built; VPS deploy instructions ready for human

### 🎨 Product & Design
- Admin web: top navbar, modern dashboard, edit plan (no max_subscriptions), coupon system, tenant profile edit
- WhatsApp: all 6 templates wired server-side; Meta template names set via env vars

---

## ✅ Completed today (2026-06-06)

### Customer App — Sprint CA (Flutter + Laravel)
- APK v4.8.7+13 built — Sprint CA complete (customer auth, dashboard, orders, bills, payments, profile, vacation)
- VPS deploy instructions generated; human must run migration + docker cp + smoke test

### Owner App (Flutter + Laravel)
- APK v4.8.6+12 built — Sprint 6 features (settings cards, dynamic types, 12hr time, contact picker, subscription suspended screen)
- WhatsApp template notifications fully wired for all 6 events:
  - Bill ready → `lacto_sync_monthly_bill`
  - Order log → `lacto_sync_order_log`
  - Payment confirmed → `lacto_sync_payment_receipt`
  - Vacation set → `lacto_sync_vacation_set`
  - Vacation ended / delivery resumed → `lacto_sync_vacation_ended`
  - Subscription qty/product changed → `lacto_sync_subscription_updated`
- Bug fix: template names were wrong defaults (mismatched with Meta); corrected via `.env` on VPS; smoke-tested SUCCESS

### Tenant Admin Web (superadmin.lactosync.com)
- Tenant profile edit sheet: name, mobile, farm name, address, city, state, zip, GST number, active toggle, PIN reset
- Coupon / promotional offer system: create coupons, toggle active, apply to tenant (extends renewal date)
- `PUT /api/admin/v1/tenants/{id}/profile` endpoint live
- Coupon API + DB tables (migrations ran on VPS): `coupons`, `tenant_coupon_redemptions`
- Coupons nav tab added to top navbar

---

## ✅ Live test farms
| Farm | Mobile | PIN |
|------|--------|-----|
| Farenidham Gaushala | 9998866008 | 1234 |
| Gokul Dairy Farm | 9876543210 | 1234 |

---

## 🔲 Pending validation (your device)
1. Install APK v4.8.6+12 on test device
2. Set vacation for a customer → WhatsApp `lacto_sync_vacation_set` should arrive
3. Change subscription shift → WhatsApp `lacto_sync_subscription_updated` should arrive
4. Record payment → WhatsApp `lacto_sync_payment_receipt` should arrive
5. Confirm `lacto_sync_monthly_bill` once Meta approves it (currently "in review")

## ⚠️ One open item
- `lacto_sync_monthly_bill` is still under Meta review — bill send will silently skip until approved

## 🔲 Coming next (when you resume)
- Legal/compliance pass before public farm rollout
- Sales/marketing activation
