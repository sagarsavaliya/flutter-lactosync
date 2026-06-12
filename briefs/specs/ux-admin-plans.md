# UX Spec — Plan Management (T1-05)

> Author: UX/UI Designer · Story: T1-05 · Date: 2026-06-05
> Consumed by: React Engineer (T1-16)
> Against: `briefs/requirements/tenant-admin-webapp.md` FR-19–FR-22
> Shell layout: see `briefs/specs/ux-admin-dashboard.md` §1

---

## 1. Screen inventory

| ID | Screen | Route |
|----|--------|-------|
| PL-01 | Plan list | `/plans` |
| PL-02 | Create plan | `/plans/new` (or wide `Sheet` over `/plans`) |
| PL-03 | Edit plan | `/plans/:id/edit` (or wide `Sheet` over `/plans`) |
| PL-04 | Archive confirmation | `AlertDialog` overlay on PL-01 |

Implementation note for the React Engineer: PL-02 and PL-03 may be implemented as a `Sheet` (slide-over panel) anchored to the right side of PL-01, rather than navigating to a new route. Either approach is acceptable; the UX spec describes the form content, not the routing mechanism. The sheet approach (`Sheet` from shadcn) is preferred for a smoother in-context experience.

---

## 2. Plan list page (PL-01)

### 2.1 Topbar
Page title: "Plans"

### 2.2 Header row

```
<div className="flex items-center justify-between mb-4">
  <div>
    <h2 className="text-base font-semibold text-gray-800">Subscription Plans</h2>
    <p className="text-xs text-gray-400 mt-0.5">
      {activePlanCount} active · {archivedPlanCount} archived
    </p>
  </div>
  <Button className="bg-green-700 hover:bg-green-800 text-white"
    onClick={() => openPlanForm('create')}>
    <Plus className="w-4 h-4 mr-1.5" /> New Plan
  </Button>
</div>
```

### 2.3 Plan table

shadcn `Table`:

| Column | Width hint | Notes |
|--------|-----------|-------|
| Name | auto | `font-medium text-gray-800` |
| Description | auto | `text-sm text-gray-400 truncate max-w-xs` |
| Price | 100px | `₹{price}` |
| Billing Cycle | 120px | Capitalised label (Monthly, Quarterly, etc.) |
| Max Customers | 100px | right-aligned number |
| Max Subscriptions | 120px | right-aligned number |
| Status | 100px | `Badge` (see below) |
| Tenants | 80px | count of active assignments (link to filtered `/tenants?plan={id}`) |
| Actions | 80px | icon buttons (see below) |

**Status badge:**

| State | Tailwind | Text |
|-------|----------|------|
| Active | `bg-green-100 text-green-800 border-green-200` | "Active" |
| Archived | `bg-gray-100 text-gray-500 border-gray-200` | "Archived" |

**Archived plan row treatment:**
- `className="opacity-50"` on the entire `<TableRow>`
- Actions column: only "Unarchive" action available (no Edit)
- Row `title` attribute or `Tooltip`: "This plan is archived and cannot be assigned to new tenants."

**Actions column:**

For an **active** plan:
```
<div className="flex items-center gap-1">
  <Tooltip content="Edit plan">
    <Button variant="ghost" size="icon" onClick={() => openPlanForm('edit', plan)}>
      <Pencil className="w-4 h-4" />
    </Button>
  </Tooltip>
  <Tooltip content="Archive plan">
    <Button variant="ghost" size="icon"
      className="text-red-400 hover:text-red-600 hover:bg-red-50"
      onClick={() => openArchiveDialog(plan)}>
      <Archive className="w-4 h-4" />
    </Button>
  </Tooltip>
</div>
```

For an **archived** plan:
```
<Tooltip content="Unarchive plan">
  <Button variant="ghost" size="icon"
    className="text-gray-400 hover:text-gray-700"
    onClick={() => unarchivePlan(plan.id)}>
    <ArchiveRestore className="w-4 h-4" />
  </Button>
</Tooltip>
```

