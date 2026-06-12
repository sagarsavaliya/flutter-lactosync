# QA Test Plan — Sprint OR: Owner App Redesign

> **Author:** QA Engineer
> **Date:** 2026-06-07
> **Sprint codename:** OR (Owner Redesign)
> **Source documents:**
> - `briefs/requirements/sprint-owner-redesign.md` (PRD)
> - `briefs/specs/schema-sprint-or.md` (DB spec)
> - `briefs/specs/ux-sprint-or.md` (UX spec)

---

## Scope

This plan covers all database migrations, API contract changes, and Flutter UI changes introduced in Sprint OR. Manual verification cases cover the live tenant (Farenidham Gaushala) and the full onboarding flow to confirm zero regression.

## Prerequisites

- Dev/staging MySQL instance cloned from a recent VPS dump (or VPS itself in a maintenance window for DM tests).
- Owner app APK built from Sprint OR branch installed on test device.
- Access to `artisan migrate` and `artisan db:seed` on the target environment.
- API accessible at the staging base URL.
- Test farm owner account with at least one existing product, subscription, and customer.

---

## Section 1 — Database Migration Tests (DM)

> These cases are executed in sequence on the staging environment **before** applying to the live VPS. Run Step 1 first, verify, then run Step 2. Step 3 must never be run in this sprint.

### Step 1 Migration — Additive

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| DM-01 | `container_type_sizes` table created | 1. Run Step 1 migration (`sprint_or_step1_additive`). 2. Run `SHOW TABLES;`. 3. Run `DESCRIBE container_type_sizes;`. | Table exists. Columns present: `id` (bigint PK auto-increment), `container_type_id` (bigint NOT NULL FK), `size_liters` (decimal(8,2) NOT NULL), `created_at`, `updated_at`. UNIQUE key on `(container_type_id, size_liters)`. Index `idx_container_type_sizes_container_id` on `container_type_id`. Table is empty. | |
| DM-02 | `product_offered_sizes` table created | After Step 1 migration, run `DESCRIBE product_offered_sizes;`. | Table exists. Columns: `id` (bigint PK auto-increment), `product_id` (bigint NOT NULL FK → `products.id` CASCADE DELETE), `size_liters` (decimal(8,2) NOT NULL), `created_at`, `updated_at`. UNIQUE key on `(product_id, size_liters)`. Index `idx_product_offered_sizes_product_id`. Table is empty. | |
| DM-03 | `milk_quantities` table created | After Step 1 migration, run `DESCRIBE milk_quantities;`. | Table exists. Columns: `id` (bigint PK auto-increment), `quantity_liters` (decimal(8,2) NOT NULL), `display_label` (varchar(20) NOT NULL), `created_at`, `updated_at`. UNIQUE key on `(quantity_liters)`. Table is empty. | |
| DM-04 | `farms.prefill_customer_address` column added | After Step 1 migration, run `DESCRIBE farms;`. Then run `SELECT id, prefill_customer_address FROM farms LIMIT 5;`. | Column `prefill_customer_address` of type `tinyint(1)` with DEFAULT `0` is present. All existing farm rows return `prefill_customer_address = 0`. No existing farm data altered. | |
| DM-05 | `subscription_lines.container_size` column added; no existing data lost | After Step 1 migration, run `DESCRIBE subscription_lines;`. Then run `SELECT COUNT(*) FROM subscription_lines;` before and after migration. Then run `SELECT container_size FROM subscription_lines LIMIT 5;`. | Column `container_size` of type `decimal(8,2)` NULLABLE is present. Row count is unchanged. All existing `container_size` values are NULL (not zero — nullable). No subscription line data is altered. | |

