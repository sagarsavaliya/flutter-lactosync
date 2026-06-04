# UX Spec — S6-03: Settings — Farm profile card + Owner profile card redesign

> Author: UX/UI Designer · Source: Sprint 6 story S6-03 · Date: 2026-06-04
> Implemented by: Flutter Engineer

---

## Flow

```
Settings screen (ListView)
  │
  ├─ Farm profile card (read view)
  │     └─ Tap pencil icon → Farm edit bottom sheet
  │           ├─ ZIP field onChange (6 digits) → Pincode lookup API
  │           │     ├─ Loading → spinner on City / State fields
  │           │     ├─ Success → City + State auto-populated
  │           │     └─ Error → inline "Pincode not found" message
  │           └─ Tap "Save changes" → loading → success (sheet closes + snackbar)
  │                                           → error (snackbar with message)
  │
  ├─ Daily order schedule card (unchanged — ListTile rows, 12 hr time display)
  │
  └─ Owner profile card (read view)
        └─ Tap pencil icon → Owner edit bottom sheet
              └─ Tap "Save changes" → loading → success (sheet closes + snackbar)
                                              → error (snackbar with message)
```

---

## Design tokens

- **Colours:**
  - Primary / accent: `AppColors.primary` (#386948 light · #4DB89A dark)
  - Primary faint (chip fill): `AppColors.primaryFaint`
  - Surface (card background): `AppColors.surface`
  - Page background: `AppColors.bg`
  - Default text: `AppColors.ink`
  - Secondary / muted text: `AppColors.inkMuted`
  - Faint text (read-only labels): `AppColors.inkFaint`
  - Border: `AppColors.border`
  - Danger: `AppColors.danger`
  - Success: `AppColors.success`
  - Dark variants: corresponding `AppColors.dark*` tokens
- **Typography:** `AppText.screenTitle`, `AppText.cardTitle`, `AppText.body`, `AppText.label`, `AppText.meta`
- **Spacing:** `AppSpace.xxs`=2, `AppSpace.xs`=4, `AppSpace.sm`=8, `AppSpace.md`=12, `AppSpace.lg`=16, `AppSpace.xl`=24, `AppSpace.xxl`=32
- **Radii:** `AppRadius.sm`=6, `AppRadius.md`=10, `AppRadius.lg`=14
- **Widgets (pre-built, use as-is):** `AppCard`, `AppButton`, `AppTextField`, `OwnerSectionHeader`, `OwnerSheetTitle`, `OwnerSheetActions`, `AppSoftIconButton`, `showOwnerBottomSheet`

---

## Screens

### 1. Settings screen — Farm profile card (read view)

- **Purpose:** Show farm details at a glance; entry point to the farm edit sheet.

- **Layout & components:**
  - `OwnerSectionHeader` with title "Dairy farm" — no change to existing section header.
  - `AppSpace.sm` gap below header.
  - `AppCard` containing:
    - **Header row inside card** (not section header — this is within the card):
      - Left: farm name in `AppText.cardTitle`, `AppColors.ink`
      - Right: `AppSoftIconButton` with `Icons.edit_outlined`, size 32, tooltip "Edit farm details"
    - `AppSpace.xs` gap below header row.
    - Each info row is a plain `Row` with a left label and right value (no ListTile — read-only info layout):
      - Row 1: label "Address" · value = address line (`AppText.body`, `AppColors.ink`). If empty, show em-dash "—".
      - Row 2: label "City / State / PIN" · value = city, state, ZIP joined as "Pune, Maharashtra · 411 001". If all empty, show "—".
      - Row 3: label "UPI ID" · value = UPI VPA. If empty, show "—".
      - Row 4: label "UPI payee name" · value = UPI payee name. If empty, show "—".
    - Labels use `AppText.meta`, `AppColors.inkMuted`. Values use `AppText.body`, `AppColors.ink`.
    - Vertical gap between rows: `AppSpace.xs` (4px).
  - Entire card has `AppSpace.lg` (16px) padding on all sides (standard `AppCard` padding).
  - The pencil icon sits in the top-right of the card — achieved with a `Row` spanning `Expanded` title + trailing icon button.

- **States:**
  - **Default (data loaded):** Farm name displayed in card title; info rows show values.
  - **Partially filled:** Any missing field shows "—" in that row's value. The card still renders all rows.
  - **Settings loading (initial page load):** The card is replaced by a `CircularProgressIndicator` centred on screen — existing behaviour on the page level, no change needed.
  - **Settings error:** Existing "Retry" `TextButton` centred on screen — no change.

- **Interactions:**
  - Tapping the pencil icon (`AppSoftIconButton`) opens the Farm edit bottom sheet (see §3).
  - No tap action on the card body itself.

- **Content:**
  - Section header: "Dairy farm"
  - Card title: farm name (e.g. "Shreeji Gir Gaushala")
  - Row labels: "Address", "City / State / PIN", "UPI ID", "UPI payee name"
  - Pencil tooltip: "Edit farm details"
  - Empty value placeholder: "—"

- **Accessibility:**
  - Pencil icon button must have a `Tooltip` with label "Edit farm details".
  - Minimum tap target for pencil button: 32×32 px (handled by `AppSoftIconButton`).
  - Info row labels are decorative; values are the semantic content — ensure `AppText.body` contrast ≥ 4.5:1 on `AppColors.surface`.

---

### 2. Settings screen — Owner profile card (read view)

- **Purpose:** Show owner identity at a glance; entry point to the owner edit sheet.

- **Layout & components:**
  - `OwnerSectionHeader` with title "Owner profile" — no change.
  - `AppSpace.sm` gap below header.
  - `AppCard` containing:
    - **Header row inside card:**
      - Left: full name (`firstName + " " + lastName`) in `AppText.cardTitle`, `AppColors.ink`. If name is empty, show "—".
      - Right: `AppSoftIconButton` with `Icons.edit_outlined`, size 32, tooltip "Edit owner profile"
    - `AppSpace.xs` gap.
    - Row: label "Mobile" · value = mobile number (read-only, always shows registered number). `AppText.body`, `AppColors.inkMuted` for the value — muted to signal non-editable.
  - Same label/value typography as Farm card.

- **States:**
  - **Default:** Full name in title; mobile in body row.
  - **Name empty:** Title shows "—"; mobile row is always populated.
  - **Settings loading / error:** Same page-level behaviour as Farm card.

- **Interactions:**
  - Tapping the pencil icon opens the Owner edit bottom sheet (see §4).
  - No tap on card body.

- **Content:**
  - Section header: "Owner profile"
  - Card title: full name (e.g. "Ramesh Patel")
  - Row label: "Mobile"
  - Pencil tooltip: "Edit owner profile"

- **Accessibility:**
  - Pencil button tooltip: "Edit owner profile".
  - Mobile field is intentionally non-editable — do not give it a tappable affordance.

---

### 3. Farm edit bottom sheet

- **Purpose:** Allow the owner to update all farm fields in one focused sheet.

- **Layout & components:**
  - `showOwnerBottomSheet` (drag handle, rounded top corners, `AppRadius.lg`, surface background).
  - Padding: `AppSpace.lg` left/right, `AppSpace.lg` bottom + keyboard inset (handled by `showOwnerBottomSheet`).
  - `OwnerSheetTitle` with title "Edit farm details" (no subtitle).
  - `AppSpace.sm` gap.
  - Fields in order:
    1. `AppTextField` — label "Farm name", full width.
    2. `AppSpace.sm` gap.
    3. `AppTextField` — label "Address", full width.
    4. `AppSpace.sm` gap.
    5. **Three-column Row** for PIN code / City / State:
       - **Column A — PIN code** (`flex: 2`): `AppTextField`, label "PIN code", `keyboardType: number`, max 6 digits. This is the leftmost, narrower column.
       - `AppSpace.sm` horizontal gap.
       - **Column B — City** (`flex: 3`): `AppTextField`, label "City". Shows loading spinner inside trailing of field when PIN lookup is in progress (see ZIP auto-fill states below). Read-only while lookup is running.
       - `AppSpace.sm` horizontal gap.
       - **Column C — State** (`flex: 3`): `AppTextField`, label "State". Same loading/read-only behaviour as City.
    6. `AppSpace.xs` gap (4px).
    7. **Pincode error message** (conditional — see states): `AppText.meta`, `AppColors.danger`, text "Pincode not found, please enter city/state manually". Shown directly below the three-column row. Invisible when no error.
    8. `AppSpace.md` gap.
    9. `AppTextField` — label "UPI ID (for bill QR)", full width.
    10. `AppSpace.sm` gap.
    11. `AppTextField` — label "UPI payee name", full width.
    12. `AppSpace.md` gap.
    13. `OwnerSheetActions` — primaryLabel "Save changes", no secondary action.
  - The sheet is scrollable (`isScrollControlled: true`, use `SingleChildScrollView` + `Column` inside) to handle smaller screens with keyboard up.

- **States:**

  **Default (form open, no lookup running):**
  - All fields pre-populated from current settings values.
  - Pincode error row hidden.
  - City and State fields editable.
  - Save button enabled.

  **ZIP auto-fill — Loading (6 digits entered in PIN code field):**
  - City and State fields become read-only.
  - Each shows a `CircularProgressIndicator` of size 14 in the field's trailing area (suffix icon slot).
  - Pincode error row hidden.
  - Save button disabled (greyed, `onPressed: null`) while lookup is in progress.

  **ZIP auto-fill — Success:**
  - City field auto-populated with returned city name.
  - State field auto-populated with returned state name.
  - City and State revert to editable (owner can override).
  - Spinner removed from both fields.
  - Pincode error row stays hidden.
  - Save button re-enabled.

  **ZIP auto-fill — Error (pincode not found or network error):**
  - City and State remain empty (or retain previous value if they had one before lookup).
  - City and State revert to editable.
  - Spinner removed.
  - Pincode error row visible: "Pincode not found, please enter city/state manually" in `AppText.meta`, `AppColors.danger`.
  - Save button re-enabled so owner can proceed with manual entry.

  **Save — Loading:**
  - `OwnerSheetActions` passes `loading: true` to the primary `AppButton`.
  - All fields disabled (non-interactive) while save is in progress.
  - Sheet stays open.

  **Save — Success:**
  - Sheet closes (pop).
  - `SnackBar` shown on the Settings screen: "Settings saved".
  - Settings data refreshes (provider invalidated).

  **Save — Error:**
  - Sheet stays open.
  - `SnackBar` with the API error message.
  - Loading state clears; fields re-enabled; owner can retry or cancel by dismissing the sheet.

- **Interactions:**
  - PIN code field `onChanged`: when input reaches exactly 6 digits, trigger pincode lookup automatically. Do not require a separate "Lookup" button.
  - If owner edits the PIN code field after a successful lookup (changes digits), clear City and State if they were auto-filled, re-run lookup when 6 digits reached again.
  - City and State are always manually editable once the lookup completes (success or error).
  - Drag handle dismisses the sheet without saving.
  - "Save changes" submits; sheet closes only on success.

- **Content:**
  - Sheet title: "Edit farm details"
  - Fields: "Farm name", "Address", "PIN code", "City", "State", "UPI ID (for bill QR)", "UPI payee name"
  - Save button: "Save changes"
  - Pincode error message: "Pincode not found, please enter city/state manually"
  - Save success snackbar: "Settings saved"
  - Save error snackbar: API error message (server-provided)

- **Accessibility:**
  - Three-column row: ensure each field has a distinct label so screen readers can identify them.
  - Disabled state on City/State during lookup: use `readOnly: true` on the `AppTextField` (field remains focusable for screen readers but not editable).
  - Loading state on Save button: `AppButton` with `loading: true` handles the accessible label internally.
  - Focus should land on "Farm name" when sheet opens.

---

### 4. Owner edit bottom sheet

- **Purpose:** Allow the owner to update their first and last name.

- **Layout & components:**
  - `showOwnerBottomSheet` (same sheet container as Farm sheet).
  - `OwnerSheetTitle` with title "Edit owner profile".
  - `AppSpace.sm` gap.
  - **Two-column Row** for names:
    - Left (`Expanded`): `AppTextField`, label "First name".
    - `AppSpace.sm` horizontal gap.
    - Right (`Expanded`): `AppTextField`, label "Last name".
  - `AppSpace.sm` gap.
  - Read-only mobile display: `Row` with label "Mobile" (`AppText.label`, `AppColors.inkMuted`) and value from settings (`AppText.body`, `AppColors.inkMuted`). No text field — purely informational. Visually matches an info row from the read card.
  - `AppSpace.md` gap.
  - `OwnerSheetActions` — primaryLabel "Save changes".

- **States:**

  **Default (sheet open):**
  - First name and Last name pre-populated.
  - Mobile row shows registered mobile (static, no edit affordance).
  - Save button enabled.

  **Save — Loading:**
  - `OwnerSheetActions` with `loading: true`.
  - Fields non-interactive.
  - Sheet stays open.

  **Save — Success:**
  - Sheet closes.
  - `SnackBar`: "Settings saved".
  - Owner profile card updates to reflect new name.

  **Save — Error:**
  - Sheet stays open.
  - `SnackBar` with API error message.
  - Fields re-enabled.

- **Interactions:**
  - No validation beyond "first name must not be empty" — if blank, show inline validation on the First name field: "Enter first name" (`AppStrings.firstNameRequired`).
  - Drag handle dismisses without saving.

- **Content:**
  - Sheet title: "Edit owner profile"
  - Field labels: "First name", "Last name"
  - Mobile label: "Mobile"
  - Save button: "Save changes"
  - First name validation: "Enter first name"
  - Success snackbar: "Settings saved"

- **Accessibility:**
  - First name and last name fields: explicit labels accessible to screen readers.
  - Mobile row: treated as decorative text; no interactive affordance.
  - Focus lands on "First name" when sheet opens.

---

### 5. Daily order schedule card (unchanged, time display note)

- **Purpose:** No visual redesign required. Keep existing `ListTile` rows inside `AppCard`.

- **Time display format:** The time value in each `ListTile` trailing widget must display in 12-hour format with AM/PM (e.g. "5:00 AM", "3:00 PM"). The backend stores times as `HH:mm` 24-hour strings; the formatting is purely display-side. Story S6-09 on the code side handles the formatter — the spec confirms the display intent here.

- **No other changes to this section.**

---

## Handoff

```
TO:      Flutter Engineer
STORY:   S6-03 — Settings: Farm profile card + Owner profile card redesign
DO:      Replace the current always-editable form cards with read-only info cards
         + pencil-triggered bottom sheets as defined in this spec. Keep the Order
         Schedule section unchanged except for 12-hr time display format.
AGAINST: briefs/specs/ux-s6-03-settings-profile-cards.md
DONE WHEN:
  - Farm card shows read-only info (name, address, city/state/ZIP row, UPI fields) with pencil icon
  - Farm edit sheet opens on pencil tap; ZIP auto-fill triggers on 6 digits; loading/success/error
    states all render correctly; save closes sheet + shows snackbar
  - Owner card shows read-only info (full name + mobile) with pencil icon
  - Owner edit sheet opens on pencil tap; first+last name in one row; save works
  - Order schedule card unchanged; times display in 12-hr format (e.g. "5:00 AM")
  - All states in this spec are implemented (no missing states)
  - Design tokens (AppColors, AppText, AppSpace, AppRadius) used throughout — no hard-coded values
```
