# UX Spec — Payment Tracking (T1-06)

> Author: UX/UI Designer · Story: T1-06 · Date: 2026-06-05
> Consumed by: React Engineer (T1-17)
> Against: `briefs/requirements/tenant-admin-webapp.md` FR-23–FR-27
> Shell layout: see `briefs/specs/ux-admin-dashboard.md` §1
> Per-tenant payment history table: embedded in Tenant Detail — see `briefs/specs/ux-admin-tenants.md` §3.7
>   This spec details the modal used from both the global list and the tenant detail page.

---

## 1. Screen inventory

| ID | Screen | Route / trigger |
|----|--------|----------------|
| PY-01 | Global payments list | `/payments` |
| PY-02 | Record Payment modal | `Dialog` overlay (opens from dashboard, tenant list, tenant detail, global list) |
| PY-03 | Edit Payment modal | `Dialog` overlay (same form pre-populated) |
| PY-04 | Delete Payment confirmation | `AlertDialog` overlay |

---

## 2. Global payments list (PY-01)

### 2.1 Topbar
Page title: "Payments"

### 2.2 Outstanding summary card

Rendered at the very top of the content area, before filters:

```
<Card className="mb-5 p-4 flex items-center justify-between bg-red-50 border-red-200">
  <div className="flex items-center gap-3">
    <AlertCircle className="w-5 h-5 text-red-500" />
    <div>
      <p className="text-xs text-red-600 font-medium uppercase tracking-wide">
        Total Outstanding
      </p>
      <p className="text-2xl font-bold text-red-700">₹{totalOutstanding}</p>
    </div>
  </div>
  <p className="text-xs text-red-400">Across all tenants</p>
</Card>
```

If `totalOutstanding === 0`:
```
<Card className="mb-5 p-4 flex items-center gap-3 bg-green-50 border-green-200">
  <CheckCircle2 className="w-5 h-5 text-green-600" />
  <p className="text-sm font-medium text-green-700">All accounts are settled. No outstanding dues.</p>
</Card>
```

### 2.3 Toolbar row

```
<div className="flex flex-wrap items-center gap-3 mb-4">
  {/* Date range */}
  <DatePickerWithRange
    value={dateRange}
    onChange={setDateRange}
    className="w-64"
    placeholder="Filter by date range"
  />

  {/* Tenant filter */}
  <Select value={tenantFilter} onValueChange={setTenantFilter}>
    <SelectTrigger className="w-48">
      <SelectValue placeholder="All Tenants" />
    </SelectTrigger>
    <SelectContent>
      <SelectItem value="all">All Tenants</SelectItem>
      {tenants.map(t => (
        <SelectItem key={t.id} value={t.id}>{t.farm_name}</SelectItem>
      ))}
    </SelectContent>
  </Select>

  {/* Sort by */}
  <Select value={sortBy} onValueChange={setSortBy} defaultValue="date_desc">
    <SelectTrigger className="w-40">
      <SelectValue />
    </SelectTrigger>
    <SelectContent>
      <SelectItem value="date_desc">Date (Newest)</SelectItem>
      <SelectItem value="date_asc">Date (Oldest)</SelectItem>
      <SelectItem value="amount_desc">Amount (High–Low)</SelectItem>
      <SelectItem value="amount_asc">Amount (Low–High)</SelectItem>
      <SelectItem value="tenant_asc">Tenant (A–Z)</SelectItem>
    </SelectContent>
  </Select>

  {/* Clear filters */}
  {(dateRange || tenantFilter !== 'all') && (
    <Button variant="ghost" size="sm" onClick={clearFilters}
      className="text-gray-400 hover:text-gray-600">
      <X className="w-4 h-4 mr-1" /> Clear
    </Button>
  )}

  {/* Record Payment CTA — right-aligned */}
  <Button className="ml-auto bg-green-700 hover:bg-green-800 text-white"
    onClick={() => openRecordPayment(null)}>
    <Plus className="w-4 h-4 mr-1.5" /> Record Payment
  </Button>
</div>
```

### 2.4 Payments table

shadcn `Table`:

| Column | Width hint | Notes |
|--------|-----------|-------|
| Date | 110px | Payment date, `DD MMM YYYY` |
| Tenant | auto | `text-green-700 font-medium cursor-pointer hover:underline` → `/tenants/:id` |
| Amount | 100px | `₹{amount}` `font-medium` |
| Method | 110px | UPI / Cash / Credit Card |
| Paid By | auto | free text |
| Reference | auto | `text-gray-400 text-xs truncate max-w-[140px]` or "—" |
| Actions | 60px | `DropdownMenu` |

