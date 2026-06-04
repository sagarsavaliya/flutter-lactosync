# DECISIONS LOG — App_LactoSync

## [2026-05-30] | Backend: Laravel API-only monolith in Docker | Akshara Laravel standard | Solution Architect

## [2026-05-30] | Database: MySQL 8 + Redis | Hostinger VPS deployment | Solution Architect

## [2026-05-30] | No web app — Flutter-only | Mobile-only product | Product

## [2026-05-30] | Docker stack under `lactosync/` project name | Isolated from other apps | Solution Architect

## [2026-05-30] | Production hosting: Hostinger VPS | CEO decision | CEO

## [2026-05-30] | App identity: lactosync_Flutter App | Distinguish from other Akshara apps | CEO

## [2026-05-30] | Tenant model: one farm, one owner | Subscription plans per farm at SaaS launch | CEO

## [2026-05-30] | OTP: WhatsApp only — no SMS, no email | Synchronous send for speed; 6-digit OTP in Redis | CEO

## [2026-05-30] | Phase 1 Auth shipped | Sanctum + Farm/FarmOwner + Flutter Dio | Technical

## [2026-05-30] | Onboarding v2: resume-from-step | Each step persists to DB; splash routes to last incomplete step | CEO

## [2026-05-30] | Role picker at signup — approved & built | After OTP: owner → PIN + farm setup; customer → coming soon shell | CEO

## [2026-05-30] | Unified signup before role | First/last name + mobile + OTP, then role + PIN | CEO

## [2026-05-30] | Product fields | milk_type: Gir Cow/Cow/Buffalo; container: Glass Bottle/Plastic Bag; unit: ltr | CEO

## [2026-05-30] | Coupon = flat amount off rate | effective_rate = rate − coupon_amount (not %) | CEO

## [2026-05-30] | Daily order log fields | customer_id, subscription_id, product_id, product_name, qty, shift, status, delivery_date, billing_month (YYYY-MM) | CEO

## [2026-05-30] | Billing model: invoice + payment | One invoice per customer per month (all subscriptions aggregated); invoice_lines for breakdown; payments as transactions (jama/udhar, cash/UPI, delivery boy handover) | CEO

## [2026-05-30] | Monthly bill generation | 1st of month from prior month delivered order logs; idempotent per customer + YYYY-MM | CEO

## [2026-05-30] | Owner module Phase 4–5 UI started | Daily Orders, Billing, Payment tabs + APIs approved by CEO "start working" | CEO

## [2026-05-30] | Customer detail screen — approved & built | Cards A–D with real API data; list tap navigates to detail | CEO

## [2026-05-30] | Global top bar + customers list v2 — approved & built | Farm name / screen title / profile menu; search+sort, mini toggle, vacation sheet | CEO
