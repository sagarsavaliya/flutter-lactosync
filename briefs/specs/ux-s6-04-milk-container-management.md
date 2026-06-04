# UX Spec — S6-04: Settings — Milk types + Container types management sections

> Author: UX/UI Designer · Source: Sprint 6 story S6-04 · Date: 2026-06-04
> Implemented by: Flutter Engineer

---

## Flow

```
Settings screen (ListView)
  │
  ├─ … (Farm, Order schedule, Owner — above)
  │
  ├─ [NEW] Milk Types section
  │     ├─ Tap (+) in section header → Add milk type bottom sheet
  │     │     └─ Tap "Save" → loading → success (sheet closes, list refreshes)
  │     │                             → error (snackbar)
  │     ├─ System default row → hide toggle (optimistic, revert on error)
  │     └─ Custom type row → delete icon → Confirmation dialog
  │           └─ Confirm → loading → success (row removed)
  │                                → blocked (snackbar "Type is in use")
  │                                → error (snackbar)
  │
  ├─ [NEW] Container Types section
  │     ├─ Tap (+) in section header → Add container type bottom sheet
  │     │     └─ Tap "Save" → loading → success (sheet closes, list refreshes)
  │     │                             → error (snackbar)
  │     ├─ System default row → hide toggle (optimistic, revert on error)
  │     └─ Custom type row → delete icon → Confirmation dialog
  │           └─ Confirm → loading → success (row removed)
  │                                → blocked (snackbar "Type is in use")
  │                                → error (snackbar)
  │
  └─ WhatsApp sharing section (unchanged — already exists below Products)
```

**Position in Settings screen ListView:**
Insert both new sections after "Milk products" (`settingsProductsSection`) and before "WhatsApp sharing" (`settingsTemplatesSection`). Order: Milk products → Milk Types → Container Types → WhatsApp sharing.

---

## Design tokens

- **Colours:**
  - Primary / accent: `AppColors.primary` (light) / `AppColors.darkPrimary` (dark)
  - Primary faint: `AppColors.primaryFaint` / `AppColors.darkPrimaryFaint`
  - Surface: `AppColors.surface` / `AppColors.darkSurface`
  - Page bg: `AppColors.bg` / `AppColors.darkBg`
  - Ink (primary text): `AppColors.ink` / `AppColors.darkInk`
  - Ink muted (secondary text, labels): `AppColors.inkMuted` / `AppColors.darkInkMuted`
  - Ink faint: `AppColors.inkFaint` / `AppColors.darkInkFaint`
  - Border: `AppColors.border` / `AppColors.darkBorder`
  - Danger: `AppColors.danger` / `AppColors.darkDanger`
  - Success: `AppColors.success` / `AppColors.darkSuccess`
- **Typography:** `AppText.cardTitle`, `AppText.body`, `AppText.label`, `AppText.meta`
- **Spacing:** `AppSpace.xxs`=2, `AppSpace.xs`=4, `AppSpace.sm`=8, `AppSpace.md`=12, `AppSpace.lg`=16, `AppSpace.xl`=24
- **Radii:** `AppRadius.sm`=6, `AppRadius.md`=10, `AppRadius.lg`=14, `AppRadius.pill`=100
- **Widgets:** `AppCard`, `AppButton`, `AppTextField`, `OwnerSectionHeader`, `OwnerSheetTitle`, `OwnerSheetActions`, `AppSoftIconButton`, `showOwnerBottomSheet`, `showAppConfirmDialog`

---

## Screens

### 1. Milk Types section — List view

- **Purpose:** Show all milk types (system defaults + farm-custom), let the owner hide system defaults or delete custom ones, and add new custom types.