**Actions `DropdownMenu`:**
```
<DropdownMenu>
  <DropdownMenuTrigger asChild>
    <Button variant="ghost" size="icon">
      <MoreHorizontal className="w-4 h-4" />
    </Button>
  </DropdownMenuTrigger>
  <DropdownMenuContent align="end">
    <DropdownMenuItem onClick={() => openEditPayment(payment)}>
      <Pencil className="w-4 h-4 mr-2" /> Edit
    </DropdownMenuItem>
    <DropdownMenuSeparator />
    <DropdownMenuItem className="text-red-600"
      onClick={() => openDeleteConfirm(payment)}>
      <Trash2 className="w-4 h-4 mr-2" /> Delete
    </DropdownMenuItem>
  </DropdownMenuContent>
</DropdownMenu>
```

### 2.5 Loading state
Outstanding summary card shows `Skeleton className="h-8 w-32"` in place of the amount.
Table: 8 skeleton rows.

### 2.6 Empty state (no payments match filters)
```
<div className="flex flex-col items-center py-16 text-center">
  <Banknote className="w-12 h-12 text-gray-200 mb-3" />
  <p className="text-sm font-medium text-gray-500">No payments found</p>
  <p className="text-xs text-gray-400 mt-1">
    {hasFilters
      ? "Try adjusting your filters."
      : "Record the first payment to get started."}
  </p>
</div>
```

### 2.7 Error state
`Alert variant="destructive"` · "Failed to load payments. Try again."

---

## 3. Record Payment modal (PY-02)

This modal is opened from: dashboard Actions menu · tenant list Actions menu · tenant detail "Record Payment" button · global payments list "Record Payment" button.

When opened from a tenant context, `tenantId` is pre-filled and the Tenant field is locked. When opened from a global context (dashboard, global list), the Tenant field is an editable `Select`.

### 3.1 Modal structure

```
<Dialog open={open} onOpenChange={setOpen}>
  <DialogContent className="max-w-lg">
    <DialogHeader>
      <DialogTitle>Record Payment</DialogTitle>
      <DialogDescription>
        Record a SaaS subscription payment for a tenant.
      </DialogDescription>
    </DialogHeader>

    <form onSubmit={handleSubmit} className="space-y-4 py-2">
      {/* fields — see §3.2 */}
    </form>

    <DialogFooter>
      <Button variant="outline" onClick={close} type="button">Cancel</Button>
      <Button type="submit" className="bg-green-700 hover:bg-green-800 text-white"
        disabled={isSubmitting}>
        {isSubmitting
          ? <><Loader2 className="w-4 h-4 mr-1.5 animate-spin" /> Recording…</>
          : "Record Payment"}
      </Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

### 3.2 Form fields

#### Tenant (conditional)
```
{/* Show read-only if opened from tenant context; editable Select if opened globally */}
{tenantId ? (
  <div>
    <Label>Tenant</Label>
    <div className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-sm font-medium">
      {tenantName}
    </div>
  </div>
) : (
  <div>
    <Label>Tenant <span className="text-red-500">*</span></Label>
    <Select required value={selectedTenant} onValueChange={setSelectedTenant}>
      <SelectTrigger><SelectValue placeholder="Choose a tenant" /></SelectTrigger>
      <SelectContent>
        {tenants.map(t => (
          <SelectItem key={t.id} value={t.id}>{t.farm_name}</SelectItem>
        ))}
      </SelectContent>
    </Select>
  </div>
)}
```

#### Amount (required)
```
<div>
  <Label htmlFor="amount">Amount <span className="text-red-500">*</span></Label>
  <div className="relative">
    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">₹</span>
    <Input id="amount" type="number" min="1" step="1" placeholder="0"
      className="pl-7" required />
  </div>
</div>
```

#### Payment Date (required)
```
<div>
  <Label>Payment Date <span className="text-red-500">*</span></Label>
  <DatePicker value={paymentDate} onChange={setPaymentDate} defaultValue={today} required />
</div>
```

#### Due Date (required)
```
<div>
  <Label>Due Date <span className="text-red-500">*</span></Label>
  <DatePicker value={dueDate} onChange={setDueDate} required />
  <p className="text-xs text-gray-400 mt-1">
    The billing due date this payment is covering.
  </p>
</div>
```

#### Payment Method (required)
```
<div>
  <Label>Payment Method <span className="text-red-500">*</span></Label>
  <Select required>
    <SelectTrigger><SelectValue placeholder="Select method" /></SelectTrigger>
    <SelectContent>
      <SelectItem value="upi">UPI</SelectItem>
      <SelectItem value="cash">Cash</SelectItem>
      <SelectItem value="credit_card">Credit Card</SelectItem>
    </SelectContent>
  </Select>