### Step 2 Migration — Backfill

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| DM-06 | System `container_types` merged to canonical names | 1. Before Step 2: record current `container_types` row count and IDs. 2. Run Step 2 migration. 3. Run `SELECT id, name, farm_id FROM container_types WHERE farm_id IS NULL ORDER BY id;`. | System defaults (farm_id IS NULL) now show exactly 6 rows: "Glass Bottle", "Plastic Bag", "5L Can", "10L Can", "15L Can", "20L Can". The old flat rows (Glass Bottle 500ml, Glass Bottle 1L, etc.) are removed. The retained canonical row for Glass Bottle and Plastic Bag has the smallest ID from the original set. | |
| DM-07 | `container_type_sizes` populated correctly for system defaults | After Step 2, run `SELECT ct.name, cts.size_liters FROM container_type_sizes cts JOIN container_types ct ON ct.id = cts.container_type_id WHERE ct.farm_id IS NULL ORDER BY ct.name, cts.size_liters;`. | Rows present: Glass Bottle → 0.50, 1.00. Plastic Bag → 0.50, 1.00, 1.50, 2.00. 5L Can → 5.00. 10L Can → 10.00. 15L Can → 15.00. 20L Can → 20.00. Total 10 rows. No duplicates. | |
| DM-08 | FK re-pointing — products referencing non-canonical container_type rows now point to canonical row | Before Step 2: note any `products.container_type_id` values that pointed to non-canonical flat rows (e.g. "Glass Bottle 1L" row id). After Step 2: run `SELECT id, name, container_type_id FROM products WHERE deleted_at IS NULL;`. | All `container_type_id` values in `products` reference valid, existing `container_types` rows (no orphaned FKs). No products have a `container_type_id` pointing to a now-deleted non-canonical row. | |
| DM-09 | `products.name` backfilled to auto-generated format | After Step 2, run `SELECT p.name, mt.name AS milk_type_name, p.rate FROM products p LEFT JOIN milk_types mt ON mt.id = p.milk_type_id WHERE p.deleted_at IS NULL LIMIT 10;`. | Each product's `name` matches the pattern `"{MilkTypeName} - ₹{rate}"` where rate is formatted as a number without trailing .00 (e.g. "Gir Cow Milk - ₹80" not "₹80.00"). Products with NULL `milk_type_id` fall back to `products.milk_type` string column in the name. No product has a blank or NULL name. | |
| DM-10 | Special Buffalo Milk inserted as new system milk type | After Step 2, run `SELECT id, name, farm_id, is_active FROM milk_types WHERE farm_id IS NULL ORDER BY id;`. | A row for "Special Buffalo Milk" with `farm_id = NULL` and `is_active = 1` exists. The existing rows "Gir Cow", "Cow", "Buffalo" (old short names) are still present and untouched — not deleted or deactivated. The new canonical rows "Gir Cow Milk", "Cow Milk", "Buffalo Milk" are also present. Rows for "Kankrej Cow", "Mehoni Buffalo", "Jafrabadi Buffalo" are present if they existed before (not deleted). | |
| DM-11 | `product_offered_sizes` backfilled from `product_container_types` pivot | After Step 2, run `SELECT COUNT(*) FROM product_offered_sizes;`. Then run `SELECT pos.product_id, pos.size_liters FROM product_offered_sizes pos JOIN products p ON p.id = pos.product_id WHERE p.deleted_at IS NULL ORDER BY pos.product_id, pos.size_liters LIMIT 20;`. | Table is not empty (unless no products existed). Each row in `product_offered_sizes` corresponds to a valid product that had an entry in `product_container_types`. `size_liters` values match the sizes associated with the product's container type via `container_type_sizes`. No duplicate `(product_id, size_liters)` pairs. | |
| DM-12 | `milk_quantities` seeded with all 20 values and correct labels | After Step 2, run `SELECT quantity_liters, display_label FROM milk_quantities ORDER BY quantity_liters;`. | Exactly 20 rows. Values: 0.50 → "500 ml", 1.00 → "1 L", 1.50 → "1.5 L", 2.00 → "2 L", 2.50 → "2.5 L", 3.00 → "3 L", 3.50 → "3.5 L", 4.00 → "4 L", 4.50 → "4.5 L", 5.00 → "5 L", 5.50 → "5.5 L", 6.00 → "6 L", 6.50 → "6.5 L", 7.00 → "7 L", 7.50 → "7.5 L", 8.00 → "8 L", 8.50 → "8.5 L", 9.00 → "9 L", 9.50 → "9.5 L", 10.00 → "10 L". Values below 1 L display as "ml"; values ≥ 1 L display as "L". Whole-number L values drop the decimal. Migration is idempotent (run again → no duplicate rows due to `insertOrIgnore`). | |

