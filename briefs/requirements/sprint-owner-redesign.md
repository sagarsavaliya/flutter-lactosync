# PRD — Sprint OR: Owner App Redesign

> **Status:** BA complete — awaiting PM sprint plan
> **Author:** Business Analyst
> **Date:** 2026-06-07
> **Sprint codename:** OR (Owner Redesign)

---

## 1. Overview

This sprint delivers a set of schema and UX improvements to the owner-facing LactoSync app. The changes cover: a full redesign of how container types and their sizes are modelled; standardised milk-type defaults; a reworked product schema with per-product size selection; a standardised quantity list used across all quantity pickers; a farm-address prefill toggle for new-customer creation; and a set of confirmed bug fixes. The DBMS Architect, Flutter Engineer, and Laravel Engineer build directly from this document.

---

## 2. Actors

| Actor | Role |
|---|---|
| **FarmOwner** | Primary user of the owner app. Creates and manages products, subscriptions, and customers. |
| **System** | Seeds default container types, milk types, and quantities. Enforces business rules server-side. |

---

## 3. Container Type + Size — Schema Redesign

### 3.1 Business rule

A **container type** (e.g. "Glass Bottle") is a physical container the farm uses. It is available in one or more **sizes**. Sizes are a property of the container type, not of the product. Sizes are stored in the database and must never be hardcoded in app code.

### 3.2 System default container types (seeded, visible to all farms)

| Container Type | Sizes |
|---|---|
| Glass Bottle | 0.5 L, 1 L |
| Plastic Bag | 0.5 L, 1 L, 1.5 L, 2 L |
| 5L Can | 5 L |
| 10L Can | 10 L |
| 15L Can | 15 L |
| 20L Can | 20 L |

### 3.3 Farm-custom container types

- A farm owner may add their own container types with their own sizes. These are visible only to that farm.
- A farm owner **cannot** delete or edit system default container types. They may only hide a system default from their own farm's view.

### 3.4 Required schema

#### Table: `container_types`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint, PK | |
| `name` | varchar | Display name, e.g. "Glass Bottle" |
| `farm_id` | bigint, nullable, FK → `farms.id` | NULL = system default; non-null = farm-custom |
| `is_active` | boolean, default true | Soft-disable without deletion |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

#### Table: `container_type_sizes`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint, PK | |
| `container_type_id` | bigint, FK → `container_types.id` | |
| `size_liters` | decimal(8,2) | e.g. 0.5, 1.0, 1.5 |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

#### Table: `farm_container_type_visibility`

This table already exists. It controls which system defaults a given farm sees. No structural change required — the DBMS Architect confirms migration strategy.

### 3.5 Migration note

The current `container_types` schema has a flat `size_ml` column (one row per size). This must be migrated to the new grouped structure. The DBMS Architect owns the migration strategy and writes the migration spec.

---

## 4. Milk Type Defaults

### 4.1 Confirmed default milk types (seeded, system-wide, farm-hideable)

1. Gir Cow Milk
2. Cow Milk
3. Buffalo Milk
4. Special Buffalo Milk

### 4.2 Removal from seed

The following previously seeded milk types must be **removed from the seed file**: Kankrej Cow, Mehoni Buffalo, Jafrabadi Buffalo.

**Data preservation rule:** Any existing farm records (products, subscriptions, orders) that reference these milk type names must not be deleted or altered. Only the seed is updated — no data migration deletes rows.

---

## 5. Product Schema — Confirmed Design

### 5.1 What a product is

A **Product** = one milk type + one container type + one rate per litre. One product record in the catalog. The product record does not store a specific container size.

### 5.2 Product name generation

The product name is **auto-generated** at creation time as:

```
"{MilkTypeName} - ₹{rate}"
```

Example: "Gir Cow Milk - ₹80". The farm owner does not type a product name.

### 5.3 Product creation form

The owner fills in four inputs, in this order:

1. **Milk type** — dropdown populated from the farm's visible milk types.
2. **Container type** — dropdown populated from the farm's visible container types.
3. **Container sizes** — checkboxes, populated dynamically from the sizes defined for the selected container type (`container_type_sizes`). The farm owner selects which sizes they offer for this product. At least one size must be selected.
4. **Rate per litre** — number input (decimal).

A **product name preview** renders below the form as soon as both the milk type and rate are entered. It updates in real time.

### 5.4 Offered sizes — storage

A product has many offered sizes, stored in a separate table. This is distinct from `container_type_sizes` (which defines what the container physically comes in).

#### Table: `product_offered_sizes`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint, PK | |
| `product_id` | bigint, FK → `products.id` | |
| `size_liters` | decimal(8,2) | Must be one of the sizes in `container_type_sizes` for the product's container type |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

**Rationale:** A farm owner might offer Glass Bottle Gir Cow Milk only in 1 L even though Glass Bottles also come in 0.5 L. The size selection on the product is independent of the container type's full size list.

### 5.5 Product table display (owner app — Settings → Products)

| Column | Content |
|---|---|
| Product Name | Auto-generated name |
| Milk Type | Name of the associated milk type |
| Container Type | Name of the associated container type |
| Available Sizes | Comma-joined list of offered sizes, e.g. "0.5 L, 1 L" |
| Rate | Rate per litre, formatted as "₹{rate}" |

---

## 6. Subscription Line — Size Field

### 6.1 New column

`subscription_lines` gains a `container_size` column:

| Column | Type | Notes |
|---|---|---|
| `container_size` | decimal(8,2) | The specific container size chosen at subscription time. Must be one of the product's offered sizes (`product_offered_sizes`). |

