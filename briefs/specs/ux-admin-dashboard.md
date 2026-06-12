# UX Spec — Admin Dashboard (T1-03)

> Author: UX/UI Designer · Story: T1-03 · Date: 2026-06-05
> Consumed by: React Engineer (T1-14)
> Against: `briefs/requirements/tenant-admin-webapp.md` FR-07–FR-10

---

## 1. Shell layout (shared across all authenticated pages)

All authenticated pages render inside this shell. Define it once here; later specs reference it.

```
┌──────────────────────────────────────────────────────────┐
│  Sidebar (w-64, fixed, full-height)                      │
│  bg-gray-900 text-gray-100                               │
├──────────────────────────────────────────────────────────┤
│  Main column (flex-1, ml-64)                             │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Topbar (h-14, bg-white, border-b border-gray-200) │  │
│  ├────────────────────────────────────────────────────┤  │
│  │  Content area (p-6, bg-gray-50, min-h-screen)      │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

### 1.1 Sidebar

- Width: `w-64` (256 px), fixed positioning, full viewport height
- Background: `bg-gray-900`

**Logo area** (`h-16`, `border-b border-gray-800`, flex centering):
- LactoSync logo SVG (`h-7`) + wordmark in `text-white text-lg font-semibold`
- Below logo: `<span className="text-xs text-green-400 font-medium tracking-wider uppercase">Admin</span>`

**Navigation links** (`mt-4`, `px-3`):
- shadcn is not used for the nav itself — use a plain `<nav>` with styled `<a>` / React Router `<NavLink>`
- Each link: `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium`
- Inactive: `text-gray-400 hover:bg-gray-800 hover:text-white`
- Active: `bg-green-700 text-white`

| Icon (lucide) | Label | Route |
|---------------|-------|-------|
| `LayoutDashboard` | Dashboard | `/dashboard` |
| `Building2` | Tenants | `/tenants` |
| `CreditCard` | Plans | `/plans` |
| `Banknote` | Payments | `/payments` |

**Logout button** (pinned to bottom, `mt-auto mb-4 px-3`):
- shadcn `Button` — `variant="ghost"`, `className="w-full justify-start gap-3 text-gray-400 hover:text-white hover:bg-gray-800"`
- `LogOut` lucide icon + "Log Out" label
- On click: call `POST /api/admin/v1/auth/logout`, clear token, navigate to `/login`

### 1.2 Topbar

- Height: `h-14`, `bg-white`, `border-b border-gray-200`
- Left: page title — `<h1 className="text-lg font-semibold text-gray-800">` (injected per page)
- Right side (flex gap-3 items-center):
  - Last refreshed text: `<span className="text-xs text-gray-400">Last refreshed: HH:MM:SS</span>`
  - Refresh icon: `RefreshCw` lucide, `w-4 h-4 text-gray-400`, class `animate-spin` added while background fetch is in flight; click triggers manual refresh

---

## 2. Dashboard page (`/dashboard`)

### 2.1 Page title
Topbar: "Dashboard"

### 2.2 KPI card grid

Two rows of shadcn `Card` components, responsive grid:

```
Row 1: grid-cols-4 gap-4
Row 2: grid-cols-3 gap-4 mt-4  (3 cards, left-aligned)
```

Each KPI card structure:
```
<Card className="p-5">
  <div className="flex items-start justify-between">
    <div>
      <p className="text-xs font-medium text-gray-500 uppercase tracking-wide">{label}</p>
      <p className="mt-1 text-3xl font-bold text-gray-900">{value}</p>
      {subtitle && <p className="mt-0.5 text-xs text-gray-400">{subtitle}</p>}
    </div>
    <div className="rounded-full p-2 bg-{color}-50">
      <Icon className="w-5 h-5 text-{color}-600" />
    </div>
  </div>
</Card>
```

**Row 1 — 4 cards:**

| # | Label | Icon (lucide) | Accent color | Subtitle |
|---|-------|---------------|-------------|---------|
| 1 | Total Tenants | `Building2` | `green` | `"{active} active · {paused} paused · {expired} expired"` |
| 2 | Active Subscriptions | `Users` | `green` | "Milk-delivery subscriptions" |
| 3 | Total Customers | `UserCheck` | `blue` | "Across all tenants" |
| 4 | Today's Orders | `ShoppingBag` | `purple` | `date("Today, D MMM")` |

**Row 2 — 3 cards:**

| # | Label | Icon (lucide) | Accent color | Subtitle |
|---|-------|---------------|-------------|---------|
| 5 | Total Collected | `CircleDollarSign` | `green` | "This month" |
| 6 | Total Billed | `Receipt` | `blue` | "This month" |
| 7 | Pending Dues | `AlertCircle` | `red` | "Outstanding across all tenants" |

- Cards 5 and 6: currency values formatted as `₹X,XX,XXX` (Indian numbering)
- Card 7 (Pending Dues): if value > 0, `text-red-600` on the amount; if 0, `text-gray-900`

### 2.3 Tenant summary table

Below the KPI rows, `mt-8`.

**Table header row:**
```
<div className="flex items-center justify-between mb-3">
  <h2 className="text-base font-semibold text-gray-800">All Tenants</h2>
  <Button variant="outline" size="sm" onClick={() => navigate('/tenants')}>
    View All
  </Button>
