# Code Review — T1-19: Tenant Admin Web App
**Reviewer:** Code Reviewer & Security
**Date:** 2026-06-06
**Scope:** All new Laravel backend and React frontend code for the Tenant Admin Web App

---

## Executive Summary

**Verdict: Fix critical issues first — do not deploy as-is.**

One critical issue blocks deploy: the admin PIN is stored in plain text inside `briefs/STATUS.md`, which is committed to the git repository. This is a credential leak that must be addressed before any deployment.

All other focus areas pass review. Guard isolation is correctly implemented and tight. No SQL injection vectors exist. No XSS risk in the React SPA. No secrets in source code (outside the STATUS.md finding). The bcrypt PIN handling in the migration, model, seeder, and controller is all correct. The soft-delete audit pattern in PaymentController is correctly ordered. The rate-limiting gap is real but architectural by design (explained below under High).

---

## CRITICAL

### C-01 — Plain-text admin PIN in `briefs/STATUS.md`

**File:** `briefs/STATUS.md`, line 121
**Line content:** `| Auth | Single super-admin: savaliya.sagar@aksharatech.com + 6-digit PIN \`159874\` |`

The STATUS.md file is tracked by git and appears to be committed to the repository. The admin PIN `159874` is stored in plain text alongside the email address, forming a complete credential set that anyone with repository access can use immediately.

**Impact:** Full admin panel compromise for anyone with git clone or read access to the repository. This is compounded by the fact that the seeder (`AdminUserSeeder.php`) also uses this PIN — making it the live credential, not just documentation.

**Recommendation:**
1. Remove the PIN from STATUS.md immediately. Replace with: `Auth | Single super-admin: savaliya.sagar@aksharatech.com + 6-digit PIN (stored in password manager only — never in files)`.
2. After the fix, rotate the PIN: update the seeder with a new PIN, re-run the seeder against the database, and update the password manager entry.
3. Use `git filter-branch` or BFG Repo-Cleaner to scrub the PIN from git history if this repository has any remote audience beyond the developer (CI, VPS deploy keys, etc.).

---

## HIGH

### H-01 — No server-side rate limit on the admin login route

**File:** `lactosync/src/routes/api.php`, line 23 (the `admin/v1` route group)

The owner auth routes use explicit `throttle:3,60` and `throttle:5,1` middleware. The admin login route (`POST admin/v1/auth/login`) has no `throttle:` middleware applied at the route level. The account-level lockout in `AdminUser::recordFailedAttempt()` (5 attempts → 15 min lock) is the only brute-force mitigation, and it operates per-account not per-IP.

**Impact:** An attacker who enumerates a valid admin email can attempt 5 PINs every 15 minutes indefinitely from different IPs (since the lock is per-account, not per-IP). A 6-digit PIN space is only 1,000,000 combinations; without IP-level throttling, automated low-rate guessing across rotated IPs is feasible over days.

**Note:** The account-level lockout is correctly implemented server-side (not UI-only), and the UI lockout is driven by the server's `retry_after` value. The gap is purely the absence of IP-level rate limiting.

**Recommendation:** Add `->middleware('throttle:10,1')` to the admin login route (or tighter: `throttle:5,5` for 5 attempts per 5 minutes per IP). Example:
```php
Route::post('auth/login', [AdminAuthController::class, 'login'])
    ->middleware('throttle:10,1');
```

### H-02 — `computeTotalOutstanding()` in PaymentController has an N+1 query

**File:** `lactosync/src/app/Http/Controllers/Api/Admin/V1/PaymentController.php`, lines 296–321

The `computeTotalOutstanding()` private method loads all active `TenantPlanAssignment` rows with eager-loaded `subscriptionPlan`, then fires one `SaasPayment::where(...)->sum()` query **per assignment** inside a `foreach` loop. With N active tenants this issues N+1 queries.

This method is called from `index()` (the global payments list, line 143) — a potentially frequent endpoint.

