# UX Spec — Sprint OR: Owner App Redesign

> **Author:** UX/UI Designer
> **Date:** 2026-06-07
> **Source PRD:** `briefs/requirements/sprint-owner-redesign.md`
> **Blocks:** All OR Flutter stories
> **Design token source:** `briefs/specs/ux-customer-app.md` (§ Design Language Reference) — all colour, spacing, typography, and component rules apply unchanged to the owner app.

---

## Design Language Quick Reference

All screens use the established owner-app design system. Key tokens repeated here for quick lookup:

- **Spacing:** `AppSpace.xs = 4`, `sm = 8`, `md = 16`, `lg = 24`, `xl = 32`
- **Typography:** `AppText.screenTitle`, `sectionTitle`, `cardTitle`, `body`, `label`, `meta` — never hardcode sizes
- **Colours:** `AppColors.primary`, `inkMuted`, `inkFaint`, `ink`, `surface`, `bg`, `border`, `danger`, `dangerFaint`
- **Components:** `AppCard` (elevation 0, `border` side, `BorderRadius.circular(12)`), `AppTextField` (filled, surface fill, content padding `horizontal: 16, vertical: 11`), elevated button height 48 dp
- **Page padding:** `EdgeInsets.all(AppSpace.lg)` throughout

---

## Screen 1 — Product Creation Form (Owner Settings → Products → Add Product)

**Entry point:** FAB or "Add Product" button on the Products list (described in Screen 2). Opens as a full-screen push or a tall bottom sheet — Flutter Engineer chooses whichever accommodates the size checkbox group without clipping. If implemented as a bottom sheet it must be `isScrollControlled: true` with keyboard inset padding.

### Layout

`Column(crossAxisAlignment: CrossAxisAlignment.stretch)` inside a scrollable container, padded `AppSpace.md` on all sides. Fields appear in this fixed order:

1. **Milk type dropdown** — full-width `AppTextField`-styled `DropdownButtonFormField`. Label: "Milk type". Hint text: "Select milk type". Populated from the farm's visible milk types. Required — shows "Select a milk type" error text if empty on save.

2. **Container type dropdown** — full-width `AppTextField`-styled `DropdownButtonFormField`. Label: "Container type". Hint text: "Select container type". Populated from the farm's visible container types. Each dropdown item displays the container type name as primary text, with a secondary line rendered as `AppText.meta` in `inkMuted` colour: "Available in X, Y" (comma-joined sizes from `container_type_sizes` for that container type, formatted as "0.5 L", "1 L", etc.). When a container type is selected, the same hint appears as a subtitle directly below the dropdown field — a `Text` widget: "Available in {sizes}" styled `AppText.meta`, `color: inkMuted`. This subtitle is absent until a selection is made. Selecting a new container type refreshes the sizes below and clears any existing size checkboxes. Required.

3. **Container sizes — checkbox group** — appears below the container type dropdown only after a container type is selected. Section label: `Text("Sizes offered", style: AppText.label)`. Below the label, one `CheckboxListTile` per size in the selected container type's `container_type_sizes`, ordered ascending. Each tile:
   - `title: Text("{display_label}", style: AppText.body)` (e.g. "0.5 L", "1 L")
   - `contentPadding: EdgeInsets.zero`
   - `controlAffinity: ListTileControlAffinity.leading`
   - Checkbox uses `primary` colour when checked.
   At least one size must be checked. If Save is tapped with none checked, show inline error text below the group: "Select at least one size."

4. **Rate per litre input** — full-width `AppTextField`. Label: "Rate (₹/ltr)". `keyboardType: TextInputType.numberWithOptions(decimal: true)`. `inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]`. Required. Error: "Enter a rate" if empty on save.

5. **Product name preview card** — rendered below all four inputs, visible as soon as both milk type and rate have values. Updates in real time as either field changes. Layout: `AppCard` with `Padding(AppSpace.md)` containing a `Column`:
   - `Text("Product name", style: AppText.meta, color: inkMuted)` — caption label
   - `SizedBox(AppSpace.xs)`
   - `Text("{MilkTypeName} - ₹{rate}", style: AppText.body.copyWith(fontWeight: FontWeight.w500))`
   Background: `AppColors.bg` (muted surface — slightly off the card default). Use `AppCard` with a `color: AppColors.bg` override or a `Container` with `AppColors.bg` fill and the same border radius. While either field is empty, the card is absent (not rendered as a placeholder).

6. **Save button** — full-width elevated, height 48 dp, label "Save product". Loading state (spinner replaces label) while API call is in-flight. Disabled during loading.