### Step 3 — Deferred

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| DM-13 | Step 3 migration file exists but is NOT executed | 1. On the staging DB after Step 1 + Step 2, run `SELECT * FROM migrations WHERE migration LIKE '%step3%';`. 2. Run `DESCRIBE container_types;`. 3. Run `DESCRIBE products;`. | The `migrations` table has NO entry for the step3 migration (it was never run). `container_types` still has columns `kind`, `size_ml`, `size_key`. `products` still has columns `milk_type`, `container_type`, `container_kind`. `product_container_types` table still exists. The step3 migration file exists in `database/migrations/` directory (verify via `ls` in repo) but is uncommitted from the migration run. | |

---

## Section 2 — Container Types (CT)

> API base: `GET /api/v1/owner/product-types/containers`. Auth: valid farm owner Sanctum token.

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| CT-01 | GET returns grouped list with `sizes` array | Authenticate as farm owner. Call `GET /api/v1/owner/product-types/containers`. Inspect JSON response. | Response is 200. Each item in the response array has a `sizes` field that is an array of objects with `id` and `size_liters`. System defaults are grouped: "Glass Bottle" has `sizes: [{size_liters: "0.50"}, {size_liters: "1.00"}]`, "Plastic Bag" has 4 size entries, each Can type has 1 size entry. No item has both a sizes array and the old flat size data (size_ml / size_key) as the primary representation (old fields may still be present as nulls, but `sizes` is the active data). | |
| CT-02 | System container types have `is_system: true` | From the CT-01 response, filter items where `farm_id` is null. | All items with `farm_id: null` have `is_system: true` (or equivalent field). Items with a non-null `farm_id` have `is_system: false`. | |
| CT-03 | Farm-custom container types visible only to owning farm | 1. As Farm A owner, create a custom container type via POST. 2. Authenticate as Farm B owner. 3. Call GET. | Farm B's response does not include the container type created by Farm A. Farm A's response does include it. | |
| CT-04 | Add custom container type with sizes | As farm owner, call `POST /api/v1/owner/product-types/containers` with body `{"name": "Stainless Pot", "sizes": [0.5, 1.0, 1.5]}`. | Response 201. New container type "Stainless Pot" is returned with `farm_id` = farm's ID, `is_system: false`. `container_type_sizes` table has 3 rows for this new type (0.50, 1.00, 1.50). Subsequent GET includes this type with correct sizes array. | |
| CT-05 | Delete farm-custom container type | 1. Create a custom container type (CT-04). 2. Call `DELETE /api/v1/owner/product-types/containers/{id}` for the new type. | Response 200 or 204. Container type and its associated `container_type_sizes` rows are removed from the DB. Subsequent GET does not include this type. | |
| CT-06 | Block delete of system container type (403) | Call `DELETE /api/v1/owner/product-types/containers/{id}` where `{id}` is the ID of "Glass Bottle" (a system default, `farm_id IS NULL`). | Response 403. Body contains an error message indicating system types cannot be deleted. Database is unchanged. | |
| CT-07 | Block delete if a product references the container type (422) | 1. Create a custom container type. 2. Create a product using that container type. 3. Attempt to delete the container type. | Response 422. Body contains error message indicating the container type is in use by products. Container type and sizes rows are not deleted. Product still references it. | |
| CT-08 | Size chips render correctly on Container Types settings screen | In the owner app, navigate to Settings → Container Types. | Each container type card shows size chips. Glass Bottle card shows chips labelled "0.5 L" and "1 L". Plastic Bag shows "0.5 L", "1 L", "1.5 L", "2 L". 5L Can shows "5 L". Chips are display-only (not tappable — no action on tap). Chips use `AppColors.primaryFaint` background. | |
| CT-09 | "System" badge displayed on system container types | In the app Settings → Container Types, inspect each card. | All 6 system default cards (Glass Bottle, Plastic Bag, 5L Can, 10L Can, 15L Can, 20L Can) display a small "System" pill badge with a lock icon. No delete icon or swipe-to-delete is present on system cards. Farm-custom cards show a delete icon and no System badge. | |
| CT-10 | Add container type via bottom sheet | In app Settings → Container Types, tap "Add container type". In the bottom sheet: enter name "Clay Pot", add sizes 0.5 and 2. Tap Save. | Bottom sheet opens correctly (`isScrollControlled: true`). Name field accepts text. Tapping "+ Add size" opens a small dialog; entering "0.5" creates a chip labelled "500 ml"; entering "2" creates a chip labelled "2 L". On Save: snackbar "Container type added." appears. The list refreshes and "Clay Pot" card is visible with chips "500 ml" and "2 L". | |