- **Layout & components:**
  - `OwnerSectionHeader` with title "Milk types" and trailing `AppSoftIconButton` (icon `Icons.add`, tooltip "Add milk type").
  - `AppSpace.sm` gap.
  - `AppCard` containing the list.
  - Inside the card, each milk type is a `ListTile` with `contentPadding: EdgeInsets.zero`:
    - **title:** type name in `AppText.label`, `AppColors.ink`.
    - **subtitle (system defaults only):** Text "System default" in `AppText.meta`, `AppColors.inkFaint`. Custom types have no subtitle.
    - **trailing (system defaults):** `Switch` (compact) — on/off indicates whether the type is visible on this farm. Active (visible) = switch on; Hidden = switch off. Use `AppCompactSwitch` or equivalent compact switch with `Transform.scale(0.72)`.
    - **trailing (custom types):** `IconButton` with `Icons.delete_outline`, size 20, `AppColors.inkMuted`. Tooltip: "Delete".
  - Each row except the last is followed by a `Divider(height: AppSpace.lg)` inside the column.
  - Card padding is standard `AppCard` padding (`AppSpace.lg` on all sides).

- **States:**

  **Populated — system defaults only (no custom types added yet):**
  - Shows all system defaults (e.g. "Gir Cow", "Cow", "Buffalo"). Each has "System default" subtitle and a hide toggle.
  - No delete icons visible.
  - This is the initial state for a new farm.

  **Populated — system defaults + custom types:**
  - System defaults appear first, each with "System default" subtitle and hide toggle.
  - Custom types appear below, each with a delete icon and no subtitle.
  - Dividers between all rows.

  **Empty (no types at all — edge case if all custom deleted and all system hidden):**
  - Card shows: icon `Icons.water_drop_outlined` centred, then text "No milk types visible. Add a custom type or enable system defaults." in `AppText.body`, `AppColors.inkMuted`. Use `OwnerDashedEmptyCard` pattern (icon centred, message below, dashed border).
  - This state is rare; spec it to avoid blank card.

  **Loading (initial fetch of settings):**
  - Page-level `CircularProgressIndicator` — existing page loading state. No per-section skeleton needed.

  **Error (settings fetch failed):**
  - Page-level "Retry" button — existing error state. No per-section error UI needed.

- **Interactions:**
  - Tapping (+) in section header opens Add milk type sheet (§3).
  - Toggling the hide switch on a system default: optimistic UI — update switch immediately, then call API. On error: revert switch to previous state and show `SnackBar`: "Could not update. Please try again."
  - Tapping delete on a custom type: opens confirmation dialog (§5).

- **Content:**
  - Section header: "Milk types"
  - Add button tooltip: "Add milk type"
  - System default subtitle: "System default"
  - Delete tooltip: "Delete"
  - Empty state message: "No milk types visible. Add a custom type or enable a system default."
  - Hide toggle error snackbar: "Could not update. Please try again."

- **Accessibility:**
  - Switch accessible label: "[type name] — visible" / "[type name] — hidden".
  - Delete icon button accessible label: "Delete [type name]".
  - Minimum tap target: 44×44 px for switches and icon buttons (Flutter `Switch` meets this; `IconButton` default 48×48 px meets this).

---

### 2. Container Types section — List view

- **Purpose:** Show all container types (system defaults + custom), let the owner hide or delete, and add new ones.

- **Layout & components:**
  - `OwnerSectionHeader` with title "Container types" and trailing `AppSoftIconButton` (icon `Icons.add`, tooltip "Add container type").
  - `AppSpace.sm` gap.
  - `AppCard` containing the list.
  - Each row is a `ListTile` with `contentPadding: EdgeInsets.zero`:
    - **title:** material + size joined with " · " (e.g. "Plastic Bag · 1L", "Glass Bottle · 500ml") in `AppText.label`, `AppColors.ink`.
    - **subtitle (system defaults only):** "System default" in `AppText.meta`, `AppColors.inkFaint`.
    - **trailing:** same as Milk Types — `AppCompactSwitch` for system defaults; delete `IconButton` for custom types.
  - Dividers between rows; standard card padding.

- **States:**

  **Populated — system defaults only:**
  - Shows system defaults (e.g. "Glass Bottle · 500ml", "Plastic Bag · 1L"). Each with subtitle + hide toggle.

  **Populated — system defaults + custom:**
  - System defaults first; custom types below with delete icon.

  **Empty:**
  - Use same `OwnerDashedEmptyCard` pattern: icon `Icons.inventory_2_outlined`, message "No container types visible. Add a custom type or enable a system default."

  **Loading / Error:** Page-level — same as Milk Types.

