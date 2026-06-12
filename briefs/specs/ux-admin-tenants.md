# UX Spec — Tenant Management (T1-04)

> Author: UX/UI Designer · Story: T1-04 · Date: 2026-06-05
> Consumed by: React Engineer (T1-15)
> Against: `briefs/requirements/tenant-admin-webapp.md` FR-11–FR-18
> Shell layout: see `briefs/specs/ux-admin-dashboard.md` §1

---

## 1. Screen inventory

| ID | Screen | Route |
|----|--------|-------|
| TN-01 | Tenant list | `/tenants` |
| TN-02 | Tenant detail | `/tenants/:id` |
| TN-03 | Assign Plan modal | overlay on TN-02 |
| TN-04 | Change Plan modal | overlay on TN-02 |
| TN-05 | Pause Plan modal | overlay on TN-02 |
| TN-06 | Resume Plan modal | overlay on TN-02 |

---

## 2. Tenant list page (TN-01)

### 2.1 Topbar
Page title: "Tenants"

### 2.2 Toolbar row

```
<div className="flex items-center gap-3 mb-4">
  {/* Search */}
  <div className="relative flex-1 max-w-sm">
    <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
    <Input
      placeholder="Search tenants…"
      className="pl-9"
      value={search}
      onChange={e => setSearch(e.target.value)}
    />
  </div>

  {/* Status filter */}
  <Select value={statusFilter} onValueChange={setStatusFilter}>
    <SelectTrigger className="w-44">
      <SelectValue placeholder="All Statuses" />
    </SelectTrigger>
    <SelectContent>
      <SelectItem value="all">All Statuses</SelectItem>
      <SelectItem value="active">Active</SelectItem>
      <SelectItem value="grace">Grace Period</SelectItem>
      <SelectItem value="suspended">Suspended</SelectItem>
      <SelectItem value="no_plan">No Plan</SelectItem>
      <SelectItem value="paused">Paused</SelectItem>
    </SelectContent>
  </Select>
</div>
```

### 2.3 Tenant table

shadcn `Table`:

| Column | Width hint | Notes |
|--------|-----------|-------|
| Tenant Name | auto | `text-green-700 font-medium cursor-pointer hover:underline` → `/tenants/:id` |
| Phone | 130px | formatted phone number |
| Plan | auto | plan name or `<span className="text-gray-400 italic">No plan</span>` |
| Status | 140px | `Badge` (same variants as dashboard spec §2.3) |
| Renewal Date | 120px | `DD MMM YYYY` or "—" |
| Outstanding | 110px | `₹X,XXX` in `text-red-600` if >0, else `text-gray-500` |
| Actions | 60px | `DropdownMenu` |

**Suspended row highlight:** `className="bg-red-50"` (same rule as dashboard)

**Actions `DropdownMenu` — context-sensitive items:**

All statuses always show:
- `Eye` · "View Details" → `/tenants/:id`

Conditional (based on current status):
| Current status | Show item |
|----------------|-----------|
| No Plan | `CreditCard` · "Assign Plan" → opens TN-03 |
| Active, Grace, Suspended | `CreditCard` · "Change Plan" → opens TN-04 |
| Active | `PauseCircle` · "Pause Plan" → opens TN-05 |
| Paused | `PlayCircle` · "Resume Plan" → opens TN-06 |
| Any (not No Plan) | `Banknote` · "Record Payment" → opens Record Payment modal |

`DropdownMenuSeparator` before "Record Payment".

### 2.4 Loading state
5 skeleton rows; toolbar inputs still rendered.

### 2.5 Empty state
```
<div className="flex flex-col items-center py-16 text-center">
  <Building2 className="w-12 h-12 text-gray-200 mb-3" />
  <p className="text-sm font-medium text-gray-500">No tenants found</p>
  <p className="text-xs text-gray-400 mt-1">Try adjusting your search or filter.</p>
</div>
```

### 2.6 Error state
Same `Alert variant="destructive"` pattern as dashboard §2.6. Message: "Failed to load tenants."

---

## 3. Tenant detail page (TN-02)