</div>
```

#### Paid By (required)
```
<div>
  <Label htmlFor="paid_by">Paid By <span className="text-red-500">*</span></Label>
  <Input id="paid_by" placeholder="e.g. Farm owner name" required />
</div>
```

#### Reference / Notes (optional)
```
<div>
  <Label htmlFor="reference">Reference / Notes</Label>
  <Input id="reference" placeholder="e.g. UPI transaction ID, bank ref, note"
    maxLength={255} />
</div>
```

### 3.3 Validation errors

- Required field empty: red border + `<p className="text-xs text-red-500 mt-1">Required.</p>`
- Amount ≤ 0: "Amount must be greater than 0."
- API error: `Alert variant="destructive"` inside modal above footer. Message: "Failed to record payment. Please try again."

### 3.4 On success

```
toast.success("Payment recorded successfully.")
closeModal()
// refresh calling context:
//   - if opened from tenant detail: refetch tenant payments + outstanding balance
//   - if opened from global list: refetch payments table + outstanding summary card
//   - if opened from dashboard: refetch KPI cards
```

---

## 4. Edit Payment modal (PY-03)

Same form as PY-02, but:
- `DialogTitle`: "Edit Payment"
- All fields pre-populated from the existing payment record
- Tenant field is always read-only (locked, cannot change which tenant a payment belongs to)
- Submit button label: "Update Payment"
- On success: toast "Payment updated." · close modal · refresh list

No other differences from PY-02.

---

## 5. Delete Payment confirmation (PY-04)

shadcn `AlertDialog`:

```
<AlertDialog open={deleteTarget !== null} onOpenChange={...}>
  <AlertDialogContent>
    <AlertDialogHeader>
      <AlertDialogTitle>Delete this payment record?</AlertDialogTitle>
      <AlertDialogDescription>
        This will remove the payment of <strong>₹{deleteTarget?.amount}</strong> recorded on{" "}
        <strong>{formatDate(deleteTarget?.payment_date)}</strong> for{" "}
        <strong>{deleteTarget?.tenant_name}</strong>.
        <br /><br />
        The tenant's outstanding balance will increase accordingly.
        This action uses a soft delete — the record is archived in the audit trail and
        can be reviewed but not restored from the UI.
      </AlertDialogDescription>
    </AlertDialogHeader>
    <AlertDialogFooter>
      <AlertDialogCancel>Cancel</AlertDialogCancel>
      <AlertDialogAction
        className="bg-red-600 hover:bg-red-700 text-white"
        onClick={confirmDelete}>
        Delete
      </AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>
```

On confirm: call `DELETE /api/admin/v1/payments/:id` · toast "Payment deleted." · refresh list + outstanding balance.

---

## 6. Loading & error states (modal-level)

**PY-02 / PY-03 opening (pre-populating tenant list or payment data):**
- While fetching: show `Loader2 animate-spin` centered inside the modal body
- On fetch error: show `Alert variant="destructive"` · "Could not load data. Close and try again."

**PY-02 / PY-03 submit in-flight:**
- Submit button shows spinner + "Recording…" / "Saving…", `disabled`
- Form inputs remain enabled (do not disable the whole form)

---

## 7. Design tokens (payment pages)

| Token | Tailwind | Usage |
|-------|----------|-------|
| Outstanding danger card | `red-50 / red-200 / red-700` | Summary card bg/border/amount |
| Outstanding zero card | `green-50 / green-200 / green-700` | All-clear card |
| Record Payment CTA | `green-700 / green-800` | Primary button |
| Delete action | `red-600 / red-700` | AlertDialog action + dropdown item |

---

## 8. Navigation flow

```
/payments (PY-01)
  ├── tenant name click ──▶ /tenants/:id
  ├── "Record Payment" button ──▶ PY-02 modal (no tenant pre-filled)
  ├── Actions → "Edit" ──▶ PY-03 modal (pre-filled)
  └── Actions → "Delete" ──▶ PY-04 AlertDialog

Dashboard → Actions → "Record Payment" ──▶ PY-02 modal (tenant pre-filled)
/tenants/:id → "Record Payment" button ──▶ PY-02 modal (tenant pre-filled, locked)
/tenants/:id payment history → Actions → "Edit" ──▶ PY-03 modal (pre-filled)
/tenants/:id payment history → Actions → "Delete" ──▶ PY-04 AlertDialog
```
