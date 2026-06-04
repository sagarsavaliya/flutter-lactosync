# DESIGN TASKS — LactoSync Onboarding v2
# Updated: 2026-05-30

## D-001 Navigation map (CPO → UI/UX)
- [ ] Splash → resume logic (signed out / signup / onboarding step / dashboard)
- [ ] Auth stack: Sign up, Login, OTP, Role picker, Set PIN
- [ ] Owner stack: Farm details → Dashboard → Product setup → Customer → Subscription fork
- [ ] Customer stack: Customer home shell (Phase 4)

## D-002 Screen specs (minimal modern — not sparse classic)
- [ ] Sign up: first name, last name, mobile, CTA + “Already have account?”
- [ ] Role picker: two large cards — Customer | Dairy farm owner
- [ ] Farm details: name, address, city, state, zip — single scroll, one primary CTA
- [ ] Dashboard: checklist cards (Products → First customer → First subscription)
- [ ] Product setup: inline rows or bottom sheet — name, milk type chips, rate, unit, container
- [ ] Customer form: names, address block, landmark, contacts, WhatsApp toggle, active toggle
- [ ] Subscription: searchable customer dropdown, product picker, qty, coupon amount, shift, calculation card

## D-003 Design tokens (reuse existing theme)
- [ ] Spacing: 8pt grid — fields 16h / sections 24v
- [ ] Typography: single scale — title 20, body 15, caption 13
- [ ] One primary button per screen; secondary as text link only

## D-004 Copy & accessibility
- [ ] Plain English/Hindi-ready strings in app_strings
- [ ] Tap targets ≥ 48dp; error states on every field