- **Interactions:**
  - Tapping (+) opens Add container type sheet (§4).
  - Hide toggle: same optimistic behaviour as Milk Types.
  - Delete: confirmation dialog (§5), same rules as Milk Types.

- **Content:**
  - Section header: "Container types"
  - Add button tooltip: "Add container type"
  - System default subtitle: "System default"
  - Row format: "[Material] · [Size]" — e.g. "Glass Bottle · 500ml", "Plastic Bag · 1L"
  - Empty state message: "No container types visible. Add a custom type or enable a system default."
  - Hide toggle error snackbar: "Could not update. Please try again."

- **Accessibility:** Same rules as Milk Types section.

---

### 3. Add milk type — bottom sheet

- **Purpose:** Capture a new custom milk type name and save it to this farm.

- **Layout & components:**
  - `showOwnerBottomSheet`.
  - `OwnerSheetTitle` with title "Add milk type".
  - `AppSpace.sm` gap.
  - `AppTextField` — label "Milk type name", hint "e.g. A2 Cow", full width. Auto-focus on open.
  - `AppSpace.md` gap.
  - `OwnerSheetActions` — primaryLabel "Save".

- **States:**

  **Empty form (sheet just opened):**
  - Text field empty.
  - Save button enabled (validation fires only on submit, not inline-as-you-type).

  **Validation error (submit with empty field):**
  - Inline validation message below the field: "Enter milk type name" in `AppText.meta`, `AppColors.danger`. Standard Flutter `InputDecoration.errorText` pattern.
  - Sheet stays open.

  **Save — Loading:**
  - `OwnerSheetActions` with `loading: true`.
  - Text field non-interactive.

  **Save — Success:**
  - Sheet closes.
  - Milk Types list refreshes to include the new type.
  - No snackbar needed (list update is confirmation enough), but a brief `SnackBar` "Milk type added" is acceptable.

  **Save — Error:**
  - Sheet stays open.
  - `SnackBar` with API error message.
  - Field re-enabled; owner can retry or dismiss.

- **Content:**
  - Sheet title: "Add milk type"
  - Field label: "Milk type name"
  - Field hint: "e.g. A2 Cow"
  - Validation: "Enter milk type name"
  - Save button: "Save"
  - Success snackbar (optional): "Milk type added"

- **Accessibility:**
  - Auto-focus `AppTextField` when sheet opens.
  - Error message associated with field via `InputDecoration.errorText`.

---

### 4. Add container type — bottom sheet

- **Purpose:** Capture material + size for a new custom container type.

- **Layout & components:**
  - `showOwnerBottomSheet`.
  - `OwnerSheetTitle` with title "Add container type".
  - `AppSpace.sm` gap.
  - **Material dropdown:** `DropdownButtonFormField<String>` styled to match `AppTextField` (`InputDecoration` with label "Material"). Options:
    - "Glass Bottle" (value: `glass_bottle`)
    - "Plastic Bag" (value: `plastic_bag`)
    - Default selection: none / placeholder "Select material".
  - `AppSpace.sm` gap.
  - `AppTextField` — label "Size", hint "e.g. 1L, 500ml", full width.
  - `AppSpace.md` gap.
  - `OwnerSheetActions` — primaryLabel "Save".

- **States:**

  **Empty form:**
  - Dropdown showing placeholder "Select material".
  - Size field empty.
  - Save button enabled.

  **Validation errors (submit):**
  - Material not selected: dropdown shows error text "Select a material" (via `validator` on `DropdownButtonFormField`).
  - Size empty: field shows "Enter size (e.g. 1L)" in `AppText.meta`, `AppColors.danger` via `InputDecoration.errorText`.
  - Both errors can show simultaneously.
  - Sheet stays open.

  **Save — Loading:**
  - `OwnerSheetActions` with `loading: true`.
  - Dropdown and field non-interactive.

  **Save — Success:**
  - Sheet closes.
  - Container Types list refreshes.
  - `SnackBar` "Container type added" (optional but recommended for this two-field form where the feedback is less self-evident).

  **Save — Error:**
  - Sheet stays open.
  - `SnackBar` with API error message.
  - Controls re-enabled.

