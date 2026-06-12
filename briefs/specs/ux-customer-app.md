# UX Spec — LactoSync Customer App (CA-11 through CA-17)

> **Author:** UX/UI Designer
> **Date:** 2026-06-06
> **Source PRD:** `briefs/requirements/customer-app.md`
> **Sprint plan:** `briefs/sprints/sprint-customer-app.md`
> **Blocks stories:** CA-11 · CA-12 · CA-13 · CA-14 · CA-15 · CA-16 · CA-17

---

## Design Language Reference

All customer screens must be visually identical to the existing owner app. The design tokens below are the single source of truth. Do not introduce new values.

### Colour tokens (`lib/core/theme/app_colors.dart`)

| Token | Light | Dark |
|---|---|---|
| `primary` | `#386948` (forest green) | `#4DB89A` (teal green) |
| `primaryFaint` | `#B9EFC5` | `#1A3530` |
| `bg` | `#F7FAF4` | `#111418` |
| `surface` | `#FFFFFF` | `#1C2027` |
| `border` | `#E3E6EA` | `#2C3038` |
| `ink` | `#1A1D21` | `#E8EAED` |
| `inkMuted` | `#6B727B` | `#9AA1AA` |
| `inkFaint` | `#9AA1AA` | `#6B727B` |
| `success` | `#1E8E5A` | `#3ECE82` |
| `successFaint` | `#E4F4EC` | `#152C20` |
| `warning` | `#B9770A` | `#E8A230` |
| `warningFaint` | `#FBF1DE` | `#2E2210` |
| `danger` | `#C0392B` | `#E05C4E` |
| `dangerFaint` | `#FBEA E8` | `#2E1512` |

Theme seed: `ColorScheme.fromSeed(seedColor: AppColors.primary)` — same call as the owner app's `buildLightTheme()` / `buildDarkTheme()`.

### Component rules (copy exactly from owner app)

- **Cards:** `AppCard` widget — elevation 0, `border` colour side, `BorderRadius.circular(AppRadius.md)` (12 dp). Background: `surface`. Use `AppCard` for all card surfaces.
- **Input fields:** `AppTextField` widget — `InputDecoration` style from `app_theme.dart`: filled, `surface` fill, border `border` colour, focused border `primary` 1.4 dp, error border `danger`. Content padding `horizontal: AppSpace.md (16), vertical: 11`.
- **Buttons:** Elevated = `primary` bg, white text, height 48 dp (`AppSize.field`). Outlined = `surface` bg, `ink` text, `border` side. TextButton = `primary` text.
- **Bottom sheets:** `showModalBottomSheet(isScrollControlled: true, ...)`. Theme supplies `shape: RoundedRectangleBorder(topLeft: 16, topRight: 16)`, drag handle shown, `surface` background. Wrap content in `Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom))`.
- **Snackbars:** `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(...)))`. Floating behaviour, rounded. Error messages use `SnackBar(content: Text(...), backgroundColor: AppColors.danger)`. Success messages use default (no colour override).
- **Loading state:** `Center(child: CircularProgressIndicator())` centred on the page body. No skeleton screens except the bill image viewer (specified separately).
- **Error / retry state:** `Center(child: Column([Text(errorMessage), TextButton('Retry', onPressed: reload)]))`.
- **Section headers:** `Text(title, style: AppText.sectionTitle)` — matches `OwnerSectionHeader` pattern.
- **ListTile:** `contentPadding: EdgeInsets.zero` inside a card (owner pattern). Dense + compact visual density.
- **Spacing:** `AppSpace.xs = 4`, `AppSpace.sm = 8`, `AppSpace.md = 16`, `AppSpace.lg = 24`, `AppSpace.xl = 32`.
- **Typography:** `AppText.screenTitle`, `AppText.sectionTitle`, `AppText.cardTitle`, `AppText.body`, `AppText.label`, `AppText.meta` — all from `app_typography.dart`. Never hardcode font sizes.
- **Page padding:** `ListView.padding` or `SingleChildScrollView` padding = `EdgeInsets.all(AppSpace.lg)` (same as `OwnerSettingsPage`).

---

## File / folder conventions

All new customer Flutter files go under `lib/features/customer/`. Mirror the existing owner feature structure:

```
lib/features/customer/
  data/
    repositories/
      customer_auth_repository.dart        ← CA-11
      customer_repository.dart             ← CA-12 through CA-17
    models/                                ← response DTOs
  domain/
    entities/                              ← domain models
  presentation/
    providers/
      customer_auth_provider.dart
      customer_provider.dart
    pages/
      customer_login_page.dart             ← CA-11
      customer_otp_page.dart               ← CA-11
      customer_set_pin_page.dart           ← CA-11
      customer_dashboard_page.dart         ← CA-12
      customer_orders_page.dart            ← CA-13
      customer_vacation_page.dart          ← CA-14
      customer_bills_page.dart             ← CA-15
      customer_payments_page.dart          ← CA-16
      customer_profile_page.dart           ← CA-17
    shell/
      customer_shell.dart                  ← shell + bottom nav
    widgets/
      (shared widgets for customer feature)
```

go_router path prefix: `/customer/...` — completely separate from `/owner/...` routes.

Token storage key: `customer_auth_token` (must not collide with `auth_token` used by the owner app).

---

## Screen 0 — Customer Shell

**Route:** Shell route wrapping `/customer/home`, `/customer/orders`, `/customer/bills`, `/customer/profile`

**Purpose:** Provides the persistent AppBar + bottom navigation bar for all four main customer tabs.

### Layout structure