### States

- **Loading (initial):** Show `CircularProgressIndicator` centred in body while milk types and container types are fetching.
- **Error (initial load):** Full-page error state with Retry.
- **Save success:** Close form, refresh product list, show snackbar "Product added."
- **Save HTTP 422:** Show inline `errorText` on the offending field, or a red snackbar for non-field errors.

### Interaction notes

- Milk type and container type dropdowns are independent — changing one does not clear the other.
- Changing container type clears all checked sizes (they are no longer valid for the new container type).
- Rate field accepts decimals. Preview formats the rate exactly as entered (no rounding in preview).

---

## Screen 2 — Product List (Owner Settings → Products)

**Location:** A section within the existing Owner Settings page, or a navigated sub-page. Matches the pattern of other Settings sections.

### Layout

Section header: `Text("Products", style: AppText.sectionTitle)` + `SizedBox(AppSpace.sm)`.

`AppCard` containing a `Column` of product rows separated by `Divider(height: 1)`. Each row is a `ListTile`:

- **Primary (`title`):** `Text("{MilkTypeName} - ₹{rate}", style: AppText.label)` — the auto-generated product name. Example: "Gir Cow Milk - ₹80".
- **Secondary (`subtitle`):** `Text("{MilkType} · {ContainerType} · {Sizes} · ₹{rate}/ltr", style: AppText.meta, color: inkMuted)`. Example: "Gir Cow Milk · Glass Bottle · 0.5 L, 1 L · ₹80/ltr". Sizes are comma-joined from `product_offered_sizes`.
- **Trailing:** `IconButton(icon: Icon(Icons.delete_outline, color: AppColors.danger), onPressed: _confirmDelete)`. Alternatively, swipe-to-delete is supported as a supplement (not a replacement) — a `Dismissible` widget wrapping the tile with `direction: DismissDirection.endToStart` and a red background with a trash icon.

### Delete confirmation

On trailing icon tap (or after swipe completes): show an `AlertDialog`:
- Title: "Remove product?"
- Content: `Text("\"${productName}\" will be removed from your catalog.", style: AppText.body)`
- Actions: `TextButton("Cancel")` + `TextButton("Remove", style: TextButton.styleFrom(foregroundColor: AppColors.danger))`
- Confirm → API delete call → remove row from list + snackbar "Product removed."
- API error → red snackbar with API `message`.

### "Add Product" control