### 6.2 Subscription creation flow

The owner fills in four inputs:

1. **Product** — dropdown (from the farm's product catalog).
2. **Container size** — dropdown, populated from the selected product's offered sizes (`product_offered_sizes`). Updates when the product selection changes.
3. **Quantity in litres per day** — selected from the standardised quantity list (see §7).
4. **Shift** — Morning or Evening.

### 6.3 Billing — unchanged

Billing formula remains: `quantity × unit_rate`. `container_size` is an **operational field only**. It tells the farm how many containers to prepare: `quantity / container_size` containers. It has no effect on billing calculations.

---

## 7. Standardised Quantity List

### 7.1 Values

20 values, in litres:

0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10

### 7.2 Storage

#### Table: `milk_quantities`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint, PK | |
| `quantity_liters` | decimal(8,2) | e.g. 0.5, 1.0 |
| `display_label` | varchar | e.g. "500 ml", "1 L", "1.5 L", … "10 L" |

**Seeding:** All 20 values above are seeded as system records. Display labels follow the format: values below 1 L display as "X ml" (e.g. "500 ml"); values 1 L and above display as "X L" (e.g. "1 L", "1.5 L").

Storing labels in the DB allows the list to be extended without requiring an app update.

### 7.3 Usage — dropdown replaces all free-form quantity inputs

Every quantity selection across the app must use this list as a **dropdown**. The following existing inputs must be replaced:

| Location | Current behaviour | New behaviour |
|---|---|---|
| Subscription creation — quantity field | Free-form text input | Dropdown from `milk_quantities` |
| Subscription edit — quantity field | Free-form text input | Dropdown from `milk_quantities` |
| Daily Orders — qty picker | Limited to 0.5–3 L | Dropdown from full `milk_quantities` list |
| Customer Detail — subscription edit | Free-form text input | Dropdown from `milk_quantities` |

---

## 8. Farm Address Prefill Toggle

### 8.1 New field

`farms` table gains:

| Column | Type | Default | Notes |
|---|---|---|---|
| `prefill_customer_address` | boolean | false | Controls whether city/state/zip are prefilled in new-customer form |

### 8.2 Behaviour when ON

When `prefill_customer_address` is true: in the new customer creation form, the fields `city`, `state`, and `zip` are **pre-filled** with the farm's values. These fields remain **editable** — the owner can override the prefilled values before saving.

### 8.3 Behaviour when OFF (or default)

When `prefill_customer_address` is false: `city`, `state`, and `zip` are **optional**. Only `address_line` is mandatory.

### 8.4 Settings UI

A toggle switch is added to: **Owner Settings → Farm section**.

- Label: "Pre-fill customer address from farm"
- Reads and writes `farms.prefill_customer_address` via the existing settings API (or a new settings endpoint if needed — DBMS Architect and Laravel Engineer confirm).

---

## 9. Bug Fixes (Functional Requirements)

### B-01 — Customer app entry point

**Requirement:** The sign-in screen (owner app) must include a text link at the bottom reading "Customer? Sign in here". Tapping this link navigates to `/customer/login`. No other structural change to the sign-in screen is made.

### B-02 — Customer pre-selection in subscription form

**Requirement:** When the owner creates a new customer and then taps "Add subscription" from the post-creation confirmation screen, the subscription creation form must open with the newly created customer **pre-selected** in the customer picker. The customer picker must be **non-changeable** (read-only / locked) in this flow. The owner cannot switch to a different customer from within this form invocation.

### B-03 / B-04 — Form input consistency

**B-03 — Quantity field label format:**
All quantity fields across the app must display the label "Qty (ltr)". The unit must never appear inside the input box itself (no suffix or placeholder text of "ltr", "L", or "litres" inside the field).

**B-04 — Uniform input height:**
All form inputs across the app must have a uniform height. No field within the same form may appear taller or shorter than the others. Specifically, the discount field in the subscription form must match the height of all adjacent fields.

---

## 10. Screens Affected

The following screens require changes. Layout and component decisions are resolved by the Flutter Engineer against the UX spec produced separately.

| Screen | Change type |
|---|---|
| Owner Settings → Container Types section | Redesign — new grouped container type + size management |
| Owner Settings → Products section | Redesign — new product table (§5.5), new creation form (§5.3) |
| Onboarding → Product Setup | Update to match new product creation form (§5.3) |
| Onboarding → Subscription (new customer flow) | Update to match new subscription creation flow (§6.2) |
| Customer Detail → Add / Edit Subscription | Container size dropdown (§6.2); quantity dropdown (§7.3) |
| Daily Orders → Qty picker | Replace limited picker with full standardised quantity dropdown (§7.3) |
| New Customer form | Address fields prefill behaviour (§8); city/state/zip optional when toggle off |
| Sign-in screen | "Customer? Sign in here" text link (B-01) |

---

## 11. Out of Scope for This Sprint

- Customer-app screens (covered in Sprint CA).
- Billing calculation changes.
- WhatsApp notification changes.
- Any schema changes not listed in §§3–8.

---

## 12. Open Questions / Escalation Items

| # | Question | Assigned to |
|---|---|---|
| OQ-01 | Migration strategy for `container_types` flat `size_ml` → grouped `container_type_sizes` (data + rollback plan) | DBMS Architect |
| OQ-02 | Does `prefill_customer_address` read/write via an existing settings endpoint or does it require a new one? | DBMS Architect + Laravel Engineer (peer-to-peer; log resolution in DECISIONS.md) |
