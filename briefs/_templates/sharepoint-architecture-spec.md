# SharePoint Architecture Spec — <solution / feature>

> Author: SharePoint Architect · Source: PRD · Date: <date>
> Implemented by: SPFx Engineer / Power Automate Engineer · Governance deployed by: DevOps

---

## PART A — Information architecture (for the implementers)

### Lists
For each list:
#### `<List Name>`
**Purpose:** <one line>

| Column (internal name) | Type | Required | Notes |
| ---------------------- | ---- | -------- | ----- |
| <Title> | Single line | yes | |
| <Field> | <Lookup → List / Choice / DateTime / …> | <…> | <relationship if lookup> |

- **Relationships (lookups):** `<field>` → `<List>` — models <…>

### Site columns / metadata
<Reusable columns to create, names + types.>

### Content types
| Content type | Parent | Applies to | Columns |
| ------------ | ------ | ---------- | ------- |
| <…> | <…> | <list/library> | <…> |

### Document libraries
- **`<Library>`** — content types: <…>; metadata tagging: <fields>; search/indexing
  strategy: <how tagging drives fast, accurate search>; large-list strategy: <if applicable>.

### SPFx web part design (if needed)
- **Folder structure:** <the structure the engineer must follow>
- **SharePoint content leveraged:** <lists / content types / fields by internal name, read vs write>
- **Configuration:** <property-pane options the site owner controls>

### Power Automate flow design (if needed)
- **Trigger:** <…>
- **Logic / steps:** <the flow's business logic, branch by branch>
- **Error handling:** <try/catch/finally shape — what Catch logs and notifies>
- **Retry / idempotency:** <retry policy on which actions; how re-runs avoid duplicates>

---

## PART B — Governance (for DevOps)

### Permission groups & roles
| Group | Role / level | Members |
| ----- | ------------ | ------- |
| <…> | <Read / Contribute / Full…> | <…> |

### Access matrix — who can access what
| Resource (list / library / item / page) | Group | Access |
| --------------------------------------- | ----- | ------ |
| <…> | <…> | <view / edit / none> |

### Other administration
<Site settings, navigation, search config, anything else DevOps must stand up. Least
privilege by default.>