---

## Section 3 — Products (PR)

> API base: `GET /api/v1/owner/products`. Auth: valid farm owner Sanctum token.

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| PR-01 | GET product list includes milk_type, container_type, and offered_sizes | Call `GET /api/v1/owner/products` (or equivalent products listing endpoint). | Response 200. Each product object includes: `name` (auto-generated string), `milk_type` (object with `id` and `name`), `container_type` (object with `id` and `name`), `offered_sizes` (array of objects with `id` and `size_liters`), `rate` (decimal string). | |
| PR-02 | Create product — auto-generated name format | Call `POST /api/v1/owner/products` with `{"milk_type_id": <GirCowMilkId>, "container_type_id": <GlassBottleId>, "offered_sizes": [1.00], "rate": 80}`. | Response 201. Returned product has `name` = "Gir Cow Milk - ₹80". Name was generated server-side; the client did not send a name field. DB `products.name` = "Gir Cow Milk - ₹80". | |
| PR-03 | Auto-generated name uses milk type name not ID | Create a product with Cow Milk and rate 65. | Product name returned is "Cow Milk - ₹65". No ID or reference code appears in the name. | |
| PR-04 | Delete product | 1. Create a product. 2. Call `DELETE /api/v1/owner/products/{id}`. | Response 200 or 204. Product row has `deleted_at` set (soft-deleted). Product no longer appears in the GET product list. | |
| PR-05 | Block delete if active subscription references product (422) | 1. Create a product. 2. Create a subscription referencing that product. 3. Attempt DELETE on the product. | Response 422. Error message indicates the product is in use by active subscriptions. `deleted_at` on the product remains NULL. | |
| PR-06 | Product form validation — required fields | In the app, open Add Product form. Tap Save without filling any field. | Inline validation errors shown: "Select a milk type" on the milk type dropdown; "Select a container type" on the container type dropdown; "Select at least one size" below the sizes group; "Enter a rate" on the rate field. No API call is made. | |
| PR-07 | Container type dropdown in product form populated from farm's container types | In the app, open Add Product form. Open the Container type dropdown. | Dropdown lists all container types visible to the farm (system defaults + farm-custom). Each dropdown item shows the container type name as primary text and a secondary line "Available in X, Y" listing sizes. The secondary line is styled `AppText.meta` in `inkMuted`. | |
| PR-08 | Product list shows subtitle correctly | In app Settings → Products, view the product list. | Each product row has a title matching the auto-generated name (e.g. "Gir Cow Milk - ₹80") and a subtitle matching the pattern `"{MilkType} · {ContainerType} · {Sizes} · ₹{rate}/ltr"` (e.g. "Gir Cow Milk · Glass Bottle · 0.5 L, 1 L · ₹80/ltr"). Sizes are comma-joined from `product_offered_sizes`. | |
| PR-09 | Rate field formats as integer (80 not 80.0) | Create a product with rate 80. View it in the product list and in the GET API response. | Product name shows "Gir Cow Milk - ₹80" (not "₹80.0" or "₹80.00"). Rate in the subtitle also renders without unnecessary decimals. The `rate` field in the API response is "80.00" as a decimal string (correct DB type), but the rendered name drops the .00 suffix. | |
| PR-10 | Empty state when no products exist | On a fresh test farm with no products, navigate to Settings → Products. | Inside the AppCard, a row reads "No products yet" (styled `AppText.body`, `inkMuted` colour). The "Add product" button is still visible below the card. | |