`Scaffold` with:
- `appBar`: `AppBar` (uses theme `appBarTheme` — `surface` background, elevation 0). Title = farm name string loaded from `customerDashboardProvider` (shows farm name once data loads; shows empty string while loading — no shimmer in AppBar).
- `body`: `widget.child` (the active tab's page widget, passed via `StatefulShellBranch` in go_router).
- `bottomNavigationBar`: Custom `DecoratedBox` with top border (same decoration pattern as `OwnerShell`). Contains a `SafeArea(top: false)` wrapping a `Row` of 4 `_NavItem` widgets.

### Bottom nav tabs

| Index | Route | Icon | Label |
|---|---|---|---|
| 0 | `/customer/home` | `Icons.home_rounded` | Home |
| 1 | `/customer/orders` | `Icons.calendar_month_outlined` | Orders |
| 2 | `/customer/bills` | `Icons.receipt_long_outlined` | Bills |
| 3 | `/customer/profile` | `Icons.person_outline_rounded` | Profile |

### _NavItem widget

Identical to `OwnerShell._NavItem`. Selected colour = `AppColors.primary`. Unselected colour = `AppColors.inkMuted.withValues(alpha: 0.6)`. Icon size 24 dp, label `AppText.meta` (10–11 sp). `InkWell` with `BorderRadius.circular(8)`. Column: icon + 4 dp gap + label.

### Navigation

- The shell is entered after successful login (from `customer_set_pin_page` or `customer_login_page` → `context.go('/customer/home')`).
- Within the shell, each `_NavItem.onTap` calls `context.go(path)` (replaces history, same as OwnerShell).
- Routes outside the shell (vacation screen, bill image viewer, payments screen) are pushed with `context.push(...)` from within tab pages — they receive their own AppBar with a back arrow.

---

## Auth Screens (CA-11)

All four auth screens share a common layout skeleton:

```
Scaffold(bg: AppColors.bg)
  └─ SafeArea
       └─ SingleChildScrollView(padding: EdgeInsets.all(AppSpace.lg))
            └─ Column(crossAxisAlignment: CrossAxisAlignment.stretch)
                 ├─ SizedBox(height: AppSpace.xl)
                 ├─ [Icon or logo — 56×56 primary icon]
                 ├─ SizedBox(height: AppSpace.md)
                 ├─ Text(title, style: AppText.screenTitle)
                 ├─ SizedBox(height: AppSpace.xs)
                 ├─ Text(subtitle, style: AppText.body, color: inkMuted)
                 ├─ SizedBox(height: AppSpace.xl)
                 ├─ [form fields]
                 ├─ SizedBox(height: AppSpace.md)
                 ├─ [primary CTA button]
                 └─ [secondary text link if applicable]
```

No custom logo/branding beyond the icon — match the existing owner auth pages (`sign_in_page.dart`, `set_pin_page.dart`, `verify_otp_page.dart`) exactly in layout proportion.

---

### Screen 1 — Customer Login

**Route:** `/customer/login`
**Purpose:** Customer enters their mobile number and PIN to log in.

#### Layout structure

`Scaffold` → `SafeArea` → `SingleChildScrollView` → `Column` containing:
1. Spacing (xl)
2. Center-aligned `Icon(Icons.local_drink_outlined, size: 56, color: primary)` — represents milk/dairy
3. Spacing (md)
4. `Text("Sign in", style: AppText.screenTitle)` — centered
5. `Text("Enter your mobile number and PIN", style: AppText.body, color: inkMuted)` — centered
6. Spacing (xl)
7. Mobile number field (AppTextField)
8. Spacing (sm)
9. PIN field (AppTextField, obscure text, 4-digit)
10. Spacing (xs)
11. `Align(alignment: Alignment.centerRight, child: TextButton("Forgot PIN?", onPressed: ...))`
12. Spacing (md)
13. Primary elevated button: "Sign in"
14. Spacing (sm)
15. Center TextButton: "New here? Send OTP first" → navigates to `/customer/login/send-otp` (which starts the OTP flow)

#### Key UI components

- **Mobile number field**: `AppTextField`, label "Mobile number", hint "10-digit number", `keyboardType: TextInputType.phone`, `inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]`. Error: "Enter mobile number" (empty) or "Enter valid 10-digit number" (not 10 digits).
- **PIN field**: `AppTextField`, label "PIN", hint "4 digits", `obscureText: true`, `keyboardType: TextInputType.number`, `inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)]`. Trailing: eye icon to toggle visibility. Error: "Enter PIN" (empty) or "PIN must be 4 digits" (not 4 digits).
- **Sign in button**: Full-width elevated. Shows `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)` in place of text while the API call is in-flight. Disabled during loading.
- **Forgot PIN?**: Right-aligned `TextButton` in `primary` colour. Navigates to `/customer/otp` with a route parameter `reason: forgot`.
- **"New here?" link**: Navigates to `/customer/otp` with `reason: first_time`.

#### Navigation

- Entry: from `/` splash (if no stored `customer_auth_token`) or from `/customer/otp` after forgot-PIN flow completes.
- Successful login → `context.go('/customer/home')`.
- Forgot PIN → `context.push('/customer/otp?reason=forgot')`.
- First-time user → `context.push('/customer/otp?reason=first_time')`.

#### Interaction rules

1. Validate mobile (non-empty, 10 digits) and PIN (non-empty, 4 digits) on button tap before API call.
2. Show field-level error text inline below the offending field.
3. On `POST /api/customer/v1/auth/login` HTTP 401: show error snackbar "Invalid mobile number or PIN."
4. On network error: show error snackbar "Connection error — please try again."
5. On success: store token as `customer_auth_token` in secure storage → `context.go('/customer/home')`.

#### Empty/error states

- Fields show inline `errorText` per `InputDecoration` pattern.
- API errors appear as a red snackbar at the bottom (floating, rounded — theme default).

---

### Screen 2 — Send OTP (entry into OTP flow)

**Route:** `/customer/otp` (also handles `?reason=first_time` and `?reason=forgot`)
**Purpose:** Customer enters their mobile number to receive a 6-digit OTP on WhatsApp.

#### Layout structure

Same auth skeleton as Screen 1, with:
1. `Icon(Icons.whatsapp, size: 56, color: primary)` or `Icon(Icons.message_outlined, size: 56, color: primary)`
2. Title: "Verify with OTP"
3. Subtitle: "We'll send a 6-digit code on WhatsApp"
4. Mobile number field (AppTextField)
5. Primary button: "Send OTP"
6. Secondary text link (if `reason=forgot`): "Back to sign in" → pops navigation

#### Key UI components

- **Mobile number field**: same spec as Screen 1's mobile field.
- **Send OTP button**: full-width elevated. Loading state while API call in-flight.

#### Navigation

- Entry: from Screen 1 "Forgot PIN?" or "New here?" links.
- On success (`POST /api/customer/v1/auth/send-otp`) → `context.push('/customer/otp/verify?reason=...')` passing the mobile number as a query param or route extra.
- "Back to sign in" → `context.pop()`.

#### Interaction rules

1. Validate mobile non-empty and 10 digits before calling API.
2. HTTP 422 ("Mobile not found" or customer not registered): show error snackbar with the API `message` field verbatim.
3. On success: navigate forward to OTP entry screen.

---

### Screen 3 — Verify OTP

**Route:** `/customer/otp/verify`
**Purpose:** Customer enters the 6-digit OTP received on WhatsApp.

#### Layout structure

Same auth skeleton with:
1. `Icon(Icons.lock_open_outlined, size: 56, color: primary)`
2. Title: "Enter OTP"
3. Subtitle: "Check WhatsApp for the 6-digit code sent to {mobile}"
4. OTP input field (AppTextField)
5. Primary button: "Verify OTP"
6. Resend row (timer + link)

#### ASCII wireframe

```
┌────────────────────────────────────┐
│                                    │
│           🔓  (icon 56dp)          │
│                                    │
│          Enter OTP                 │
│    Check WhatsApp for the          │
│    6-digit code sent to            │
│    98765 43210                     │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  OTP (6 digits)              │  │
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │       Verify OTP             │  │  ← primary button
│  └──────────────────────────────┘  │
│                                    │
│  Resend OTP in 0:28   [Resend]     │  ← resend row
│                                    │
└────────────────────────────────────┘
```

#### Key UI components

- **OTP field**: `AppTextField`, label "OTP", hint "6 digits", `keyboardType: TextInputType.number`, `inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]`. Error: "Enter OTP" (empty) or "OTP must be 6 digits" (not 6).
- **Verify button**: full-width elevated, loading state during API call.
- **Resend row**: `Row([Text("Resend OTP in {countdown}", style: AppText.meta, color: inkMuted), Spacer(), TextButton("Resend", onPressed: _onResend)])`. The `TextButton` is disabled (greyed out) while countdown > 0; enabled when countdown reaches 0:00. Countdown starts at 30 seconds and decrements each second using a `Timer.periodic`. When the user taps "Resend", the countdown resets to 30 s and `POST /api/customer/v1/auth/send-otp` is called again. The resend TextButton uses `primary` colour when enabled and `inkFaint` when disabled.

#### Navigation

- Entry: pushed from "Send OTP" screen.
- On `POST /api/customer/v1/auth/verify-otp` success → `context.push('/customer/set-pin')` passing mobile + OTP verification token (or signed session flag) as route extras.
- No direct back navigation shown — user can use system back to return to the mobile entry screen.

#### Interaction rules

1. Validate OTP non-empty and exactly 6 digits before calling API.
2. HTTP 422 (invalid OTP): show error snackbar "Invalid or expired OTP."
3. HTTP 422 (expired OTP): show error snackbar "OTP has expired. Tap Resend."
4. On success: navigate to Set PIN screen.
5. Resend tap: show brief success snackbar "OTP resent on WhatsApp." and restart 30s countdown.

---

### Screen 4 — Set PIN

**Route:** `/customer/set-pin`
**Purpose:** Customer sets a new 4-digit PIN (used for both first-time registration and forgot-PIN reset).

#### Layout structure

Same auth skeleton with:
1. `Icon(Icons.pin_outlined, size: 56, color: primary)` (or `Icons.lock_outline`)
2. Title: "Set your PIN"
3. Subtitle: "Choose a 4-digit PIN — you'll use this to sign in"
4. New PIN field
5. Confirm PIN field
6. Primary button: "Save PIN"

#### Key UI components

- **New PIN field**: `AppTextField`, label "New PIN", hint "4 digits", `obscureText: true`, numeric, max 4 digits, trailing eye-toggle icon.
- **Confirm PIN field**: `AppTextField`, label "Confirm PIN", hint "4 digits", `obscureText: true`, numeric, max 4 digits, trailing eye-toggle icon. Error: "PINs do not match" when value differs from new PIN (validated on submit).
- **Save PIN button**: full-width elevated, loading state during API call.

#### Navigation

- Entry: pushed from "Verify OTP" screen.
- On `POST /api/customer/v1/auth/set-pin` success: the API returns a Sanctum token. Store it as `customer_auth_token`. Navigate to `context.go('/customer/home')` (clears auth stack).
- No back navigation shown (user should not return to OTP entry without resending).

#### Interaction rules

1. Validate new PIN non-empty and 4 digits. Validate confirm PIN matches new PIN. Both checks run on button tap.
2. Show inline `errorText` on the offending field.
3. HTTP 422 from API: show error snackbar with the API `message`.
4. On success: store token, navigate to dashboard.

---

## Screen 5 — Customer Shell + Dashboard (CA-12)

**Route (shell tab 0):** `/customer/home`
**Purpose:** The landing screen after login — shows outstanding balance, monthly summary, active subscriptions, and quick-nav links.

### Layout structure

`Scaffold` provided by `CustomerShell` (AppBar + bottom nav). Body = `RefreshIndicator` wrapping a `ListView` with `padding: EdgeInsets.all(AppSpace.lg)`. The `RefreshIndicator` triggers a re-fetch of `customerDashboardProvider`.

Inside the `ListView`, sections appear in this order:
1. Outstanding balance card (conditional — shown only when `outstanding_balance > 0`)
2. Monthly summary row
3. Active subscriptions section header + card
4. Quick-nav row

### ASCII wireframe (balance present)

```
┌─ AppBar ─────────────────────────────┐
│  Shreeji Gir Gaushala          👤    │  ← farm name as title
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │  You owe ₹1,250               │  │  ← balance card (hidden if ₹0)
│  │                                │  │
│  │  ┌──────────────────────────┐  │  │
│  │  │  [UPI QR image 200×200]  │  │  │
│  │  └──────────────────────────┘  │  │
│  │  Pay now                       │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────┐ │
│  │Delivered │ │ Skipped  │ │ Vacn │ │  ← summary chips
│  │    18    │ │    2     │ │   5  │ │
│  └──────────┘ └──────────┘ └──────┘ │
│                                      │
│  Active subscriptions                │  ← section header
│  ┌────────────────────────────────┐  │
│  │  Full Cream Milk · Morning · 1L│  │
│  │─────────────────────────────── │  │
│  │  Curd · Evening · 500ml        │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌──────────────┐  ┌──────────────┐  │
│  │  Bills       │  │  Payments    │  │  ← quick-nav cards
│  │  receipt icon│  │  payments icon│  │
│  └──────────────┘  └──────────────┘  │
│                                      │
├─ Bottom Nav ──────────────────────────┤
│  Home  Orders  Bills  Profile        │
└──────────────────────────────────────┘
```

### Key UI components

#### Outstanding balance card

Condition: render only when `outstanding_balance > 0`. If 0, this card is completely absent (no placeholder space).

`AppCard` containing a `Column` (centered content, `crossAxisAlignment: CrossAxisAlignment.center`):
- `Text("You owe ₹{amount}", style: AppText.cardTitle, color: AppColors.danger)` — formatted with Indian number format (e.g. "₹1,250"). Top padding `AppSpace.md`.
- `SizedBox(height: AppSpace.md)`
- `ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(upi_qr_url, width: 200, height: 200, fit: BoxFit.contain))`. The QR URL may require auth headers — use a Dio-backed `Image` or a signed URL from the API (implement via `FadeInImage` with a network fetch through the auth-enabled Dio client if needed; the Flutter Engineer decides the implementation approach based on what the API returns).
  - Loading state: `SizedBox(200, 200, child: Center(child: CircularProgressIndicator()))`.
  - Error state: `SizedBox(200, 200, child: Center(child: Icon(Icons.qr_code_2_outlined, size: 64, color: inkFaint)))`.
- `SizedBox(height: AppSpace.xs)`
- `Text("Tap to pay via UPI", style: AppText.meta, color: inkMuted)` — descriptive label. No tap action on the QR image itself (the QR is scanned externally from the customer's phone camera).

Full card padding: `AppSpace.md` on all sides.

#### Monthly summary row

Three side-by-side stat chips in a `Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly)`.

Each chip is a small `AppCard` (flex: 1, margin: symmetric horizontal 4 dp) containing a `Column(crossAxisAlignment: CrossAxisAlignment.center)`:
- `Text(count.toString(), style: AppText.sectionTitle)` — bold count number
- `Text(label, style: AppText.meta, color: inkMuted)` — "Delivered", "Skipped", "On vacation"

Padding inside each chip: `EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.xs)`.

Labels and their data mapping:
- "Delivered" ← `monthly_summary.delivered`
- "Skipped" ← `monthly_summary.skipped`
- "On vacation" ← `monthly_summary.vacation_days`

#### Active subscriptions section

`Text("Active subscriptions", style: AppText.sectionTitle)` (section header).
`SizedBox(height: AppSpace.sm)`.
`AppCard` containing a `Column` of `ListTile` rows (one per subscription line), separated by `Divider`s:
- Each `ListTile`: `title: Text("{product_name}", style: AppText.label)`, `subtitle: Text("{shift} · {qty}", style: AppText.meta, color: inkMuted)`. No trailing widget. `contentPadding: EdgeInsets.zero`.
- Shift label: "Morning" or "Evening" (capitalised display value derived from the `shift` field).
- Qty: displayed as "1 L" or "500 ml" (the raw `qty` from the API — Flutter Engineer appends the unit from the product or subscription line if the API provides it; if not, just display the number).

Empty state: if `active_subscriptions` is empty, show a single `ListTile` with `title: Text("No active subscriptions", style: AppText.body, color: inkMuted)`.

#### Quick-nav row

Two tappable `AppCard` widgets in a `Row(children: [Expanded(...), SizedBox(width: AppSpace.sm), Expanded(...)])`.

Each card = `InkWell(onTap: ..., borderRadius: ..., child: Padding(AppSpace.md, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 28, color: primary), SizedBox(AppSpace.xs), Text(label, style: AppText.label)])))`.

| Card | Icon | Label | Destination |
|---|---|---|---|
| Bills | `Icons.receipt_long_outlined` | "Bills" | `context.go('/customer/bills')` (switches bottom nav tab) |
| Payments | `Icons.payments_outlined` | "Payments" | `context.push('/customer/payments')` |

### Navigation

- Entry: from successful login (`context.go('/customer/home')`) or by tapping Home tab in bottom nav.
- Bills card → switches to tab 2 via `context.go('/customer/bills')`.
- Payments card → pushes `/customer/payments` (full-screen, back arrow to return).

### Interaction rules

- `RefreshIndicator` on pull-down calls `ref.invalidate(customerDashboardProvider)`.
- The entire page body is driven by `ref.watch(customerDashboardProvider)` which returns an `AsyncValue`.
- Loading: `Center(child: CircularProgressIndicator())`.
- Error: `Center(child: Column([Text("Failed to load"), TextButton("Retry", onPressed: reload)]))`.

### Empty / error states

- **Zero balance:** outstanding balance card is absent. The remaining sections always render.
- **No subscriptions:** the subscriptions card shows the empty text above.
- **API error:** full-page error state with Retry button.

---

## Screen 6 — Order Log (CA-13)

**Route (shell tab 1):** `/customer/orders`
**Purpose:** Scrollable day-by-day log for the selected month; allows qty changes and single-day skips on eligible future days.

### Layout structure

`Scaffold` (provided by shell) → `Column`:
1. Month navigation header (fixed, not scrollable) — full-width row
2. `Expanded(child: ListView.builder(...))` — scrollable day list

The day list renders one row per calendar day of the selected month (28–31 rows).

### ASCII wireframe

```
┌─ AppBar ─────────────────────────────┐
│  Orders                              │
├──────────────────────────────────────┤
│  ◀  May 2026  ▶                      │  ← month nav header (fixed)
├──────────────────────────────────────┤
│  Mon, 1 Jun   ✓ 1 L       (green)   │  ← delivered
│  Tue, 2 Jun   Skipped     (amber)   │
│  Wed, 3 Jun   On vacation (purple)  │
│  Thu, 4 Jun   ○ 1 L       (grey)    │  ← expected, future
│  Fri, 5 Jun   –           (grey)    │  ← past, no record
│  Sat, 6 Jun   🔒          (grey)    │  ← locked future day
│  Sun, 7 Jun   ○ 1 L       (grey)    │  ← tappable future day
│  ...                                 │
├─ Bottom Nav ──────────────────────────┤
│  Home  Orders  Bills  Profile        │
└──────────────────────────────────────┘
```

### Key UI components

#### Month navigation header

`Container(color: surface, padding: EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm))` containing a `Row`:
- `IconButton(Icons.chevron_left, onPressed: previousMonth)` — disabled if the customer has no data for earlier months (the Flutter Engineer may choose to allow navigation back 12 months maximum, matching PRD §8 note on history scope).
- `Expanded(child: Text("{Month} {Year}", style: AppText.sectionTitle, textAlign: TextAlign.center))` — e.g. "June 2026".
- `IconButton(Icons.chevron_right, onPressed: nextMonth)` — disabled if `selectedMonth` is the current month or future (customers cannot navigate forward beyond current month).

A thin `Divider` below the header row separates it from the list.

#### Day row

Each row in the `ListView.builder` is a `ListTile` with `contentPadding: EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs)`:

- **leading:** Date label column: `Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(dayOfWeek, style: AppText.meta, color: inkMuted), Text(dayNum, style: AppText.label)])` — e.g. "Mon" on top, "6" below. Width: 36 dp.
- **title:** Status label or subscription entries (see below).
- **trailing:** Status icon or lock icon.

Status display rules per row:

| API `status` | Title text | Title colour | Trailing |
|---|---|---|---|
| `delivered` | "{qty} L" (or qty value) | `ink` | `Icon(Icons.check_circle_rounded, color: success, size: 20)` |
| `skipped` | "Skipped" | `warning` | `Icon(Icons.remove_circle_outline, color: warning, size: 20)` |
| `vacation` | "On vacation" | `primary` | `Icon(Icons.beach_access_outlined, color: primary, size: 20)` |
| `expected` (future, unlocked) | "{expected qty}" | `inkMuted` | `Icon(Icons.circle_outlined, color: inkFaint, size: 20)` — tappable row |
| `expected` (future, locked) | "{expected qty}" | `inkMuted` | `Icon(Icons.lock_outline, color: inkFaint, size: 20)` |
| `no_record` (past) | "—" | `inkFaint` | `SizedBox.shrink()` |

When a customer has **multiple subscription lines** (e.g. morning milk + evening curd), the `title` column displays a `Column` with one line per subscription entry: `Text("{product_name}: {qty}", style: AppText.meta)`. The trailing icon reflects the dominant status (if any line is `delivered`, use green tick; otherwise follow priority: vacation > skipped > locked > expected).

**Tappable rows:** `expected` (unlocked future) days respond to `onTap`. `delivered`, `skipped`, `vacation`, `no_record`, and `locked` rows have no `onTap` — tapping a locked row shows a snackbar.

**Locked row tap:** `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Changes are locked — order already submitted.")))`. No bottom sheet.

Row separator: `Divider(height: 1, thickness: 1)` between rows (thin hairline).

#### Day edit bottom sheet (future unlocked day)

Triggered by tapping an `expected` (unlocked) day row. Opens with `showModalBottomSheet(isScrollControlled: true, ...)`.

Sheet content (wrapped in `Padding` with bottom inset for keyboard):

```
┌──────────────────────────────────┐
│  ≡  (drag handle — from theme)  │
│  Thursday, 5 June               │  ← sheet title (AppText.sectionTitle)
│                                  │
│  Full Cream Milk (Morning)       │  ← subscription line label (AppText.label)
│  Qty  [−]  1  [+]               │  ← stepper row
│                                  │
│  Curd (Evening)                  │  ← if second line exists
│  Qty  [−]  1  [+]               │
│                                  │
│  Lock note: Locks at 8:00 AM    │  ← AppText.meta, inkMuted
│             tomorrow             │
│                                  │
│  ┌────────────────────────────┐  │
│  │          Save              │  │  ← primary elevated button
│  └────────────────────────────┘  │
│  ┌────────────────────────────┐  │
│  │      Skip this day         │  │  ← outlined button (danger colour border/text)
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

**Stepper row** for each subscription line:

`Row(children: [Text(lineName, style: AppText.label, flex: Expanded), Text("Qty", style: AppText.meta, color: inkMuted), IconButton(Icons.remove, onPressed: decrement, enabled: qty > 0), SizedBox(width: 32, child: Text(qty.toString(), textAlign: TextAlign.center, style: AppText.body)), IconButton(Icons.add, onPressed: increment)])`

- Minimum qty: 0 (zero = skip; the Save button can be used even with 0).
- Maximum qty: no cap (any positive integer).
- Decrement button disabled when qty == 0.
- Increment button always enabled.

**Lock note:** Shown below all stepper rows. Text determined by shift:
- Morning shift: "Locks at {morning_schedule_time} today" (formatted as 12-hr: "8:00 AM").
- Evening shift: "Locks at {evening_schedule_time} today."
- If a day has both morning and evening lines, show the relevant note per line above its stepper.
- The lock note uses `AppText.meta, color: inkMuted, style: italic` (no Dart italic — use `FontStyle.italic` via `AppText.meta.copyWith(fontStyle: FontStyle.italic)`).

**Save button:** Full-width elevated. On tap: calls `PUT /api/customer/v1/orders/{date}/qty` for each subscription line that has a changed qty. Show loading indicator on the button. On success: close sheet, refresh the day's row in the order list (invalidate the provider for that month). On HTTP 422: close sheet and show error snackbar with the API `message`.

**Skip this day button:** Outlined button with `side: BorderSide(color: AppColors.danger)` and `foregroundColor: AppColors.danger`. On tap: calls `POST /api/customer/v1/orders/{date}/skip`. On success: close sheet, update the day row to `skipped` status. On HTTP 422: close sheet, show error snackbar with the specific message from the API (`message` field).

**Interaction rules for the skip button:**
- If the API returns 422 "Cannot skip a past or current-day delivery" → snackbar with that text.
- If 422 "That day is already within your vacation hold" → snackbar.
- If 422 "Skips can only be set up to 7 days in advance" → snackbar.
- All other errors: snackbar with the API `message`.

### Navigation

- Entry: tap "Orders" tab in bottom nav.
- Month change: previous/next arrows update local state `selectedMonth`; provider fetches `GET /api/customer/v1/orders?month=YYYY-MM` for the new month.
- Day tap → opens bottom sheet (no separate screen push).
- No forward navigation from this screen.

### Interaction rules

- Default `selectedMonth` = current month on first load.
- Month navigation updates the provider watch key; the list shows a `CircularProgressIndicator` centered while the new month's data loads.
- The `locked` flag from the API response drives which rows are tappable. No client-side schedule time computation needed (API provides `locked: true|false` per subscription line entry).

### Empty / error states

- **No logs yet (all future days):** Days show `expected` status with subscription qty. Normal render.
- **API error:** Full-page error state with Retry button (replaces the list).
- **Empty month (all past days, no records):** All rows show `no_record` (dash). Normal render.

---

## Screen 7 — Vacation (CA-14)

**Route:** `/customer/vacation`
**Purpose:** View, set, or cancel the customer's active vacation hold.

This screen is **not** a shell tab. It is accessed by pushing from the Profile tab via a "Manage vacation" list row. It receives its own full `AppBar` with a back arrow (provided by the `Scaffold` since it is pushed via `context.push`).

### Layout structure

`Scaffold(appBar: AppBar(title: Text("Vacation")))` → `SingleChildScrollView(padding: EdgeInsets.all(AppSpace.lg))` → `Column(crossAxisAlignment: CrossAxisAlignment.stretch)`.

The page body has two states: **no vacation set** and **vacation active**.

### State A — No vacation set

```
┌─ AppBar ─────────────────────────────┐
│  ← Vacation                          │
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │  Plan a vacation               │  │  ← section header
│  │  Pause deliveries for a range  │  │  ← subtitle meta text
│  └────────────────────────────────┘  │
│                                      │
│  From                                │
│  ┌────────────────────────────────┐  │
│  │  Select date          📅       │  │  ← tappable field (read-only TextFormField)
│  └────────────────────────────────┘  │
│                                      │
│  Until                               │
│  ┌────────────────────────────────┐  │
│  │  Select date          📅       │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │       Set vacation             │  │  ← primary elevated button
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

**"From" and "Until" date fields:**

Each is a `GestureDetector` wrapping an `AbsorbPointer` wrapping an `AppTextField` (or equivalent read-only `TextFormField`) with:
- `readOnly: true`
- `controller`: text set to formatted date string "15 Jun 2026" when selected, or empty when not yet selected.
- `decoration`: label "From" / "Until", suffix icon `Icons.calendar_today_outlined`.
- On tap (via `GestureDetector`): opens `showDatePicker` with:
  - `firstDate`: tomorrow (`DateTime.now().add(Duration(days: 1))`).
  - `lastDate`: one year from today.
  - For "Until" field: `firstDate` = the "From" date if already selected (enforces end >= start client-side).
- Selected date is stored as local state `DateTime? _vacationStart`, `DateTime? _vacationEnd`.
- If date is selected, show the formatted date string in the field. If not yet selected, show hint "Select date".

**"Set vacation" button:** Disabled (grey) until both dates are selected. On tap: calls `POST /api/customer/v1/vacation` with `{vacation_start: "YYYY-MM-DD", vacation_end: "YYYY-MM-DD"}`.
- Loading state: button shows spinner.
- HTTP 422: show inline error text below the relevant field (or a red snackbar if the error is not field-specific). Specific 422 messages:
  - "Vacation start must be in the future." → red snackbar.
  - "Vacation end must be on or after vacation start." → error text below "Until" field.
  - "You already have an active vacation. Cancel it before setting a new one." → red snackbar.
- On success: transition page to State B (vacation active view) + show success snackbar: "Vacation set. You'll receive a WhatsApp confirmation."

### State B — Vacation active

```
┌─ AppBar ─────────────────────────────┐
│  ← Vacation                          │
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │  🏖  On vacation               │  │  ← AppCard
│  │                                │  │
│  │  15 Jun 2026 – 22 Jun 2026    │  │
│  │                                │  │
│  │  Deliveries paused during      │  │
│  │  this period.                  │  │
│  └────────────────────────────────┘  │
│                                      │
│         Cancel vacation              │  ← TextButton, danger colour
│                                      │
└──────────────────────────────────────┘
```

**Vacation active card:**

`AppCard` with `Padding(AppSpace.md)` containing a `Column`:
- `Row([Icon(Icons.beach_access_outlined, color: primary, size: 24), SizedBox(AppSpace.sm), Text("On vacation", style: AppText.cardTitle)])`.
- `SizedBox(AppSpace.sm)`.
- `Text("{start_date} – {end_date}", style: AppText.body)` — formatted as "15 Jun 2026 – 22 Jun 2026".
- `SizedBox(AppSpace.xs)`.
- `Text("Deliveries paused during this period.", style: AppText.meta, color: inkMuted)`.

**Cancel vacation button:**

`TextButton("Cancel vacation", style: TextButton.styleFrom(foregroundColor: AppColors.danger))`.

On tap: calls `DELETE /api/customer/v1/vacation`.
- Loading: show `CircularProgressIndicator` in place of the text button row.
- On success: transition page to State A + show snackbar "Vacation cancelled."
- HTTP error: show red snackbar with API `message`.

**No confirmation dialog for cancel** — the action is reversible (customer can re-set it). Keep UX lightweight.

### Navigation

- Entry: `context.push('/customer/vacation')` from Profile screen's "Manage vacation" list row.
- Back arrow returns to Profile.
- No outward navigation.

### Interaction rules

- On first load (`GET /api/customer/v1/vacation`): show `CircularProgressIndicator` in the page body while loading. Then render State A or B based on response.
- API returns `{vacation_start: null, vacation_end: null}` → State A.
- API returns dates → State B.

### Empty / error states

- **API load error:** Full-page error state with Retry button.

---

## Screen 8 — Bills (CA-15)

**Route (shell tab 2):** `/customer/bills`
**Purpose:** List of the customer's invoices with tap-to-view bill image.

### Layout structure

`Scaffold` (shell provides AppBar "Bills" + bottom nav) → `RefreshIndicator` → `ListView.builder`.

Each item in the list is a bill card. The list is ordered by `billing_month` descending (newest first, matching API sort order).

### ASCII wireframe

```
┌─ AppBar ─────────────────────────────┐
│  Bills                               │
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │  June 2026            [Unpaid] │  │  ← bill card
│  │  Total: ₹1,250                 │  │
│  │  Due:   ₹1,250                 │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  May 2026              [Paid]  │  │
│  │  Total: ₹1,150                 │  │
│  │  Due:   ₹0                     │  │
│  └────────────────────────────────┘  │
│  ...                                 │
├─ Bottom Nav ──────────────────────────┤
│  Home  Orders  Bills  Profile        │
└──────────────────────────────────────┘
```

### Key UI components

#### Bill card

`Card` (theme card style — `AppCard`) with an `InkWell` tap handler. Padding `AppSpace.md`.

`Column(crossAxisAlignment: CrossAxisAlignment.start, children: [`
- `Row([Expanded(child: Text(billingMonth, style: AppText.cardTitle)), StatusBadge(status)])`
- `SizedBox(AppSpace.xs)`
- `Row([Text("Total", style: AppText.meta, color: inkMuted, flex: 1), Text("₹{total_amount}", style: AppText.body, textAlign: right, flex: 2)])`
- `SizedBox(AppSpace.xxs)`
- `Row([Text("Due", style: AppText.meta, color: inkMuted, flex: 1), Text("₹{balance_due}", style: AppText.body.copyWith(color: balance_due > 0 ? danger : ink), textAlign: right, flex: 2)])`
`])`

Billing month formatted as "June 2026" from the `billing_month` field (e.g. "2026-06" → display "June 2026").

**Status badge:**

A small `Container` pill: `Container(padding: EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2), decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Text(label, style: AppText.meta.copyWith(color: badgeFg)))`.

| API `status` | Label | `badgeBg` | `badgeFg` |
|---|---|---|---|
| `paid` | "Paid" | `AppColors.successFaint` | `AppColors.success` |
| `partial` | "Partial" | `AppColors.warningFaint` | `AppColors.warning` |
| `unpaid` | "Unpaid" | `AppColors.dangerFaint` | `AppColors.danger` |

#### Tap action — Bill image viewer

Tapping a card pushes a new full-screen page: `context.push('/customer/bills/{id}/view')`.

The bill image viewer screen:
- **Route:** `/customer/bills/:id/view`
- **AppBar:** `AppBar(title: Text("Bill — {billingMonth}"), leading: BackButton())` — minimal, transparent background.
- **Body:** `InteractiveViewer(minScale: 0.5, maxScale: 4.0, child: Center(child: Image.network(imageUrl, ...)))`.

The viewer page fetches `GET /api/customer/v1/bills/{id}/image` on first render:

**Loading state:** `Center(child: CircularProgressIndicator())` while the URL is being fetched.

**Loaded state:** `InteractiveViewer` with pinch-to-zoom enabled, containing `Image.network(url, fit: BoxFit.contain)`.

**Error / not found (HTTP 404):** `Center(child: Column([Icon(Icons.image_not_supported_outlined, size: 64, color: inkFaint), SizedBox(AppSpace.sm), Text("Bill image not available", style: AppText.body, color: inkMuted)]))`.

**Image loading skeleton (while `Image.network` loads):** `Image.network` with a `loadingBuilder` that shows a `Shimmer` or a simpler `Center(child: CircularProgressIndicator())` while the network image streams in.

### Navigation

- Entry: "Bills" tab in bottom nav or dashboard "Bills" quick-nav card.
- Tap bill card → pushes bill image viewer screen.
- Back arrow in viewer → pops back to bill list.

### Interaction rules

- `RefreshIndicator` triggers `ref.invalidate(customerBillsProvider)`.
- Bill list loaded with `GET /api/customer/v1/bills`.

### Empty / error states

- **No bills:** `Center(child: Column([Icon(Icons.receipt_long_outlined, size: 64, color: inkFaint), SizedBox(AppSpace.sm), Text("No bills yet", style: AppText.body, color: inkMuted)]))`.
- **API error:** full-page error with Retry button.

---

## Screen 9 — Payments (CA-16)

**Route:** `/customer/payments`
**Purpose:** Read-only chronological list of all payments recorded by the farm owner.

This screen is **not** a shell tab. It is accessed by pushing from the dashboard "Payments" quick-nav card. It has its own full `AppBar` with back arrow.

### Layout structure

`Scaffold(appBar: AppBar(title: Text("Payments")))` → `RefreshIndicator` → `ListView.builder` (or `CustomScrollView` with `SliverList`).

`ListView.padding = EdgeInsets.all(AppSpace.lg)`.

### ASCII wireframe

```
┌─ AppBar ─────────────────────────────┐
│  ← Payments                          │
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │  ₹500             [Cash]      │  │  ← payment row card
│  │  5 Jun 2026                    │  │
│  │  Received for May              │  │  ← note (if present)
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  ₹1,150            [UPI]      │  │
│  │  1 Jun 2026                    │  │
│  └────────────────────────────────┘  │
│  ...                                 │
└──────────────────────────────────────┘
```

### Key UI components

#### Payment card

`AppCard` with `Padding(AppSpace.md)` containing a `Column`:

- `Row([Expanded(child: Text("₹{amount}", style: AppText.cardTitle.copyWith(color: success))), MethodBadge(method)])` — amount in `success` green, bold.
- `SizedBox(AppSpace.xs)`.
- `Text(formattedDate, style: AppText.meta, color: inkMuted)` — formatted as "5 Jun 2026".
- If `note` is non-null and non-empty: `SizedBox(AppSpace.xs)` then `Text(note, style: AppText.meta, color: inkMuted)`.

Amount formatted: "₹{amount}" with Indian number formatting (e.g. ₹1,150).

**Method badge:**

Same pill style as status badge. Mapping:

| API `method` | Label | `badgeBg` | `badgeFg` |
|---|---|---|---|
| `cash` | "Cash" | `AppColors.warningFaint` | `AppColors.warning` |
| `upi` | "UPI" | `AppColors.primaryFaint` | `AppColors.primary` |
| anything else | "Other" | `AppColors.border` | `AppColors.inkMuted` |

#### Empty state

`Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.payments_outlined, size: 64, color: inkFaint), SizedBox(AppSpace.sm), Text("No payments recorded yet", style: AppText.body, color: inkMuted)]))`.

### Navigation

- Entry: `context.push('/customer/payments')` from dashboard "Payments" card.
- No forward navigation.
- Back arrow returns to dashboard.

### Interaction rules

- `RefreshIndicator.onRefresh` calls `ref.invalidate(customerPaymentsProvider)`.
- Loaded with `GET /api/customer/v1/payments`.
- Read-only. No add/edit/delete controls rendered anywhere.

### Empty / error states

- **Empty list:** show empty state illustration (described above).
- **API error:** full-page error state with Retry.

---

## Screen 10 — Profile (CA-17)

**Route (shell tab 3):** `/customer/profile`
**Purpose:** View profile, edit name and address, toggle WhatsApp notifications, manage vacation, view subscriptions, and contact the dairy.

### Layout structure

`Scaffold` (shell provides AppBar "Profile" + bottom nav) → `ListView(padding: EdgeInsets.all(AppSpace.lg))` containing sections stacked vertically with `SizedBox(height: AppSpace.lg)` between them.

### ASCII wireframe

```
┌─ AppBar ─────────────────────────────┐
│  Profile                             │
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │   [AB]  Arjun Bhatt            │  │  ← avatar + name row
│  │         9876543210             │  │  ← mobile (muted, no edit)
│  │                                │  │
│  │  [    Edit profile    ]        │  │  ← outlined button
│  └────────────────────────────────┘  │
│                                      │
│  Notifications                       │  ← section header
│  ┌────────────────────────────────┐  │
│  │  Delivery notifications   ○●   │  │  ← SwitchListTile
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  Manage vacation           ›   │  │  ← ListTile → push vacation screen
│  └────────────────────────────────┘  │
│                                      │
│  Subscriptions                       │  ← section header
│  ┌────────────────────────────────┐  │
│  │  Full Cream Milk · Morning · 1L│  │
│  │  Curd · Evening · 500ml        │  │
│  └────────────────────────────────┘  │
│                                      │
│  Your dairy                          │  ← section header
│  ┌────────────────────────────────┐  │
│  │  Shreeji Gir Gaushala          │  │
│  │  Rajan Sharma                  │  │
│  │                                │  │
│  │  [  📞 Call  ]  [ 💬 WhatsApp ]│  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### Key UI components

#### Profile header card

`AppCard(child: Padding(AppSpace.md, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...])))`:

1. Avatar + name + mobile row: `Row([CircleAvatar(radius: 24, backgroundColor: primaryFaint, child: Text(initials, style: AppText.cardTitle.copyWith(color: primary))), SizedBox(AppSpace.sm), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(fullName, style: AppText.cardTitle), Text(mobile, style: AppText.meta, color: inkMuted)])])`.
   - Initials: first character of `first_name` + first character of `last_name` (uppercase), e.g. "AB".
2. `SizedBox(AppSpace.md)`.
3. `OutlinedButton(onPressed: _openEditSheet, child: Text("Edit profile"))` — full width.

#### WhatsApp notifications

Section header: `Text("Notifications", style: AppText.sectionTitle)` + `SizedBox(AppSpace.sm)`.

`AppCard(child: SwitchListTile(contentPadding: EdgeInsets.zero, title: Text("Delivery notifications", style: AppText.body), value: whatsappEnabled, onChanged: _onWhatsAppToggle))`.

Toggle behaviour:
- Optimistic update: flip local state immediately, then call `PUT /api/customer/v1/profile` with `{whatsapp_enabled: newValue}`.
- On API error: revert local state to original + show error snackbar.
- No loading indicator on the switch row itself (optimistic is the UX pattern for toggles — matches owner app's `SwitchListTile` pattern).

#### Manage vacation row

`AppCard(child: ListTile(contentPadding: EdgeInsets.zero, title: Text("Manage vacation", style: AppText.body), trailing: Icon(Icons.chevron_right, color: inkMuted), onTap: () => context.push('/customer/vacation')))`.

No section header needed — the row is self-explanatory and follows immediately after the notifications card with `SizedBox(AppSpace.sm)` separation.

#### Subscriptions section

`Text("Subscriptions", style: AppText.sectionTitle)` + `SizedBox(AppSpace.sm)`.

`AppCard(child: Column([...]))` where `[...]` = `ListTile` per active subscription line.
- Each `ListTile`: `title: Text("{product_name}", style: AppText.label)`, `subtitle: Text("{shift} · {qty}", style: AppText.meta, color: inkMuted)`. No trailing, no `onTap`. `contentPadding: EdgeInsets.zero`.
- Empty state: single `ListTile(title: Text("No active subscriptions", style: AppText.body, color: inkMuted))`.

The subscriptions list is read-only here. No edit or action controls.

#### Dairy contact card

`Text("Your dairy", style: AppText.sectionTitle)` + `SizedBox(AppSpace.sm)`.

`AppCard(child: Padding(AppSpace.md, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...])))`:

1. `Text(farmName, style: AppText.cardTitle)`.
2. `SizedBox(AppSpace.xs)`.
3. `Text(ownerFullName, style: AppText.body, color: inkMuted)`.
4. `SizedBox(AppSpace.md)`.
5. `Row([Expanded(child: OutlinedButton.icon(icon: Icon(Icons.phone_outlined), label: Text("Call"), onPressed: _call)), SizedBox(AppSpace.sm), Expanded(child: OutlinedButton.icon(icon: Icon(Icons.chat_outlined), label: Text("WhatsApp"), onPressed: _whatsapp))])`.

**Call button action:** `launchUrl(Uri.parse('tel:${ownerMobile}'))` using `url_launcher` package (already in pubspec).

**WhatsApp button action:** `launchUrl(Uri.parse('https://wa.me/91${ownerMobileStripped}'))` where `ownerMobileStripped` removes any leading `0` or country code prefix if present.

Both buttons use `OutlinedButton.icon` with default styling (ink text, border colour). Equal width via `Expanded`.

### Edit profile bottom sheet

Triggered by tapping "Edit profile" button. Opens with `showModalBottomSheet(isScrollControlled: true, ...)`.

**Sheet header:** `OwnerSheetTitle` style — `Text("Edit profile", style: AppText.sectionTitle)` (or use the same sheet title widget the owner app uses). Drag handle is provided by the theme.

**Form fields in the sheet:**

```
┌──────────────────────────────────┐
│  ≡  (drag handle)               │
│  Edit profile                   │
│                                  │
│  First name   [Last name        ]│  ← side-by-side (2 cols)
│                                  │
│  Address line                    │
│  [                              ]│
│                                  │
│  Area                            │
│  [                              ]│
│                                  │
│  Landmark (optional)             │
│  [                              ]│
│                                  │
│  Pincode  [City         ][State ]│  ← 3-col row (flex 2/3/3)
│                                  │
│  ℹ Address can only be updated   │
│    once every 24 hours           │  ← hint text (meta, inkMuted)
│                                  │
│  [          Save           ]     │
└──────────────────────────────────┘
```

**Fields:**

| Field | `AppTextField` label | Rules |
|---|---|---|
| First name | "First name" | Required (show "Enter first name" if empty on save) |
| Last name | "Last name" | Optional |
| Address line | "Address" | Optional |
| Area | "Area" | Optional |
| Landmark | "Landmark (optional)" | Optional |
| Pincode (zip) | "PIN code" | Numeric, max 6 digits. Auto-lookup city/state on 6-digit entry (same pincode-lookup UX as owner settings) |
| City | "City" | Read-only while pincode lookup is in progress |
| State | "State" | Read-only while pincode lookup is in progress |

Mobile number (`contact`) is NOT included in the edit form. It is not rendered here.

Pincode auto-lookup: mirrors the `_FarmEditSheet` pattern exactly — on 6-digit input, call `GET /api/customer/v1/profile/pincode/{zip}` or the owner's existing pincode endpoint (to be confirmed with Laravel Engineer — use whatever pincode endpoint is available). Show a 14×14 `CircularProgressIndicator` as the field suffix. On error, show `Text("Pincode not found", style: AppText.meta, color: danger)` below the row.

**Address change hint:** `Row([Icon(Icons.info_outline, size: 14, color: inkMuted), SizedBox(4), Expanded(child: Text("Address can only be updated once every 24 hours.", style: AppText.meta, color: inkMuted))])` — shown below the address fields group, above the Save button.

**Save button:** Full-width elevated. Loading state on tap.

On `PUT /api/customer/v1/profile`:
- HTTP 422 "Address can only be updated once every 24 hours." → show a red snackbar with this message. Do not close the sheet. All other field values remain intact.
- Any other HTTP 422 with `errors` object → show inline `errorText` on the relevant field.
- On success → close sheet + show snackbar "Profile updated." + refresh `customerProfileProvider`.

### Navigation

- Entry: "Profile" tab in bottom nav.
- "Edit profile" → opens bottom sheet (no push).
- "Manage vacation" row → `context.push('/customer/vacation')`.
- "Call" button → `launchUrl(tel:...)`.
- "WhatsApp" button → `launchUrl(https://wa.me/...)`.

### Interaction rules

- On first load (`GET /api/customer/v1/profile` + `GET /api/customer/v1/farm-contact`): both are driven by the same provider or two separate providers; show `CircularProgressIndicator` centred in the page body while loading.
- WhatsApp toggle uses optimistic update (no loading indicator).
- Edit sheet is dismissed on success only; user can also dismiss by dragging down.

### Empty / error states

- **API load error:** full-page error with Retry.
- **Farm contact not available:** dairy contact card shows `Text("Contact not available", style: AppText.body, color: inkMuted)` in place of the card content. Call / WhatsApp buttons are not rendered.

---

## Appendix A — Route table

| Route | Screen | Shell tab? | Story |
|---|---|---|---|
| `/customer/login` | Customer Login | No | CA-11 |
| `/customer/otp` | Send OTP | No | CA-11 |
| `/customer/otp/verify` | Verify OTP | No | CA-11 |
| `/customer/set-pin` | Set PIN | No | CA-11 |
| `/customer/home` | Dashboard | Yes — tab 0 | CA-12 |
| `/customer/orders` | Order Log | Yes — tab 1 | CA-13 |
| `/customer/bills` | Bills list | Yes — tab 2 | CA-15 |
| `/customer/bills/:id/view` | Bill image viewer | No (pushed) | CA-15 |
| `/customer/profile` | Profile | Yes — tab 3 | CA-17 |
| `/customer/payments` | Payments list | No (pushed) | CA-16 |
| `/customer/vacation` | Vacation | No (pushed) | CA-14 |

The go_router `ShellRoute` (or `StatefulShellRoute`) wraps tabs 0–3. The remaining routes (`/bills/:id/view`, `/payments`, `/vacation`) are pushed outside the shell.

---

## Appendix B — Provider naming conventions

| Provider | Type | Data source |
|---|---|---|
| `customerDashboardProvider` | `FutureProvider` | `GET /api/customer/v1/dashboard` |
| `customerOrdersProvider(month)` | `FutureProvider.family<..., String>` | `GET /api/customer/v1/orders?month={YYYY-MM}` |
| `customerBillsProvider` | `FutureProvider` | `GET /api/customer/v1/bills` |
| `customerPaymentsProvider` | `FutureProvider` | `GET /api/customer/v1/payments` |
| `customerProfileProvider` | `FutureProvider` | `GET /api/customer/v1/profile` + `GET /api/customer/v1/farm-contact` |
| `customerVacationProvider` | `FutureProvider` | `GET /api/customer/v1/vacation` |
| `customerAuthProvider` | `StateNotifierProvider` | Token read from secure storage |

All providers live in `lib/features/customer/presentation/providers/`. Do not share state with the owner's providers.

---

## Appendix C — Interaction patterns summary

| Pattern | Behaviour |
|---|---|
| Toggle (WhatsApp notifications) | Optimistic: flip local state immediately, API call in background; revert + snackbar on error |
| Save (forms) | Show loading on button, keep form open on 422, close + snackbar on success |
| Delete / cancel (vacation) | No confirmation dialog — action is reversible; loading on button |
| Pull-to-refresh | `RefreshIndicator` calls `ref.invalidate(provider)` |
| Error recovery | `TextButton("Retry")` centred in page body |
| Snackbar — success | Default (no colour override) |
| Snackbar — error | `backgroundColor: AppColors.danger` |
| Bottom sheet | `showModalBottomSheet(isScrollControlled: true)`, padding includes `MediaQuery.viewInsetsOf(context).bottom` |
| Loading state in page | `Center(child: CircularProgressIndicator())` |
| Loading state in button | Replace button label with `SizedBox(18, 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))` |