### 3.1 Topbar
- Page title: "{Tenant Farm Name}"
- Breadcrumb just below topbar (inline, small): `Tenants / {Farm Name}` — `Tenants` is a link back to `/tenants`

### 3.2 Page layout

Two-column layout on wide screens (`grid grid-cols-3 gap-6`):
- Left column (`col-span-2`): Plan Status, Usage vs Limits, Payment History, Activity Trail
- Right column (`col-span-1`): Tenant Profile card, Payment Summary card

On narrower screens (768px–1280px): single column, right-column cards move to top.

---

### 3.3 Right column — Tenant Profile card

```
<Card className="p-5 mb-4">
  <CardHeader className="p-0 mb-4">
    <div className="flex items-start justify-between">
      <div>
        <CardTitle className="text-base">{farm_name}</CardTitle>
        <CardDescription>{owner_name}</CardDescription>
      </div>
      <Badge ...>  {/* status badge */}
      <Button variant="outline" size="sm" disabled>Edit</Button>
    </div>
  </CardHeader>
  <CardContent className="p-0 space-y-2 text-sm text-gray-600">
    <div className="flex gap-2"><Phone className="w-4 h-4 mt-0.5 text-gray-400" />{phone}</div>
    <div className="flex gap-2"><Mail className="w-4 h-4 mt-0.5 text-gray-400" />{email}</div>
    <div className="flex gap-2"><MapPin className="w-4 h-4 mt-0.5 text-gray-400" />{address}</div>
    <div className="flex gap-2"><Calendar className="w-4 h-4 mt-0.5 text-gray-400" />
      <span className="text-gray-400">Since</span> {joined_date}
    </div>
  </CardContent>
</Card>
```

Edit button: `disabled` + `Tooltip` "Tenant profile editing is not available in this release."

---

### 3.4 Right column — Payment Summary card

```
<Card className="p-5">
  <CardTitle className="text-sm font-semibold text-gray-700 mb-3">Payment Summary</CardTitle>
  <div className="space-y-2 text-sm">
    <div className="flex justify-between">
      <span className="text-gray-500">Last paid</span>
      <span className="font-medium">{last_paid_date || "Never"}</span>
    </div>
    <div className="flex justify-between">
      <span className="text-gray-500">Last amount</span>
      <span className="font-medium">{last_paid_amount ? `₹${last_paid_amount}` : "—"}</span>
    </div>
    <Separator className="my-2" />
    <div className="flex justify-between">
      <span className="text-gray-500 font-medium">Outstanding</span>
      <span className={outstanding > 0 ? "font-bold text-red-600" : "font-medium text-gray-700"}>
        ₹{outstanding}
      </span>
    </div>
  </div>
</Card>
```

---

### 3.5 Left column — Plan Status card

```
<Card className="p-5 mb-4">
  <div className="flex items-center justify-between mb-4">
    <div>
      <p className="text-xs text-gray-400 uppercase tracking-wide mb-0.5">Current Plan</p>
      <p className="text-lg font-semibold text-gray-900">{plan_name || "No plan assigned"}</p>
    </div>
    <Badge ...>  {/* status badge */}
  </div>

  {/* Timeline dates */}
  <div className="grid grid-cols-3 gap-2 text-sm mb-4">
    <div>
      <p className="text-xs text-gray-400">Start date</p>
      <p className="font-medium">{start_date}</p>
    </div>
    <div>
      <p className="text-xs text-gray-400">Renewal date</p>
      <p className="font-medium">{renewal_date}</p>
    </div>
    <div>
      <p className="text-xs text-gray-400">Days remaining</p>
      <p className={`font-semibold ${daysColor}`}>{days_remaining}</p>
    </div>
  </div>

  {/* Progress bar start→renewal */}
  <div className="mb-4">
    <div className="flex justify-between text-xs text-gray-400 mb-1">
      <span>{start_date}</span>
      <span>{renewal_date}</span>
    </div>
    <Progress value={progressPct} className="h-2" />
    {/* progressPct = days elapsed / total days * 100 */}
    {/* Progress bar color: green if >30% remaining, amber 10–30%, red <10% */}
  </div>

  {/* Action buttons */}
  <div className="flex gap-2">
    {!hasPlan && (
      <Button size="sm" className="bg-green-700 hover:bg-green-800 text-white"
        onClick={() => openModal('assign')}>
        Assign Plan
      </Button>
    )}
    {hasPlan && (
      <>
        <Button size="sm" variant="outline" onClick={() => openModal('change')}>
          Change Plan
        </Button>
        {status !== 'paused'
          ? <Button size="sm" variant="outline" onClick={() => openModal('pause')}>
              <PauseCircle className="w-4 h-4 mr-1" /> Pause
            </Button>
          : <Button size="sm" variant="outline" onClick={() => openModal('resume')}>
              <PlayCircle className="w-4 h-4 mr-1" /> Resume
            </Button>
        }
      </>
    )}
  </div>
</Card>
```