- **Content:**
  - Sheet title: "Add container type"
  - Dropdown label: "Material"
  - Dropdown placeholder: "Select material"
  - Dropdown options: "Glass Bottle", "Plastic Bag"
  - Size field label: "Size"
  - Size field hint: "e.g. 1L, 500ml"
  - Material validation: "Select a material"
  - Size validation: "Enter size (e.g. 1L)"
  - Save button: "Save"
  - Success snackbar: "Container type added"

- **Accessibility:**
  - Dropdown has a visible label "Material" for screen readers.
  - Size field auto-focuses after sheet animates in (or focus starts on the dropdown — implementer's discretion, but one of the two fields must be auto-focused).

---

### 5. Delete confirmation dialog (shared pattern — Milk Types and Container Types)

- **Purpose:** Confirm destructive delete before calling the API. Re-use `showAppConfirmDialog` (already in the codebase).

- **Layout & components:**
  - `showAppConfirmDialog` with:
    - `title`: "Delete [type name]?" (e.g. "Delete A2 Cow?")
    - `message`: "Remove this type? This cannot be undone."
    - `confirmLabel`: "Delete"
    - `cancelLabel`: "Cancel"
    - `destructive: true` (confirm button in `AppColors.danger`)

- **States:**

  **Dialog open:**
  - Title + message + Cancel + Delete buttons visible.

  **Confirm tapped — Loading:**
  - Dialog closes immediately.
  - Row enters a deleting state: row itself can show a `LinearProgressIndicator` or simply disappear optimistically. Recommended: optimistic removal from list while API call is in progress.

  **Confirm tapped — Success:**
  - Row permanently removed from list.
  - No snackbar needed (the removal itself is the feedback).

  **Confirm tapped — Blocked (type in use):**
  - Row remains in list (revert if optimistically removed).
  - `SnackBar`: "Cannot delete — this type is used by a product. Update those products first."

  **Confirm tapped — Error (other):**
  - Row remains in list.
  - `SnackBar` with API error message.

  **Cancel tapped:**
  - Dialog closes; no action taken.

- **Content:**
  - Dialog title: "Delete [type name]?"
  - Dialog message: "Remove this type? This cannot be undone."
  - Confirm button: "Delete"
  - Cancel button: "Cancel"
  - Blocked snackbar: "Cannot delete — this type is used by a product. Update those products first."

- **Accessibility:**
  - `showAppConfirmDialog` handles focus trapping within the dialog.
  - Destructive confirm button has sufficient colour contrast (`AppColors.danger` on white ≥ 4.5:1).
  - Escape / back gesture cancels the dialog.

---

## Handoff

```
TO:      Flutter Engineer
STORY:   S6-04 — Settings: Milk types + Container types management sections
DO:      Add two new sub-sections to the Settings screen (after Milk products, before
         WhatsApp sharing) for managing milk types and container types, as defined in
         this spec.
AGAINST: briefs/specs/ux-s6-04-milk-container-management.md
DONE WHEN:
  - Milk Types section renders below Milk products in the Settings ListView
  - Container Types section renders below Milk Types
  - Both sections show system defaults (with "System default" badge + hide toggle) and
    custom types (with delete icon)
  - Hide toggle updates optimistically; reverts on error with snackbar
  - Add sheets for both types open from (+) button in section header
  - Milk type add sheet: single name field, validates on submit, save works
  - Container type add sheet: Material dropdown + Size field, both validate on submit,
    save works
  - Delete confirmation dialog matches showAppConfirmDialog pattern
  - Delete blocked by in-use check shows correct snackbar message
  - Empty state (no types visible) renders OwnerDashedEmptyCard pattern
  - All design tokens (AppColors, AppText, AppSpace, AppRadius) used; no hard-coded values
  - All states in this spec implemented (no missing states)
```