Place a `TextButton.icon(icon: Icon(Icons.add), label: Text("Add product"))` below the `AppCard` (or an `OutlinedButton` matching the owner app's "add" pattern). On tap: open the Product Creation Form (Screen 1).

If the product list is empty, show an empty-state row inside the `AppCard`: `ListTile(title: Text("No products yet", style: AppText.body, color: inkMuted))`. The "Add product" button remains visible in either state.

---

## Screen 3 — Container Types (Owner Settings → Container Types)

**Location:** A section within Owner Settings, replacing the existing flat container size list.

### Layout

Section header: `Text("Container types", style: AppText.sectionTitle)` + `SizedBox(AppSpace.sm)`.

The list renders one `AppCard` per container type. Cards are separated by `SizedBox(AppSpace.sm)`. Within each card:

```
┌─────────────────────────────────────────┐
│  Glass Bottle                [System]   │  ← name + badge row
│                                         │
│  [0.5 L]  [1 L]                        │  ← size chips
└─────────────────────────────────────────┘
```

**Card internal layout:** `Padding(AppSpace.md)` wrapping a `Column(crossAxisAlignment: CrossAxisAlignment.start)`:

1. `Row(children: [Expanded(child: Text(name, style: AppText.cardTitle)), if(isSystem) _SystemBadge(), if(!isSystem) _DeleteButton()])`
2. `SizedBox(AppSpace.sm)`
3. `Wrap(spacing: AppSpace.xs, runSpacing: AppSpace.xs, children: [for each size: _SizeChip(label)])` — chip row.

**`_SystemBadge`:** A small pill `Container` with `AppColors.inkFaint` fill and a `Row([Icon(Icons.lock_outline, size: 12, color: AppColors.inkMuted), SizedBox(2), Text("System", style: AppText.meta.copyWith(fontSize: smaller), color: AppColors.inkMuted)])`. Same pill decoration as status badges in the customer spec (horizontal padding `AppSpace.sm`, vertical padding 2, `BorderRadius.circular` pill).

**`_DeleteButton`:** `IconButton(icon: Icon(Icons.delete_outline, color: AppColors.danger), onPressed: _confirmDelete)`. Alternatively a `Dismissible` wrapping the entire card (swipe left). System defaults have neither delete icon nor Dismissible — they are locked. Swipe on a system card does nothing (no `Dismissible` wrapper).

**`_SizeChip`:** Small read-only chip. Use `Chip(label: Text(label, style: AppText.meta), backgroundColor: AppColors.primaryFaint, side: BorderSide.none, padding: EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 2))`. Label examples: "0.5 L", "1 L". Chips are display-only — not tappable.

### Delete confirmation (farm-custom containers only)

`AlertDialog`:
- Title: "Remove container type?"
- Content: `Text("\"${name}\" will be removed. Products using this container type will be affected.", style: AppText.body)`.
- Actions: `TextButton("Cancel")` + `TextButton("Remove", style: TextButton.styleFrom(foregroundColor: AppColors.danger))`.
- Confirm → API delete → remove card + snackbar "Container type removed."
- API error → red snackbar.

### "Add container type" bottom sheet

`TextButton.icon(icon: Icon(Icons.add), label: Text("Add container type"))` below the card list. On tap: `showModalBottomSheet(isScrollControlled: true, ...)`.

Sheet layout (standard sheet padding with keyboard inset):

```
≡  (drag handle — from theme)

Add container type                        ← AppText.sectionTitle

Name
┌────────────────────────────────────┐
│  e.g. Stainless Steel Pot          │   ← AppTextField, label "Name"
└────────────────────────────────────┘

Sizes
[ 0.5 L ] [ 1 L ] [ + Add size ]         ← chips + tap-to-add

┌────────────────────────────────────┐
│             Save                   │   ← primary elevated button
└────────────────────────────────────┘
```

**Name field:** `AppTextField`, label "Name", hint "e.g. Stainless Steel Pot". Required — error "Enter a name" if empty on save.

**Size chip builder:**

- Existing sizes appear as `ActionChip`-style chips: `Chip(label: Text("{label}"), onDeleted: _removeSize, deleteIcon: Icon(Icons.close, size: 14))`. Background `AppColors.primaryFaint`.
- An `ActionChip(label: Text("+ Add size"), backgroundColor: AppColors.surface, side: BorderSide(color: AppColors.border))` is always present as the last chip.
- Tapping "+ Add size" opens a small `AlertDialog` with a single `AppTextField` (label "Size (litres)", e.g. "0.5"). Accept decimal values. Validate: must be a positive decimal number. On confirm: format the value as a display label (values < 1 L → "{value × 1000} ml", e.g. "500 ml"; values ≥ 1 L → "{value} L", e.g. "1.5 L") and add as a chip. Duplicate values are silently ignored.
- Minimum 1 size must be added. Error: "Add at least one size" shown below the chip row if Save is tapped with no sizes.

**Save button:** Full-width elevated. Loading state on tap. On success: close sheet + refresh container type list + snackbar "Container type added." On 422: show inline error or red snackbar with API `message`.

### Empty state

If no container types are visible (all system defaults have been hidden and no farm-custom ones exist): `Text("No container types configured.", style: AppText.body, color: inkMuted)` inside an `AppCard`. The "Add container type" button is always visible.

---

## Screen 4 — Subscription Form (Create/Edit Subscription)

**Applies to:** New subscription creation from Customer Detail, and subscription edit sheet. Both flows use the same field layout.

### Field order and spec

1. **Product dropdown** — full-width `AppTextField`-styled `DropdownButtonFormField`. Label: "Product". Each item shows the auto-generated product name as primary text (e.g. "Gir Cow Milk - ₹80"), with a secondary line (in `AppText.meta`, `inkMuted`) showing the container type name (e.g. "Glass Bottle"). Required.

2. **Container size dropdown** — full-width `AppTextField`-styled `DropdownButtonFormField`. Label: "Container size". Populated from the selected product's `product_offered_sizes`, formatted as display labels (e.g. "0.5 L", "1 L"). This dropdown is disabled (greyed out with `enabled: false`) until a product is selected. When the product selection changes, this field resets to null. Required.

3. **Qty dropdown** — full-width `AppTextField`-styled `DropdownButtonFormField`. Label: "Qty (ltr)". Populated from the `milk_quantities` API/provider (20 values: 0.5–10 L, `display_label` from DB). Example items: "500 ml", "1 L", "1.5 L", …, "10 L". Required. No free-form input — dropdown only.

4. **Shift segmented control / toggle** — Label `Text("Shift", style: AppText.label)` above the control. Two options: "Morning" and "Evening". Implement as a `SegmentedButton<String>` (Material 3) or two `OutlinedButton` siblings in a `Row`, toggling selection. Selected segment: `primary` fill + white text. Unselected: `surface` fill + `ink` text + `border` side. Both options always visible, equal width. Required — one must always be selected (default to "Morning" on create).

5. **Discount field** (if present in the current form) — `AppTextField`, label "Discount (₹)". Must be the same height as all other `AppTextField` instances in this form. See Screen 8 / Input Consistency Rules.

6. **Customer picker** (when pre-selected from post-creation flow, B-02): rendered as a read-only `AppTextField` with `enabled: false`. Label: "Customer". Value: the pre-selected customer's name. No dropdown — not changeable in this flow invocation. Only shown when a customer is pre-selected; hidden when the owner opens the subscription form from the general subscriptions list (where they pick the customer themselves).

### Save behaviour

Full-width elevated button, label "Save" (or "Add subscription" / "Save changes"). Loading state while API call in-flight. On success: close sheet + refresh. On 422: inline `errorText` on offending field or red snackbar.

---

## Screen 5 — Daily Orders — Qty Adjustment

**Location:** Existing bottom sheet (or inline control) that opens when the owner adjusts an order's quantity for a specific day.

### Change

Replace the existing stepper or limited range picker with a **dropdown**, using the same `milk_quantities` list as Screen 4.

### Bottom sheet layout (existing sheet, modified)

The sheet retains its current structure. The qty control changes as follows:

**Before (old):** A `+` / `−` stepper with a limited range.

**After (new):** A full-width `AppTextField`-styled `DropdownButtonFormField`. Label: "Qty (ltr)". Items: all 20 values from `milk_quantities` (500 ml … 10 L). The current order quantity is pre-selected when the sheet opens. Required.

No other structural changes to the sheet. The Save button and all other rows remain unchanged.

---

## Screen 6 — Sign-In Screen — Customer Entry Point (B-01)

**Location:** `sign_in_page.dart` — the existing owner sign-in screen.

### Change

Add a single `TextButton` at the very bottom of the scrollable column content — below the primary "Sign in" button and any existing secondary links.

**Position:** Last item in the `Column` within `SingleChildScrollView`. Separated from the element above by `SizedBox(AppSpace.sm)`.

**Widget spec:**

```
Center(
  child: TextButton(
    onPressed: () => context.push('/customer/login'),
    style: TextButton.styleFrom(
      foregroundColor: AppColors.inkMuted,
    ),
    child: Text(
      "Customer? Sign in here",
      style: AppText.label,   // or AppText.meta — whichever matches body/label size
    ),
  ),
)
```

**Styling rules:**
- Text colour: `AppColors.inkMuted` — intentionally muted, not `primary`. The link is discoverable, not prominent.
- Font: `AppText.label` or `AppText.meta` (Flutter Engineer picks whichever sits at body/label scale for the existing page). Do not use `AppText.screenTitle` or `AppText.sectionTitle`.
- No underline, no icon. Plain text button.
- Navigation: `context.push('/customer/login')` — pushes onto the owner nav stack, so back arrow returns to owner sign-in.

**No other changes** to the sign-in screen layout, fields, or buttons.

---

## Screen 7 — Owner Settings — Farm Address Prefill Toggle

**Location:** Inside the existing Farm Details section of the Owner Settings page.

### Change

Add one new row to the Farm Details section. The row is placed after the existing farm address fields (city / state / ZIP) and before the section ends.

### Row spec

```
AppCard → Column [
  ...existing farm detail rows...,
  Divider(height: 1),
  SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      "Pre-fill customer address from farm",
      style: AppText.body,
    ),
    value: prefillCustomerAddress,
    onChanged: _onPrefillToggle,
  ),
  SizedBox(AppSpace.xs),
  Padding(
    padding: EdgeInsets.only(left: AppSpace.md, right: AppSpace.md, bottom: AppSpace.sm),
    child: Row([
      Icon(Icons.info_outline, size: 14, color: AppColors.inkMuted),
      SizedBox(AppSpace.xs),
      Expanded(
        child: Text(
          "When on, city, state and PIN code will be pre-filled from your farm address when adding a new customer.",
          style: AppText.meta,
          color: AppColors.inkMuted,
        ),
      ),
    ]),
  ),
]
```

**Hint text visibility:** The muted hint paragraph is **always visible** below the toggle — not conditional on the toggle state. This ensures the owner can read the explanation before enabling it.

**Toggle behaviour:** Optimistic update (matches the existing WhatsApp toggle pattern in Owner Settings). On toggle change: flip local state immediately → `PATCH /api/v1/owner/settings` (or the appropriate settings endpoint — confirm with Laravel Engineer) with `{ prefill_customer_address: newValue }`. On API error: revert to original value + red snackbar "Failed to save setting."

**No separate Save button** for this row — it saves on toggle change, consistent with all other toggle rows in Owner Settings.

---

## Screen 8 — Input Consistency Rules (applies across all forms)

These rules are enforced globally across every form in the owner app. They are not a screen but a cross-cutting constraint the Flutter Engineer must apply to all form layouts.

### Rule 1 — Uniform field height

Every `AppTextField` (and every `DropdownButtonFormField` that uses `AppTextField` decoration) within the same form must occupy the same vertical extent. The `AppTextField` component's `InputDecoration` already enforces `contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11)`. No field in any form may use a different `contentPadding` or an `isDense` override that changes its visual height relative to siblings.

**Specifically:** The discount field in the subscription form (if it has historically had different padding or a suffix widget that inflates its height) must be brought in line with the adjacent fields. Remove any suffix widget that increases the field's height. If a unit label is needed, it belongs in the field's `labelText` only.

### Rule 2 — Unit suffixes in labels only

Unit strings ("ltr", "₹", "L", "ml") must appear **only in the field label** — never inside the input box as `suffixText`, `suffix`, `prefixText`, `prefix`, or hint text. Correct examples:

| Field | Label | Input value |
|---|---|---|
| Quantity | "Qty (ltr)" | "1.5" (just the number) |
| Rate | "Rate (₹/ltr)" | "80" (just the number) |
| Discount | "Discount (₹)" | "10" (just the number) |
| Container size | "Container size" | "0.5 L" (display label from dropdown — no extra suffix) |

**Never:** `suffixText: "ltr"`, `hintText: "e.g. 1 ltr"`, or any text that places a unit inside the typed area.

### Rule 3 — Dropdown fields match text field height

`DropdownButtonFormField` instances use the same `InputDecoration` as `AppTextField` (same fill, same padding, same border, same label style). The dropdown arrow icon must not inflate the field height. Use `isDense: false` and ensure `contentPadding` matches `AppTextField`'s value.

### Rule 4 — No hardcoded heights on individual fields

Do not wrap any individual form field in a `SizedBox(height: ...)` constraint. Height uniformity is achieved through consistent `InputDecoration` configuration, not by constraining individual widgets.

---

## Appendix A — Affected Screens Summary

| Screen / Location | Change type | PRD ref |
|---|---|---|
| Owner Settings → Container Types | Redesign — grouped cards with size chips + custom add sheet | §3 |
| Owner Settings → Products | Redesign — list tile with secondary line; new creation form | §5 |
| Onboarding → Product Setup | Update product creation form to match Screen 1 above | §5 |
| Subscription form (create + edit) | Product dropdown; container size dropdown; qty dropdown; shift toggle | §6, §7 |
| Daily Orders → qty picker | Replace stepper with qty dropdown | §7 |
| Sign-in screen | "Customer? Sign in here" TextButton at bottom | B-01 |
| Owner Settings → Farm section | Prefill toggle + hint text | §8 |
| All forms | Uniform field height; unit in label only | B-03, B-04 |

---

## Appendix B — Component Decision Notes

1. **Dropdown for qty vs. stepper:** The PRD mandates dropdown for all qty inputs. Do not retain the stepper anywhere. If the stepper is in a reusable widget, replace the widget at call sites.

2. **Segmented control for Shift:** Material 3 `SegmentedButton` is preferred. If the project's Flutter/Material version does not support it, use two equal-width `OutlinedButton` widgets in a `Row` with a shared border-box visual. Both options always visible simultaneously.

3. **Product name preview:** The preview card is driven by local form state — no API call needed. Render it purely from the current `milkTypeDropdownValue` and `rateFieldValue` strings.

4. **Size checkboxes vs. multi-select dropdown:** Checkboxes are specified because the number of sizes per container type is small (≤ 6). A multi-select dropdown would require extra interaction steps. If more than 6 sizes appear for a custom container type, the checkbox list simply scrolls within the form's `SingleChildScrollView`.

5. **Container type dropdown hint / subtitle:** The subtitle "Available in X, Y" is a `Text` widget rendered below the `DropdownButtonFormField` itself — it is not inside the dropdown field's `InputDecoration`. This avoids inflating the field height.