### 2.4 Loading state
5 skeleton rows matching the column structure.

### 2.5 Empty state
```
<div className="flex flex-col items-center py-16 text-center">
  <CreditCard className="w-12 h-12 text-gray-200 mb-3" />
  <p className="text-sm font-medium text-gray-500">No plans yet</p>
  <p className="text-xs text-gray-400 mt-1">Create your first plan to start assigning it to tenants.</p>
  <Button size="sm" className="mt-4 bg-green-700 hover:bg-green-800 text-white"
    onClick={() => openPlanForm('create')}>
    <Plus className="w-4 h-4 mr-1" /> New Plan
  </Button>
</div>
```

### 2.6 Error state
`Alert variant="destructive"` · "Failed to load plans. Try again."

---

## 3. Create plan form (PL-02) / Edit plan form (PL-03)

### 3.1 Sheet container

```
<Sheet open={open} onOpenChange={setOpen}>
  <SheetContent className="w-[480px] sm:max-w-[480px] overflow-y-auto">
    <SheetHeader>
      <SheetTitle>{mode === 'create' ? 'New Plan' : 'Edit Plan'}</SheetTitle>
      <SheetDescription>
        {mode === 'create'
          ? 'Define a new subscription plan.'
          : 'Update this plan\'s details.'}
      </SheetDescription>
    </SheetHeader>

    <form onSubmit={handleSubmit} className="space-y-5 mt-6">
      {/* fields — see below */}
      <SheetFooter className="mt-6 flex gap-2 justify-end">
        <Button type="button" variant="outline" onClick={close}>Cancel</Button>
        <Button type="submit" className="bg-green-700 hover:bg-green-800 text-white">
          {mode === 'create' ? 'Create Plan' : 'Save Changes'}
        </Button>
      </SheetFooter>
    </form>
  </SheetContent>
</Sheet>
```

### 3.2 Form fields

#### Plan Name (required)
```
<div>
  <Label htmlFor="name">Plan Name <span className="text-red-500">*</span></Label>
  <Input id="name" placeholder="e.g. Starter, Growth, Pro" required />
</div>
```

#### Description (optional)
```
<div>
  <Label htmlFor="description">Description</Label>
  <Textarea id="description" placeholder="Brief description of this plan"
    rows={2} className="resize-none" />
</div>
```

#### Price (required)
```
<div>
  <Label htmlFor="price">Price <span className="text-red-500">*</span></Label>
  <div className="relative">
    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">₹</span>
    <Input id="price" type="number" min="0" step="1" placeholder="0"
      className="pl-7"
      disabled={isEditWithActiveAssignments}
      required />
  </div>
  {isEditWithActiveAssignments && (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <p className="text-xs text-amber-600 mt-1 flex items-center gap-1 cursor-help">
            <Lock className="w-3 h-3" /> Cannot change while this plan has active tenants
          </p>
        </TooltipTrigger>
        <TooltipContent>
          <p>Price is locked to protect tenants on active assignments.
             Archive this plan and create a new one to change the price.</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  )}
</div>
```

#### Billing Cycle (required)
```
<div>
  <Label>Billing Cycle <span className="text-red-500">*</span></Label>
  <Select required defaultValue="monthly">
    <SelectTrigger>
      <SelectValue />
    </SelectTrigger>
    <SelectContent>
      <SelectItem value="monthly">Monthly</SelectItem>
      <SelectItem value="quarterly">Quarterly (3 months)</SelectItem>
      <SelectItem value="half_yearly">Half-Yearly (6 months)</SelectItem>
      <SelectItem value="yearly">Yearly (12 months)</SelectItem>
    </SelectContent>
  </Select>
</div>
```

#### Max Customers (required)
```
<div>
  <Label htmlFor="max_customers">
    Max Customers <span className="text-red-500">*</span>
  </Label>
  <Input id="max_customers" type="number" min="1" placeholder="e.g. 50"
    disabled={isEditWithActiveAssignments}
    required />
  {isEditWithActiveAssignments && <LockedHint />}  {/* same lock hint as Price */}
</div>
```

