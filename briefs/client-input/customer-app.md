# Client Input — Customer-Facing App

_Captured from conversation on 2026-06-06. Raw requirements as stated by the client._

---

## Design / Theme
- Same design, feel, and theme as the existing owner app (Flutter, same colour scheme, typography, component style).

## Auth
- Customer login + sign up.
- Login: mobile number + PIN (same pattern as owner app).
- Sign up: OTP verification → set PIN.

## Dashboard
- Daily orders for the current month (a calendar-style or list view showing each day's delivery).
- Previous bills (invoice history).
- Payments (payment history).
- Active subscriptions.

## Order Quantity Change
- Morning-shift subscriber: can change **tomorrow's** delivery quantity.
  - Lock condition: after the farm's **morning** order-log schedule time has passed.
- Evening-shift subscriber: can change **today's** delivery quantity.
  - Lock condition: after the farm's **evening** order-log schedule time has passed.
- After the lock time, the edit UI is disabled / shows a "locked" state.

## Vacation
- Customer marks vacation with a start date and end date.
- Scheduler automatically turns off vacation mode for the customer when their start-delivery-from date arrives (i.e., `vacation_end + 1 day`).
- Scheduler sends a WhatsApp notification (`lacto_sync_vacation_ended`) **one day before** delivery resumes.

## Feature additions (confirmed by CEO + client on 2026-06-06)

1. **Outstanding balance banner + UPI QR** — Dashboard shows "You owe ₹X" with farm owner's UPI QR code so the customer can self-pay.
2. **Single-day skip** — Skip exactly one delivery day without setting a full vacation range.
3. **Profile self-management** — View and edit their own name. Edit delivery address (owner notified via WhatsApp on address change; rate-limited to once per day). Mobile number is read-only (cannot be changed by customer).
4. **In-app bill viewer** — Show the actual bill PNG image inline for each month; don't rely on WhatsApp to be the only channel.
5. **Farm contact card** — Tap-to-call and tap-to-WhatsApp button for the farm owner.
6. **WhatsApp notification toggle** — Customer can turn their own WhatsApp notifications on/off (currently owner-controlled only).
7. **Multiple subscription lines shown separately** — Each subscription line (morning milk, evening curd, etc.) gets its own qty-change control.

## Deferred (not in MVP)
- FCM push notifications
- Referral / coupon code entry by customer
- Delivery status ("delivered/pending today") — requires driver flow not yet in system
- Delivery history beyond current working months
