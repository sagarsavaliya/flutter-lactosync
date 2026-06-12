# UX Spec — Admin Auth (T1-02)

> Author: UX/UI Designer · Story: T1-02 · Date: 2026-06-05
> Consumed by: React Engineer (T1-13)
> Against: `briefs/requirements/tenant-admin-webapp.md` FR-01–FR-06

---

## 1. Screen inventory

| ID | Screen | Route |
|----|--------|-------|
| A-01 | Login page | `/login` |
| A-02 | Lockout state (overlay on A-01) | `/login` (same page, disabled state) |

---

## 2. Login page (A-01)

### 2.1 Page-level layout

- **Background:** full-viewport gradient `bg-gradient-to-br from-green-900 to-green-700` (`#14532d` → `#166534`)
- **Center card:** `Card` from shadcn/ui — `w-[420px]`, `p-8`, `shadow-2xl`, `rounded-2xl`, white background (`bg-white`)
- Card is vertically and horizontally centered: `flex items-center justify-center min-h-screen`
- No topbar. No sidebar. Auth sits outside the shell layout.

### 2.2 Card content — top to bottom

#### Logo block
- LactoSync wordmark SVG (`<img src="/logo.svg" alt="LactoSync" className="h-10 mx-auto mb-1" />`)
- Subtitle: `<p className="text-center text-sm text-gray-500 mb-6">Admin Portal</p>`

#### Email field
- Label: `<Label htmlFor="email">Email</Label>` — `text-sm font-medium text-gray-700`
- shadcn `Input` — `type="email"`, `id="email"`, `placeholder="admin@aksharatech.com"`, `autoComplete="email"`, `autoFocus`, full-width (`w-full`)
- Bottom margin: `mb-4`

#### PIN label
- `<Label>6-digit PIN</Label>` — `text-sm font-medium text-gray-700 mb-2 block`

#### PIN input row
- `<div className="flex gap-2 justify-between mb-4">`
- 6 × shadcn `Input`:
  - `type="number"` (or `type="text" inputMode="numeric"` to avoid spinner arrows)
  - `maxLength={1}`
  - `className="w-10 h-12 text-center text-xl font-semibold rounded-md border border-gray-300 focus:border-green-600 focus:ring-1 focus:ring-green-600 [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none"`
  - Ref array for programmatic focus control
  - `onInput`: if character entered, focus next box; if box full and next exists, move forward
  - `onKeyDown`: on Backspace with empty value, focus previous box
  - `aria-label={`PIN digit ${i + 1}`}`

#### Sign In button
- shadcn `Button` — `variant="default"`, `className="w-full bg-green-700 hover:bg-green-800 text-white h-11 text-base font-semibold mt-2"`, `type="submit"`
- Label: "Sign In"
- Loading state: `disabled` + spinner icon (`Loader2` lucide, `animate-spin`, inline left of text "Signing in…")

#### Error alert (conditional)
- Rendered below the button when an error exists
- shadcn `Alert` — `variant="destructive"`, `className="mt-4"`
- `AlertCircle` lucide icon in `AlertTitle`
- **Exact error copy:**
  - Invalid credentials: `AlertTitle` = "Invalid credentials" · `AlertDescription` = "The email or PIN you entered is incorrect. Please try again."
  - Account locked: `AlertTitle` = "Account locked" · `AlertDescription` = "Too many failed attempts. Please wait before trying again." (lockout countdown shown separately — see A-02)
  - Network / server error: `AlertTitle` = "Something went wrong" · `AlertDescription` = "Could not reach the server. Check your connection and try again."

### 2.3 Form behaviour

- `onSubmit` prevents default, validates both fields non-empty, sends `POST /api/admin/v1/auth/login` with `{ email, pin }`
- PIN value assembled from the 6 individual box values before submit
- On 401 response: show "Invalid credentials" alert; clear PIN boxes; refocus box 1
- On 423 / lockout flag: transition to lockout state A-02
- On 200: store token, navigate to `/dashboard`

---

## 3. Lockout state (A-02)

Lockout is the same card — email and PIN inputs plus button are disabled, not hidden.

### 3.1 Disabled PIN row
- All 6 `Input` boxes: `disabled` prop — `opacity-50 cursor-not-allowed` (via shadcn disabled styles)
- Email `Input`: `disabled`
- "Sign In" `Button`: `disabled`

### 3.2 Lockout alert
- Replaces the error alert (same position, below button)
- shadcn `Alert` — **amber variant**: `className="mt-4 border-amber-400 bg-amber-50 text-amber-800"`
- `AlertTitle`: "Too many attempts"
- `AlertDescription`: `"Try again in "` + live countdown `MM:SS` (bold, monospace: `<span className="font-mono font-semibold">`) 
- Countdown ticks from 15:00 down to 00:00; when it reaches zero, re-enable all inputs and clear the alert

### 3.3 Countdown logic
- Server response body includes `locked_until` ISO timestamp (or `retry_after_seconds: 900`)
- React calculates remaining seconds on each tick via `setInterval(1000)`
- When remaining ≤ 0: clear interval, remove lockout state, refocus email input

### 3.4 Attempt counter (client-side UX)
- After each failed attempt (attempts 1–4): no lockout, just error alert
- The server is authoritative on lockout; the client does not independently lock
- FR-06 specifies exactly 5 attempts → lockout

---

## 4. Navigation flow

```
/login (A-01)
  │
  ├── submit valid credentials ──▶ /dashboard
  │
  ├── submit invalid credentials ──▶ stay on /login, show error alert
  │
  └── 5th failed attempt ──▶ stay on /login, show lockout alert (A-02)
                                  │
                                  └── 15-minute countdown expires ──▶ re-enable inputs
```

Any authenticated route accessed without a token redirects back to `/login`.

---

## 5. Design tokens

| Token | Tailwind class | Usage |
|-------|---------------|-------|
| Brand green | `green-700` / `green-800` | Button background / hover |
| Page gradient start | `green-900` | Background gradient from |
| Page gradient end | `green-700` | Background gradient to |
| Error red | `red-600` / destructive variant | Error alert |
| Lockout amber | `amber-400 / amber-50 / amber-800` | Lockout alert border/bg/text |
| Focus ring | `ring-green-600` | PIN box + email field focus |
| Card bg | `white` | Login card |
| Label text | `gray-700` | All form labels |
| Subtitle text | `gray-500` | "Admin Portal" subtitle |

---

## 6. Accessibility

- `aria-live="polite"` on the error/lockout alert container so screen readers announce changes
- PIN boxes have `aria-label="PIN digit N"` and are grouped under `role="group" aria-labelledby="pin-label"`
- Tab order: email → PIN box 1 → … → PIN box 6 → Sign In button
- Lockout countdown announced on each minute change via `aria-live="polite"`