</div>
```

shadcn `Table`:

| Column | Width hint | Notes |
|--------|-----------|-------|
| Tenant Name | auto | Clickable link → `/tenants/:id` (`text-green-700 font-medium hover:underline`) |
| Plan | auto | Plan name string or "—" if none |
| Status | 130px | `Badge` component (see variants below) |
| Renewal Date | 120px | `DD MMM YYYY` or "—" |
| Days Left | 100px | Colored number (see rules below) |
| Last Payment | 120px | `DD MMM YYYY` or "Never" |
| Outstanding | 110px | `₹X,XXX` in `text-red-600` if >0, else `text-gray-600` |
| Actions | 60px | `DropdownMenu` (see below) |

**Status badge variants (`Badge` from shadcn):**

| State | Variant | Extra className | Text |
|-------|---------|----------------|------|
| Active | `default` | `bg-green-100 text-green-800 border-green-200` | "Active" |
| Grace period | `secondary` | `bg-amber-100 text-amber-800 border-amber-200` | "Grace — X days" |
| Suspended | `destructive` | (default destructive = red) | "Suspended" |
| No Plan | `outline` | `text-gray-500` | "No Plan" |
| Paused | `secondary` | `bg-blue-100 text-blue-800 border-blue-200` | "Paused" |

**Days Left coloring (plain text, not badge):**
- `> 7` days: `text-green-700 font-medium`
- `1–7` days: `text-amber-600 font-semibold`
- `0` or negative: `text-red-600 font-semibold` (show "Overdue" for negatives)

**Actions column — `DropdownMenu`:**
- Trigger: `MoreHorizontal` lucide icon inside `Button variant="ghost" size="icon"`
- Items:
  1. `Eye` icon · "View Details" → navigate to `/tenants/:id`
  2. `Banknote` icon · "Record Payment" → open Record Payment modal (pre-filled tenant)
  3. `CreditCard` icon · "Manage Plan" → navigate to `/tenants/:id` (plan section)
- `DropdownMenuSeparator` between items 2 and 3 is optional

**Suspended tenant row highlight:**
- Row `className` includes `bg-red-50` when status is Suspended
- This ensures suspended tenants are visually prominent even before the badge is read

### 2.4 Loading state

While the API call is in flight on initial mount:

**KPI cards:** Replace card content with `Skeleton`:
```
<Skeleton className="h-6 w-24 mb-2" />   {/* label */}
<Skeleton className="h-9 w-16" />          {/* value */}
```
(7 cards total, same grid positions)

**Table:** 5 skeleton rows — each cell a `<Skeleton className="h-4 w-full" />`

### 2.5 Empty state (no tenants)

When tenant array is empty (possible on first setup):
```
<div className="flex flex-col items-center justify-center py-20 text-center">
  <Building2 className="w-16 h-16 text-gray-200 mb-4" />
  <h3 className="text-lg font-semibold text-gray-600 mb-1">No tenants yet</h3>
  <p className="text-sm text-gray-400">Tenants you create will appear here.</p>
</div>
```

KPI cards still render with `0` values.

### 2.6 Error state

When the API call fails (network error or 5xx):
```
<Alert variant="destructive" className="mb-6">
  <AlertCircle className="h-4 w-4" />
  <AlertTitle>Failed to load dashboard</AlertTitle>
  <AlertDescription>
    Could not fetch data from the server.
    <Button variant="link" className="p-0 h-auto ml-1" onClick={refresh}>
      Try again
    </Button>
  </AlertDescription>
</Alert>
```
KPI cards and table show last cached values (or skeleton if first load).

### 2.7 Auto-refresh behaviour

- `useEffect` sets up `setInterval(fetchDashboard, 60_000)` on mount; clears on unmount
- While a background refresh is in flight: `RefreshCw` in topbar gets `animate-spin` class
- On background error: do NOT replace page content — show a subtle `toast` (shadcn `sonner`):
  `toast.warning("Auto-refresh failed — showing last data")`
- Manual refresh: click the `RefreshCw` icon triggers `fetchDashboard()` immediately

---

## 3. Design tokens (dashboard-specific)

| Token | Tailwind | Usage |
|-------|----------|-------|
| Sidebar bg | `gray-900` | Left nav |
| Sidebar active link | `green-700` | Active nav item bg |
| Content bg | `gray-50` | Page background |
| Card bg | `white` | KPI and table cards |
| Accent green | `green-700` / `green-100` | Brand KPI icon + badge bg |
| Suspended row | `red-50` | Row highlight |
| Overdue amount | `red-600` | Outstanding column |
| Warning badge | `amber-100 / amber-800` | Grace badge |

---

## 4. Navigation flow

```
/dashboard
  ├── tenant name click ──▶ /tenants/:id
  ├── "View All" button ──▶ /tenants
  ├── Actions → "View Details" ──▶ /tenants/:id
  ├── Actions → "Record Payment" ──▶ opens Record Payment modal (overlay)
  └── Actions → "Manage Plan" ──▶ /tenants/:id  (scroll to plan section)
```