---

## Section 4 — Subscription Form (SF)

> Applies to new subscription creation from Customer Detail and subscription edit sheet.

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| SF-01 | Qty field is a dropdown, not a text input | Open the subscription creation form (Customer Detail → Add subscription). Observe the Qty field. | The Qty field renders as a `DropdownButtonFormField` (dropdown arrow visible, no keyboard appears on tap). It is NOT a free-form text input field. Tapping the field opens a dropdown list. | |
| SF-02 | Full range 0.5L–10L available in qty dropdown | Open the Qty dropdown in the subscription form. Scroll through all options. | Exactly 20 options are present: "500 ml", "1 L", "1.5 L", "2 L", "2.5 L", "3 L", "3.5 L", "4 L", "4.5 L", "5 L", "5.5 L", "6 L", "6.5 L", "7 L", "7.5 L", "8 L", "8.5 L", "9 L", "9.5 L", "10 L". Labels match the `display_label` from `milk_quantities`. No option outside this range is present. | |
| SF-03 | Qty field label is "Qty (ltr)" | Inspect the Qty field label in the subscription form. | Label text reads exactly "Qty (ltr)". No variant such as "Quantity", "Qty", "Qty (L)", or "Qty (litres)". | |
| SF-04 | No unit text inside the Qty input box | Select any value in the Qty dropdown (e.g. "1.5 L") and observe the displayed value. Also inspect the field's `suffixText`, `hintText`, and `prefixText`. | The field shows the display label (e.g. "1.5 L") from the dropdown item — which is a formatted value from the DB, not a raw number with a suffix appended by the field itself. There is no additional suffix "ltr", "L", or "litres" appended to the input box by `InputDecoration`. | |
| SF-05 | B-02 — Locked customer pre-selection (customer dropdown disabled) | From Customer Detail page for Customer A, tap "Add subscription". Observe the subscription form. | A read-only customer field is present showing Customer A's name. The field is visually disabled (greyed out, `enabled: false`). No dropdown arrow is present. The owner cannot change the customer in this form invocation. | |
| SF-06 | B-02 — Pre-selected customer value is correct | From Customer Detail page for Customer B, tap "Add subscription". Observe the customer field in the form. | The read-only customer field shows Customer B's name (not Customer A's, not blank). The customer field is pre-populated before any other interaction. | |

---

## Section 5 — Daily Orders (DO)

> Location: Daily Orders tab → Adjust quantity for an existing order.

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| DO-01 | Qty adjustment shows full 0.5–10L range | In Daily Orders, tap an order row to adjust its quantity. Observe the qty control in the adjustment sheet. | The qty control is a dropdown (`DropdownButtonFormField`), not a stepper. All 20 options from `milk_quantities` are present ("500 ml" through "10 L"). The old stepper (+ / − buttons with a limited range) is absent. | |
| DO-02 | Selecting 5L works | In the Daily Orders qty adjustment dropdown, select "5 L". Tap Save. | The order's quantity updates to 5.00 L. The displayed quantity in the Daily Orders list reflects 5 L after refresh. No validation error is shown. | |
| DO-03 | Selecting 0.5L works | In the Daily Orders qty adjustment dropdown, select "500 ml". Tap Save. | The order's quantity updates to 0.50 L. The displayed quantity in the Daily Orders list reflects 0.5 L after refresh. No validation error is shown. | |

---

## Section 6 — Owner Settings — Farm Prefill Toggle (PT)