**Note:** The same pattern also exists in the `DashboardController`'s `buildKpis()` but there the equivalent logic is done as two aggregate queries without a loop (lines 78–82), which is correct. The problem is isolated to `PaymentController::computeTotalOutstanding()`.

**Recommendation:** Replace the per-assignment loop with a single grouped aggregate:
```php
// Get all active owner IDs and their paid amounts in one query
$ownerIds = TenantPlanAssignment::whereIn('status', ['active', 'grace_period', 'suspended'])
    ->pluck('owner_id');

$paid = SaasPayment::whereIn('owner_id', $ownerIds)
    ->groupBy('owner_id')
    ->selectRaw('owner_id, SUM(amount) as total')
    ->pluck('total', 'owner_id');

// Then sum (planPrice - paid) per assignment in PHP
```

### H-03 — Token stored in Zustand in-memory only — survives page navigation but not page refresh

**File:** `admin-web/src/stores/authStore.ts`, lines 12–40

The Zustand store holds the token in plain JS memory with no persistence middleware (`zustand/middleware` `persist`). This means a page refresh logs the admin out silently. The ProtectedRoute in `router/index.tsx` then redirects to `/login` immediately.

**Clarity note:** This is not a security vulnerability — in-memory storage is actually safer than localStorage (immune to XSS token theft). However, it creates a poor and potentially confusing UX where the admin loses their session on any refresh or browser restart.

**Recommendation:** This is a UX decision with a security trade-off:
- If session persistence across refresh is required: use `sessionStorage` (persists within tab, cleared on tab close) via `zustand/middleware persist` with `storage: sessionStorage`. Do **not** use `localStorage` — tokens in localStorage are readable by any JS on the page.
- If in-memory is intentional (highest security): document it as a design decision in `briefs/DECISIONS.md` so future engineers do not add persistence without understanding the trade-off.

---

## MEDIUM

### M-01 — `UpdatePlanRequest` uses `PUT` semantics in the route but `sometimes` (PATCH) semantics in validation

**File:** `lactosync/src/app/Http/Requests/Admin/UpdatePlanRequest.php`, line 28; `lactosync/src/routes/api.php`, line 43

The route is declared as `Route::put(...)` but the `UpdatePlanRequest` uses `sometimes` on all fields, meaning a PUT with missing fields will silently leave old values in place rather than returning a 422. A caller following REST semantics would expect a full-replacement PUT to return an error if required fields are omitted.

**Impact:** No security impact; the behavior is more permissive than REST contracts imply, which could confuse API consumers.

**Recommendation:** Either change the route to `Route::patch(...)` to match the partial-update semantics, or require all fields in the request rules and remove `sometimes`. The current code comment acknowledges this inconsistency ("PATCH semantics on a PUT endpoint") but does not resolve it.

### M-02 — `show()` in TenantController calls `buildTenantDetail()` which issues multiple additional queries per call

**File:** `lactosync/src/app/Http/Controllers/Api/Admin/V1/TenantController.php`, lines 148–159 and 481–573

`buildTenantDetail()` is called from `show()` and from every plan-action endpoint. It internally calls:
- `TenantPlanAssignment::with('subscriptionPlan')->where(...)->first()` (line 482)
- `Farm::find(...)` (line 486)
- `Customer::where(...)->count()` (line 489)
- `Subscription::where(...)->count()` (line 490)
- `SaasPayment::where(...)->orderByDesc(...)->get()` (line 493)
- `TenantPlanAssignment::with(...)->where(...)->first()` again inside `computeOutstandingBalance()` (line 590)

The assignment is loaded **twice** — once at line 482 and again inside `computeOutstandingBalance()` at line 590. The second load is redundant.

**Impact:** Medium — doubles one query on every detail fetch, but only affects single-tenant detail pages, not list views.

**Recommendation:** Pass the already-loaded `$assignment` into `computeOutstandingBalance()` as a parameter rather than re-querying it internally.

### M-03 — `FarmOwner::find($id)` in TenantController (index/show/planAssign/planChange/planPause/planResume) — inconsistent null handling

**File:** `lactosync/src/app/Http/Controllers/Api/Admin/V1/TenantController.php`, lines 150, 177, 257, 340, 411