**Progress bar color (override via className):**
- >30% remaining: `[&>div]:bg-green-600`
- 10–30%: `[&>div]:bg-amber-500`
- <10%: `[&>div]:bg-red-500`

---

### 3.6 Left column — Usage vs Limits card

```
<Card className="p-5 mb-4">
  <CardTitle className="text-sm font-semibold text-gray-700 mb-4">Usage vs Plan Limits</CardTitle>

  {/* Customers */}
  <div className="mb-3">
    <div className="flex justify-between text-sm mb-1">
      <span className="text-gray-600">Customers</span>
      <span className={usagePct(customers) > 90 ? "text-red-600 font-semibold" : "text-gray-700"}>
        {customers.current} / {customers.max}
      </span>
    </div>
    <Progress value={usagePct(customers)} className={progressColor(customers)} />
  </div>

  {/* Subscriptions */}
  <div>
    <div className="flex justify-between text-sm mb-1">
      <span className="text-gray-600">Subscriptions</span>
      <span className={usagePct(subs) > 90 ? "text-red-600 font-semibold" : "text-gray-700"}>
        {subs.current} / {subs.max}
      </span>
    </div>
    <Progress value={usagePct(subs)} className={progressColor(subs)} />
  </div>
</Card>
```

`usagePct(item)` = `item.current / item.max * 100`
Progress color: same rule as plan timeline (green / amber / red at 90%+ threshold)
If no plan assigned, render: `<p className="text-sm text-gray-400 italic">No plan — limits not applicable.</p>`

---

### 3.7 Left column — Payment History

```
<div className="mb-6">
  <div className="flex items-center justify-between mb-3">
    <h3 className="text-base font-semibold text-gray-800">Payment History</h3>
    <Button size="sm" className="bg-green-700 hover:bg-green-800 text-white"
      onClick={() => openRecordPaymentModal()}>
      <Plus className="w-4 h-4 mr-1" /> Record Payment
    </Button>
  </div>

  <Table>
    <TableHeader>
      <TableRow>
        <TableHead>Date</TableHead>
        <TableHead>Amount</TableHead>
        <TableHead>Method</TableHead>
        <TableHead>Paid By</TableHead>
        <TableHead>Reference</TableHead>
        <TableHead className="w-16"></TableHead>
      </TableRow>
    </TableHeader>
    <TableBody>
      {payments.map(p => (
        <TableRow key={p.id}>
          <TableCell>{formatDate(p.payment_date)}</TableCell>
          <TableCell className="font-medium">₹{p.amount}</TableCell>
          <TableCell>{p.method}</TableCell>
          <TableCell>{p.paid_by}</TableCell>
          <TableCell className="text-gray-400 text-xs">{p.reference || "—"}</TableCell>
          <TableCell>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon"><MoreHorizontal className="w-4 h-4" /></Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => openEditPayment(p)}>
                  <Pencil className="w-4 h-4 mr-2" /> Edit
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem className="text-red-600"
                  onClick={() => openDeletePayment(p)}>
                  <Trash2 className="w-4 h-4 mr-2" /> Delete
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </TableCell>
        </TableRow>
      ))}
    </TableBody>
  </Table>

  {payments.length === 0 && (
    <p className="text-sm text-gray-400 text-center py-6">No payments recorded yet.</p>
  )}
</div>
```

---

### 3.8 Left column — Activity Trail