> Location: Owner app → Settings → Farm section.

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| PT-01 | Toggle visible in farm section | Navigate to Owner Settings. Scroll to the Farm Details section. | A `SwitchListTile` labelled "Pre-fill customer address from farm" is present in the Farm Details section, below the existing address fields. A muted hint paragraph below the toggle reads: "When on, city, state and PIN code will be pre-filled from your farm address when adding a new customer." The hint paragraph is always visible (not conditional on toggle state). | |
| PT-02 | Default toggle state is OFF | On a farm that has never changed the toggle, navigate to Settings → Farm. Observe the toggle. Also query `SELECT prefill_customer_address FROM farms WHERE id = <farm_id>;`. | Toggle is in the OFF position. DB value is `0`. | |
| PT-03 | Toggling ON saves to API and DB | With toggle currently OFF, tap it to turn ON. | Toggle flips to ON immediately (optimistic update). A `PATCH /api/v1/owner/settings` (or equivalent) request fires with `prefill_customer_address: true`. On API success: toggle stays ON. DB `prefill_customer_address` = 1. No snackbar on success (matches owner app pattern for toggle rows). On API error: toggle reverts to OFF, red snackbar "Failed to save setting." | |
| PT-04 | New customer form pre-fills city/state/zip from farm when toggle is ON | 1. Turn prefill toggle ON (PT-03). 2. Confirm farm has city, state, and zip values set. 3. Navigate to Add Customer. | The city, state, and zip fields in the new customer form are pre-populated with the farm's city, state, and zip values respectively. Fields remain editable — the owner can type over them. `address_line` is not pre-filled (only city/state/zip). | |
| PT-05 | Toggling OFF stops pre-fill | 1. Toggle is ON. 2. Navigate to Add Customer, confirm pre-fill occurs. 3. Go back, toggle OFF (toggle reverts to OFF position). 4. Navigate to Add Customer again. | After toggle is OFF, city, state, and zip fields in Add Customer form are blank (or optional, no pre-filled values from farm). | |

---

## Section 7 — Customer App Entry Point (CA-B01)

> Location: Owner sign-in screen.

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| CA-01 | "Customer? Sign in here" link visible at bottom of sign-in screen | Launch the app as a signed-out owner (or clear session). Navigate to the owner sign-in screen. Scroll to the bottom of the content. | A `TextButton` with text "Customer? Sign in here" is present at the very bottom of the sign-in screen content, below the primary "Sign in" button and any other secondary links. It is separated from the element above by a small vertical gap (`AppSpace.sm` or equivalent). | |
| CA-02 | Tap navigates to /customer/login | Tap "Customer? Sign in here". | App navigates to the customer login screen (`/customer/login`). A back arrow is present (the push nav action allows returning to the owner sign-in screen). The customer login screen is the correct screen from Sprint CA. | |
| CA-03 | Link style is muted (not prominent) | Inspect the "Customer? Sign in here" button styling. | Text colour is `AppColors.inkMuted` — noticeably muted/grey compared to the primary button colour. No underline. No icon. Font is `AppText.label` or `AppText.meta` — not `sectionTitle` or `screenTitle`. The link does not visually compete with the primary sign-in button. | |

---

## Section 8 — Input Consistency (UI)

> These cases apply across all affected forms. Test in the subscription creation/edit form and product creation form.

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| UI-01 | All form inputs in subscription form same height | Open the subscription creation form. Visually inspect all fields: Product dropdown, Container size dropdown, Qty dropdown, Shift control, Discount field (if present). Use Flutter Inspector or visual comparison. | All `AppTextField` and `DropdownButtonFormField` instances have the same visual height. No field appears taller or shorter than its siblings. `contentPadding` is uniformly `EdgeInsets.symmetric(horizontal: 16, vertical: 11)`. No field uses `isDense: true` or a different `contentPadding` value. | |
| UI-02 | Discount field matches other fields in height | In the subscription form, locate the Discount field. Compare its height to the Product dropdown and Qty dropdown. | Discount field is the same visual height as other fields. No suffix widget (e.g. "₹" suffix) inflates its height beyond sibling fields. If a currency symbol is needed, it appears only in the `labelText` ("Discount (₹)"), not as a `suffixWidget` or `suffix`. | |
| UI-03 | Qty dropdown height matches other fields | In the subscription form, compare the Qty dropdown height to the Product dropdown and Discount field. | Qty dropdown occupies the same vertical height. The dropdown arrow does not inflate the field height. `isDense: false` and `contentPadding` matching `AppTextField`. | |
| UI-04 | Rate field in product creation form same height as other fields | Open the Add Product form. Compare the Rate field height to the Milk type dropdown and Container type dropdown. | Rate field (`AppTextField` with `keyboardType: numberWithOptions(decimal: true)`) is the same height as the dropdown fields. No hardcoded `SizedBox(height: ...)` wrapper around individual fields. | |