`show()`, `planAssign()`, `planChange()`, `planPause()`, and `planResume()` all use `FarmOwner::find($id)` and check `$owner === null`. This is consistent and correct.

However, `PaymentController::store()` and `indexForTenant()` use `FarmOwner::findOrFail($id)` (lines 31, 86) which throws a `ModelNotFoundException` — handled correctly by Laravel's JSON exception renderer configured in `bootstrap/app.php`.

The inconsistency is not a bug (both produce 404 responses), but the two controllers handle the same scenario differently. `findOrFail` is cleaner and removes the explicit null check.

**Recommendation:** Standardise on `findOrFail` in TenantController to reduce boilerplate and remove the `notFound()` helper, or standardise on `find` + manual check everywhere. Either is fine; pick one.

### M-04 — Admin login route does not validate that `pin` contains only digits

**File:** `lactosync/src/app/Http/Controllers/Api/Admin/V1/AuthController.php`, line 33

The validation rule for `pin` is `['required', 'string', 'size:6']`. A PIN of `abc123` or `!@#$%^` passes validation and is passed to `Hash::check()`. `Hash::check()` will simply return `false` for a non-numeric PIN, so there is no security hole, but accepting non-digit input is unnecessarily permissive and wastes a bcrypt round-trip.

**Recommendation:** Add `regex:/^\d{6}$/` to the PIN validation rule:
```php
'pin' => ['required', 'string', 'size:6', 'regex:/^\d{6}$/'],
```

### M-05 — `billing_cycle` not validated when `is_archived` toggling but also — `is_archived` itself is in `$fillable` on `SubscriptionPlan`

**File:** `lactosync/src/app\Models\Admin\SubscriptionPlan.php`, line 26

`is_archived` is in `$fillable`. While the PlanController correctly uses dedicated `archive()` and `unarchive()` endpoints and the `UpdatePlanRequest` does not include `is_archived` in its rules, a caller could pass `is_archived: true` directly in the plan update payload. The `UpdatePlanRequest` uses `sometimes`, so an explicit `is_archived` field in the request body would be silently ignored by validation... but `$plan->update($validated)` only writes validated fields (from `$request->validated()`), so the risk is mitigated by the FormRequest.

**Verdict:** Not actually exploitable given the FormRequest flow — confirmed safe. Flagged only for awareness that `$fillable` is broader than the FormRequest allows.

### M-06 — `LoginPage.tsx` reads `data.token` but the server returns `data.data.token`

**File:** `admin-web/src/pages/LoginPage.tsx`, line 110; `lactosync/src/app/Http/Controllers/Api/Admin/V1/AuthController.php`, line 92

The server response shape is:
```json
{ "success": true, "data": { "token": "...", "email": "...", "name": "..." } }
```

The React login handler reads:
```js
setAuth(data.token, data.admin?.email || email)
```

`data.token` is `undefined` (the token lives at `data.data.token`). `data.admin?.email` is also `undefined` (it's at `data.data.email`). The result is that `setAuth(undefined, email)` is called, the store sets `token: undefined`, and the ProtectedRoute immediately redirects back to `/login` after the 200 response — the admin cannot log in.

This is a **functional regression** (login is broken end-to-end) even though it is not a security issue.

**Recommendation:** Fix the destructuring in `LoginPage.tsx`:
```js
const { data: payload } = res
setAuth(payload.data.token, payload.data.email || email)
```

---

## LOW

### L-01 — `deleted_by` is populated before soft-delete — correct, but not atomic

**File:** `lactosync/src/app/Http/Controllers/Api/Admin/V1/PaymentController.php`, lines 193–199

The `destroy()` method correctly sets `deleted_by` before calling `$payment->delete()` (FR-27 requirement is met). However, the two operations are not wrapped in a `DB::transaction()`. If the process dies between `$payment->save()` and `$payment->delete()` the row has `deleted_by` set but is not soft-deleted.

**Impact:** Low — this is a partial-write edge case that requires a crash at a specific nanosecond. The audit trail would show a `deleted_by` value on a non-deleted row, which is misleading but not a security risk.

**Recommendation:** Wrap both operations in a transaction:
```php
DB::transaction(function () use ($request, $payment) {
    $payment->deleted_by = $request->user()->id;
    $payment->save();
    $payment->delete();
});
```

### L-02 — `UpdateSubscriptionStatuses` command mutates `$assignment->due_date` in Pass 1

**File:** `lactosync/src/app/Console/Commands/UpdateSubscriptionStatuses.php`, line 39

In Pass 1, `grace_expires_at` is set to `$assignment->due_date->addDays(5)`. Carbon's `addDays()` mutates the Carbon instance in place. If `due_date` is a Carbon cast (it is, per `TenantPlanAssignment`'s casts), then `$assignment->due_date` itself is modified to `due_date + 5 days` as a side effect. The `update()` call only writes the two specified fields (`status` and `grace_expires_at`), so `due_date` in the database is not corrupted — but the in-memory model is wrong for any subsequent read within the same loop iteration.