```
<div>
  <h3 className="text-base font-semibold text-gray-800 mb-3">Activity Trail</h3>
  <ol className="relative border-l border-gray-200 ml-3 space-y-4">
    {activities.map(a => (
      <li key={a.id} className="ml-4">
        <div className="absolute -left-1.5 w-3 h-3 rounded-full bg-green-500 border-2 border-white" />
        <time className="text-xs text-gray-400">{formatDateTime(a.created_at)}</time>
        <p className="text-sm text-gray-700 mt-0.5">
          <span className="font-medium">{a.action_label}</span>
          {a.reason && <span className="text-gray-400"> — {a.reason}</span>}
        </p>
      </li>
    ))}
  </ol>
  {activities.length === 0 && (
    <p className="text-sm text-gray-400">No activity recorded yet.</p>
  )}
</div>
```

**Action labels (derive from `action_type`):**

| action_type | Label |
|-------------|-------|
| `plan_assigned` | "Plan assigned: {plan_name}" |
| `plan_changed` | "Plan changed to {new_plan}" |
| `plan_paused` | "Plan paused" |
| `plan_resumed` | "Plan resumed" |
| `payment_recorded` | "Payment of ₹{amount} recorded" |

---

## 4. Plan-action modals

All modals use shadcn `Dialog`. Max width `max-w-md`.

### 4.1 Assign Plan modal (TN-03)

Opened when: tenant has no current plan.