---

## Section 9 — Manual Verification (MV)

> These are end-to-end human-verified tests performed after migrating the staging environment and installing the Sprint OR APK.

| ID | Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| MV-OR-01 | Full onboarding flow works after schema changes | On a fresh test account (no prior data), complete the entire onboarding sequence: sign up → OTP → role picker → set PIN → farm details → product setup → add customer → add subscription → onboarding checklist. | Each step completes without error. Product setup uses the new product creation form (milk type + container type + sizes + rate). Subscription creation uses the new subscription form (product dropdown + container size dropdown + qty dropdown + shift). The onboarding checklist marks all steps complete. Dashboard loads. | |
| MV-OR-02 | Existing Farenidham Gaushala subscription data intact after Step 1 + Step 2 migrations | 1. Run Step 1 and Step 2 migrations on the staging DB. 2. Log in as Farenidham Gaushala farm owner. 3. Navigate to Customers → any active customer → Customer Detail. 4. Check subscription cards (Card B). 5. Navigate to Daily Orders. | All pre-existing subscriptions display correctly with product name, container type, quantity, and rate. No subscription shows missing data (NULL names, broken container type references, or zero quantities). Daily Orders list populates correctly for the farm. No "orphaned" FK errors appear in Laravel logs. | |
| MV-OR-03 | Daily order generation still works for existing subscriptions | After Step 1 + Step 2 migrations, trigger (or wait for) daily order generation for Farenidham Gaushala. Alternatively, use the "Generate orders" button in the Daily Orders tab if available. | Orders are generated correctly for all active subscriptions. Quantity, product, and shift are correct per the subscription record. No migration-related errors in Laravel logs. Milk preparation summary (if visible on dashboard) shows correct litre totals. | |
| MV-OR-04 | Customer app sign-in flow works end to end | 1. From the owner sign-in screen, tap "Customer? Sign in here". 2. On the customer login screen, enter a registered customer mobile number. 3. Request OTP → receive OTP → enter OTP. 4. If first login: set PIN. 5. View customer dashboard. | Full customer auth flow completes without error. Customer dashboard loads with correct data (today's order, balance, etc.). The customer app screens (Sprint CA) are unaffected by Sprint OR changes. Back navigation from customer login returns to owner sign-in. | |

---

## Test Execution Order

1. DM-01 to DM-05 (Step 1 migration — run on staging DB)
2. DM-06 to DM-12 (Step 2 migration — run immediately after Step 1)
3. DM-13 (verify Step 3 not executed)
4. CT-01 to CT-10 (Container Types — API + UI)
5. PR-01 to PR-10 (Products — API + UI)
6. SF-01 to SF-06 (Subscription Form)
7. DO-01 to DO-03 (Daily Orders)
8. PT-01 to PT-05 (Prefill Toggle)
9. CA-01 to CA-03 (Customer Entry Point)
10. UI-01 to UI-04 (Input Consistency)
11. MV-OR-01 to MV-OR-04 (Manual Verification — last, requires full build on staging)

## Pass Criteria

All DM, CT, PR, SF, DO, PT, CA, and UI cases must be Pass before merging the Sprint OR branch to main and deploying to the live VPS. All 4 MV cases must be Pass before the PM signs off the sprint.

## Rollback Notes

- If any DM-01–DM-05 case fails: run `artisan migrate:rollback` for Step 1 only. Safe — purely additive.
- If any DM-06–DM-12 case fails: run `artisan migrate:rollback` for Step 2. Note the Step 2 down() is a manual recovery (see schema spec §3 Step 2). Do not roll back Step 1 unless Step 2 rollback is also complete.
- Step 3 (DM-13) is not run in this sprint under any circumstances. If accidentally run, escalate immediately — it is not safely reversible from the migration alone.