In this specific loop there are no subsequent reads of `due_date` after the update, so the mutation is harmless now. But it is a latent bug if the loop body is ever extended.

**Recommendation:** Use `$assignment->due_date->copy()->addDays(5)` to avoid mutating the original Carbon instance:
```php
'grace_expires_at' => $assignment->due_date->copy()->addDays(5),
```

### L-03 — `CheckTenantSubscription` middleware path-matching for plan limits is fragile

**File:** `lactosync/src/app/Http/Middleware/CheckTenantSubscription.php`, lines 141–149

`isCreateCustomerRequest()` matches any POST whose path contains the string `"customers"`. This would also match, for example, `POST /owner/customers/{id}/milk-log/send` (which contains `"customers"` but is not a customer-create). Currently no such route exists that would falsely trigger a limit check, but the matching strategy is brittle.

**Impact:** No current false positive — the route map was verified. Flagged as a maintenance risk if new routes are added under the `/customers/` prefix.

**Recommendation:** Match on exact path patterns instead:
```php
return $request->isMethod('POST')
    && preg_match('#^api/v1/owner/customers$#', $request->path());
```

### L-04 — Token expiry is `null` in Sanctum config

**File:** `lactosync/src/config/sanctum.php`, line 53 — `'expiration' => null`

Admin tokens never expire. If an admin token is leaked (e.g., in browser history, logs, or a compromised machine) it remains valid indefinitely until explicitly revoked.

**Impact:** Low — the logout route correctly revokes the token server-side. The risk is only when logout is not called (closed tab, crashed browser).

**Recommendation:** Set a reasonable expiry (e.g., 8 hours = 480 minutes) for the admin session:
```php
'expiration' => env('SANCTUM_TOKEN_EXPIRY_MINUTES', 480),
```
Note: this is a global setting and would also affect farm-owner tokens. A targeted fix is to pass an `expiration` to `createToken()` in `AuthController`:
```php
$token = $admin->createToken('admin-session', ['admin'], now()->addHours(8))->plainTextToken;
```
(Laravel Sanctum 3.x supports per-token expiry in `createToken`.)

### L-05 — `billing_cycle` change is not logged in plan_change_log when a plan is updated

**File:** `lactosync/src/app/Http/Controllers/Api/Admin/V1/PlanController.php`, `update()` method (lines 94–125)

When `PlanController::update()` changes `billing_cycle`, the change is silently applied with no audit trail entry in `plan_change_log`. The `TenantController` action endpoints all append to `plan_change_log` for plan transitions, but direct plan edits do not.

**Impact:** Low — audit gap, not a security issue.

**Recommendation:** After a successful `$plan->update($validated)`, if `billing_cycle` changed, append an entry to the change log via a dedicated mechanism or at minimum log the change to the application log.

---

## Confirmed Clean

The following items were explicitly reviewed and confirmed to have no issues:

