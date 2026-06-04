# TECHNICAL TASKS — LactoSync
# Updated: 2026-05-30 | Owner onboarding v2 COMPLETE

## Sprint 0 — Architecture ✅
- [x] **T-001** Schema: products, customers, subscriptions, subscription_lines; extend farms/owners
- [x] **T-002** Onboarding state machine + `GET /onboarding/status`
- [x] **T-003** Signup OTP flow (replaces monolithic register for new users)

## Sprint 1 — Signup & resume ✅
- [x] **T-101** `POST /auth/signup/send-otp`, verify-otp, complete
- [x] **T-102** Onboarding farm PATCH + step advance
- [x] **T-103** Flutter splash resume routing
- [x] **T-104** Signup → OTP → set PIN screens

## Sprint 2 — Farm + products ✅
- [x] **T-201–204** Farm profile, products batch, setup checklist UI

## Sprint 3 — Customers + subscriptions ✅
- [x] **T-301–304** Customer CRUD, subscription builder, coupon rate card

## Sprint 4 — Customer app ⏸ DEFERRED
- Owner-first per CEO 2026-05-30

## Next phase
- [ ] Daily order log API + delivery run screen
- [ ] Monthly billing + PDF WhatsApp
