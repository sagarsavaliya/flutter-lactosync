# PROJECT STATUS — LactoSync
**Last Updated:** 2026-05-30 | **Overall:** 🟢 v4.8.4+8 — customer detail alignment + billing badges

---

### 🏗️ Technical
- **Customer list:** Search/sort same height (44px); mint cards per mockup
- **Daily orders:** Fixed row layout (no vertical text wrap)
- **Billing:** Per-customer Billed / Collected / Outstanding grid (no amount badges)
- **Customer detail:** Delete when bills paid; generate bill button; activity log + restore
- **Delete rules:** Block only unpaid balance (`CUSTOMER_HAS_UNPAID_BILLS`); subscriptions delete without log-block
- **Activity API:** `GET /owner/activities`, `POST /owner/activities/{id}/restore`
- **UI:** Green borders on search/sort/inputs; daily orders skip button; search+sort on orders/billing/payments
- **WhatsApp docs:** Server PNG milk log + bill (DejaVu fonts); payment receipt text on record; UPI QR share API
- **Dashboard:** Quick actions — Find Customer, Gen Bill, Record Payment, View QR (share to customer)
- **No PDF in app:** Settings use image-only WhatsApp delivery; client `pdf` package removed
- **Deploy:** ✅ API redeployed 2026-05-30 — activity table + delete logic live
- **APK:** `build/app/outputs/flutter-apk/app-release.apk` v4.8.4+8
- **Bill generate:** Recalculates existing month bill (not duplicate invoices)
- **WhatsApp:** Credentials OK on server; bills/logs use session images (24h Meta window); payment receipt errors now surfaced in app

### 🎨 Product & Design
- Milk log / bill layout: customer left, farm right, product/rate/month centered, thank-you footer
- Owner popups: Cancel + primary actions side-by-side

---

## ✅ Live farm logins

| Farm | Mobile | PIN |
|------|--------|-----|
| Shreeji Gir Gaushala | 9429040899 | *(your PIN)* |
| Farenidham Gaushala | 9998866008 | 1234 |
| Gokul Dairy Farm | 9876543210 | 1234 |

---

## 🔲 Coming Next
- Install APK v4.8.4+6; test bill recalc icon, bill detail Send button, WhatsApp with customer who messaged farm in last 24h