```
<Dialog>
  <DialogContent className="max-w-md">
    <DialogHeader>
      <DialogTitle>Assign Plan</DialogTitle>
      <DialogDescription>Select a plan and start date for {tenant_name}.</DialogDescription>
    </DialogHeader>

    <div className="space-y-4 py-2">
      <div>
        <Label>Plan</Label>
        <Select required>
          <SelectTrigger><SelectValue placeholder="Choose a plan" /></SelectTrigger>
          <SelectContent>
            {activePlans.map(p => (
              <SelectItem key={p.id} value={p.id}>
                {p.name} — ₹{p.price}/{p.billing_cycle_label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        {/* Note: archived plans are excluded from this list */}
      </div>

      <div>
        <Label>Start Date</Label>
        <DatePicker value={startDate} onChange={setStartDate} />
        {/* Default: today */}
      </div>
    </div>

    <DialogFooter>
      <Button variant="outline" onClick={close}>Cancel</Button>
      <Button className="bg-green-700 hover:bg-green-800 text-white"
        onClick={submit} disabled={!selectedPlan}>
        Assign Plan
      </Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

On success: toast "Plan assigned successfully." · close modal · refresh tenant detail.

### 4.2 Change Plan modal (TN-04)

Opened when: tenant has an active/paused plan.

```
<Dialog>
  <DialogContent className="max-w-md">
    <DialogHeader>
      <DialogTitle>Change Plan</DialogTitle>
    </DialogHeader>

    <div className="space-y-4 py-2">
      {/* Current plan (read-only) */}
      <div className="rounded-md bg-gray-50 border border-gray-200 px-3 py-2 text-sm">
        <span className="text-gray-400 text-xs block mb-0.5">Current plan</span>
        <span className="font-medium">{current_plan_name}</span>
      </div>

      {/* New plan select */}
      <div>
        <Label>New Plan</Label>
        <Select required>
          <SelectTrigger><SelectValue placeholder="Choose a plan" /></SelectTrigger>
          <SelectContent>
            {activePlans.filter(p => p.id !== current_plan_id).map(p => (
              <SelectItem key={p.id} value={p.id}>
                {p.name} — ₹{p.price}/{p.billing_cycle_label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Auto-label: Upgrade / Downgrade */}
      {selectedPlan && (
        <div className={`text-sm font-medium px-3 py-1.5 rounded-md ${
          selectedPlan.price > current_plan_price
            ? "bg-green-50 text-green-700"
            : "bg-amber-50 text-amber-700"
        }`}>
          {selectedPlan.price > current_plan_price ? "↑ Upgrade" : "↓ Downgrade"}
        </div>
      )}

      {/* Reason */}
      <div>
        <Label>Reason <span className="text-red-500">*</span></Label>
        <Textarea
          placeholder="e.g. Tenant requested upgrade to accommodate more customers"
          required
          rows={2}
        />
      </div>
    </div>

    <DialogFooter>
      <Button variant="outline" onClick={close}>Cancel</Button>
      <Button className="bg-green-700 hover:bg-green-800 text-white"
        onClick={submit} disabled={!selectedPlan || !reason}>
        Confirm Change
      </Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

On success: toast "Plan updated." · close modal · refresh.

### 4.3 Pause Plan modal (TN-05)

```
<Dialog>
  <DialogContent className="max-w-sm">
    <DialogHeader>
      <DialogTitle>Pause Plan</DialogTitle>
    </DialogHeader>

    <div className="py-2">
      <Alert className="border-amber-300 bg-amber-50">
        <PauseCircle className="h-4 w-4 text-amber-600" />
        <AlertDescription className="text-amber-800">
          The renewal clock will stop. The tenant's renewal date is frozen until
          the plan is resumed. Active tenant access continues during the pause.
        </AlertDescription>
      </Alert>
    </div>

    <DialogFooter>
      <Button variant="outline" onClick={close}>Cancel</Button>
      <Button variant="destructive" onClick={submit}>
        Pause Plan
      </Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

On success: toast "Plan paused." · close modal · refresh.

### 4.4 Resume Plan modal (TN-06)

```
<Dialog>
  <DialogContent className="max-w-sm">
    <DialogHeader>
      <DialogTitle>Resume Plan</DialogTitle>
    </DialogHeader>

    <div className="py-2">
      <p className="text-sm text-gray-600">
        The renewal clock will restart from today. The tenant's remaining days
        are preserved from the point the plan was paused.
      </p>
    </div>

    <DialogFooter>
      <Button variant="outline" onClick={close}>Cancel</Button>
      <Button className="bg-green-700 hover:bg-green-800 text-white" onClick={submit}>
        Resume Plan
      </Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

On success: toast "Plan resumed." · close modal · refresh.

---

## 5. Loading & error states (detail page)

**Loading:** Full-page skeleton — profile card, plan card, usage card all show `Skeleton` blocks matching their rough dimensions.

**Not found (404):**
```
<div className="flex flex-col items-center py-20 text-center">
  <AlertCircle className="w-12 h-12 text-gray-300 mb-3" />
  <h3 className="text-lg font-semibold text-gray-600">Tenant not found</h3>
  <Button variant="link" onClick={() => navigate('/tenants')}>
    Back to tenants
  </Button>
</div>
```

**API error:** Same `Alert variant="destructive"` pattern + "Try again" link.

---

## 6. Design tokens (tenant pages)

| Token | Tailwind | Usage |
|-------|----------|-------|
| Progress green | `green-600` | Healthy usage bars |
| Progress amber | `amber-500` | Moderate usage bars |
| Progress red | `red-500` | Critical usage / overdue timeline |
| Activity dot | `green-500` | Timeline bullet |
| Disabled Edit button | gray outline, cursor-not-allowed | Profile edit |
| Upgrade chip | `green-50 / green-700` | Plan change auto-label |
| Downgrade chip | `amber-50 / amber-700` | Plan change auto-label |

---

## 7. Navigation flow

```
/tenants (TN-01)
  ├── row click / "View Details" ──▶ /tenants/:id (TN-02)
  ├── "Assign Plan" ──▶ TN-03 modal
  ├── "Change Plan" ──▶ TN-04 modal
  ├── "Pause Plan" ──▶ TN-05 modal
  ├── "Resume Plan" ──▶ TN-06 modal
  └── "Record Payment" ──▶ Record Payment modal (see ux-admin-payments.md)

/tenants/:id (TN-02)
  ├── breadcrumb "Tenants" ──▶ /tenants
  ├── "Assign Plan" button ──▶ TN-03 modal
  ├── "Change Plan" button ──▶ TN-04 modal
  ├── "Pause" / "Resume" button ──▶ TN-05 / TN-06 modal
  └── "Record Payment" button ──▶ Record Payment modal (pre-filled, see ux-admin-payments.md)
```