#### Max Subscriptions (required)
```
<div>
  <Label htmlFor="max_subscriptions">
    Max Subscriptions <span className="text-red-500">*</span>
  </Label>
  <Input id="max_subscriptions" type="number" min="1" placeholder="e.g. 100"
    disabled={isEditWithActiveAssignments}
    required />
  {isEditWithActiveAssignments && <LockedHint />}
</div>
```

**`isEditWithActiveAssignments`** = mode is 'edit' AND `plan.active_tenant_count > 0`

When this flag is true, the fields for Price, Max Customers, Max Subscriptions render `disabled` and show the lock hint. Name and Description remain editable in all cases.

**`LockedHint` component (reusable small element):**
```
function LockedHint() {
  return (
    <p className="text-xs text-amber-600 mt-1 flex items-center gap-1">
      <Lock className="w-3 h-3" />
      Cannot change while this plan has active tenants
    </p>
  )
}
```

### 3.3 Validation errors (inline)

- Required field left empty: red border on input + `<p className="text-xs text-red-500 mt-1">This field is required.</p>`
- Price ≤ 0: "Price must be greater than 0."
- Max Customers ≤ 0: "Must be at least 1."
- Duplicate plan name (API 422): toast `toast.error("A plan with this name already exists.")`

### 3.4 Submit states

- Submitting: button shows `Loader2 animate-spin` + text "Saving…", `disabled`
- On success (create): toast "Plan created." · close sheet · table refreshes with new row highlighted briefly (`bg-green-50` fading out)
- On success (edit): toast "Plan updated." · close sheet · row updates in place
- On API error: `Alert variant="destructive"` inside the sheet above the footer

---

## 4. Archive confirmation (PL-04)

shadcn `AlertDialog`:

```
<AlertDialog open={archiveTarget !== null} onOpenChange={...}>
  <AlertDialogContent>
    <AlertDialogHeader>
      <AlertDialogTitle>Archive this plan?</AlertDialogTitle>
      <AlertDialogDescription>
        <strong>{archiveTarget?.name}</strong> will be archived.
        Tenants currently on this plan keep their assignment until renewal.
        No new tenants can be assigned this plan after archiving.
      </AlertDialogDescription>
    </AlertDialogHeader>

    {archiveTarget?.active_tenant_count > 0 && (
      <Alert className="border-amber-300 bg-amber-50 my-2">
        <AlertCircle className="h-4 w-4 text-amber-600" />
        <AlertDescription className="text-amber-800 text-sm">
          {archiveTarget.active_tenant_count} tenant(s) are currently on this plan.
          They will remain unaffected until their renewal date.
        </AlertDescription>
      </Alert>
    )}

    <AlertDialogFooter>
      <AlertDialogCancel>Cancel</AlertDialogCancel>
      <AlertDialogAction
        className="bg-red-600 hover:bg-red-700 text-white"
        onClick={confirmArchive}>
        Archive Plan
      </AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>
```

On confirm: call `PATCH /api/admin/v1/plans/:id/archive` · show toast "Plan archived." · row gains "Archived" badge + `opacity-50`.

---

## 5. Design tokens (plans pages)

| Token | Tailwind | Usage |
|-------|----------|-------|
| Archived row opacity | `opacity-50` | Archived table row |
| Archived badge | `gray-100 / gray-500` | Badge for archived state |
| Lock hint text | `amber-600` | Disabled-field explanation |
| Archive confirm | `red-600 / red-700` | AlertDialog destructive action |
| New plan CTA | `green-700 / green-800` | "New Plan" button |

---

## 6. Navigation flow

```
/plans (PL-01)
  ├── "New Plan" button ──▶ opens create Sheet (PL-02)
  ├── Edit icon ──▶ opens edit Sheet (PL-03) pre-filled with plan data
  ├── Archive icon ──▶ opens archive AlertDialog (PL-04)
  └── Tenant count link ──▶ /tenants?plan={id}  (filtered tenant list)
```