| Item | File(s) | Verdict |
| ---- | ------- | ------- |
| PIN stored as plain text in migration | `create_admin_users_table.php` | Clean — column is `pin_hash`, no plain PIN in schema |
| PIN stored as plain text in seeder | `AdminUserSeeder.php` | Clean — `Hash::make()` used; no raw PIN in file |
| PIN returned in API response | `AdminUser.php`, `AuthController.php` | Clean — `pin_hash` in `$hidden`; login response contains only token + email + name |
| Admin guard isolation (farm-owner token crossing to admin routes) | `config/auth.php`, `routes/api.php`, `sanctum.php` | Clean — `auth:admin` uses `admin_users` provider; `auth:sanctum` uses `farm_owners` provider; the two providers are distinct; a farm-owner token cannot authenticate via `auth:admin` |
| SQL injection via raw queries | All Admin controllers | Clean — `DB::raw()` used only for aggregates with no user input interpolated; all user-supplied filter values go through parameterised Eloquent builder calls |
| CSRF on admin API routes | `bootstrap/app.php`, `sanctum.php` | Clean — admin routes use stateless Bearer token auth, not session cookies; CSRF middleware is not applicable and correctly absent; no SPA cookie-session hybrid for admin |
| `deleted_by` populated before soft-delete | `PaymentController.php` lines 193–199 | Clean — ordering is correct (FR-27 satisfied); flagged only as missing transaction wrapper (L-01) |
| XSS via `dangerouslySetInnerHTML` | All React source files under `admin-web/src/` | Clean — no `dangerouslySetInnerHTML` usage found anywhere |
| Hardcoded secrets / API keys in source | All Admin controllers, React source | Clean — no hardcoded secrets found; all external config comes from `env()` or `import.meta.env` |
| Rate limiter server-side vs UI-only | `AdminUser.php`, `AuthController.php`, `LoginPage.tsx` | Clean — lockout is enforced in the database (failed_attempts + locked_until); UI lockout is cosmetic and driven by the server's `retry_after` value; IP-level throttle is the gap (H-01) |
| `auth()->id()` in admin context | All Admin V1 controllers | Clean — all controllers call `$request->user()->id` (not `auth()->id()`) after `auth:admin` middleware; the authenticated user is always an `AdminUser` instance in these routes |
| N+1 queries in DashboardController | `DashboardController.php` | Clean — `buildTenantRows()` uses a single eager-load + three pre-aggregated keyed queries; no N+1 in the foreach loop |
| Validation completeness — plans | `StorePlanRequest.php`, `UpdatePlanRequest.php` | Clean — all required fields validated; enum whitelist on `billing_cycle`; uniqueness check ignores current row on update |
| Validation completeness — payments | `PaymentController.php` store/update | Clean — all fields validated; `payment_method` uses Rule::in whitelist |
| Error message leakage | All Admin V1 controllers | Clean — all error responses use opaque error codes; no stack traces, table names, or SQL errors exposed; `shouldRenderJsonWhen` in `bootstrap/app.php` routes framework exceptions to JSON |
| 404 handling for non-existent IDs | TenantController, PaymentController | Clean — TenantController has explicit null checks with `notFound()` helper; PaymentController uses `findOrFail` for payment IDs (see M-03 for mild inconsistency, not a bug) |
| ProtectedRoute guard in React | `router/index.tsx` | Clean — all authenticated pages wrapped in `ProtectedRoute`; unauthenticated users redirected to `/login` |
| Plan-limit enforcement — server-side | `CheckTenantSubscription.php` | Clean — limits enforced server-side in middleware on all POST/PUT/PATCH owner requests; not UI-only |
| Soft-delete excludes deleted payments from balance calculations | `SaasPayment.php`, `PaymentController.php` | Clean — `SoftDeletes` trait active; default query scope excludes soft-deleted rows; `withTrashed()` never called in balance calculations |
| `UpdateSubscriptionStatuses` — grace/suspend transitions | `UpdateSubscriptionStatuses.php` | Clean — two-pass logic is correct; passes are independent so a tenant going active→grace on the same day grace→suspended would correctly require two runs; scheduler runs daily at 00:05 |
