# Stack Standard — SPFx

For the **SPFx Engineer** (SharePoint Framework web parts / extensions, TypeScript +
React). Read alongside `engineering-standards.md` and `react.md` (the React rules apply to
the UI layer). Implements the **SharePoint Architect's** design — it does not decide
information architecture, content types, permissions, or the web part's structural plan.

SPFx, Node, and library versions are pinned per-project in `briefs/` (the toolchain is
version-sensitive — confirm the supported Node version per project before scaffolding).

---

## Non-negotiables

- **Build to the architecture spec.** The SharePoint Architect decides the web part's
  folder structure, what SharePoint content it leverages (which lists, content types,
  fields), and how. The SPFx Engineer implements that — it does not invent the data model
  or the structure. Gaps are clarifications (§8) routed to the Architect.
- **React for all UI.** No direct DOM manipulation, no jQuery. Render through React
  components, following `react.md`.
- **TypeScript, strict and typed** against the SharePoint data shapes the Architect
  specified.

---

## Structure

Follow the structure the Architect defined for the web part. Within it:

```
src/webparts/<part>/
├── components/        # React components (presentational + container split)
├── services/          # SharePoint data access (PnPjs), typed
├── models/            # interfaces for list items, content types, DTOs
└── <Part>WebPart.ts   # property pane, wiring, context setup
```

Keep the web part class thin: it wires context and the property pane, then renders the
root React component. Logic and data access live in components/services, not in the web
part class.

---

## SharePoint data access

- Use **PnPjs** (or the project's chosen library) for all list/library/Graph access —
  never hand-rolled REST string-building.
- All access goes through a typed **service** layer, not scattered through components. The
  component asks the service; the service knows SharePoint.
- Map list items to typed models immediately; components never handle raw SharePoint JSON.
- Respect the content types, site columns, and metadata the Architect defined — query and
  write to those, with their internal names, exactly as specified.
- Batch requests where multiple operations occur; mind list view thresholds on large
  libraries (the Architect's spec should flag large-list strategy — follow it).

---

## Permissions & context

- Honour the permission model from the Architect's spec — the web part assumes the access
  the Architect designed; it does not silently elevate or work around permissions.
- Read tenant/site/user context from the SPFx context, not hard-coded URLs or IDs. Any
  environment-specific value comes from the property pane or configuration, never a
  literal.

---

## Theming & UX

- Use the SharePoint theme / Fluent UI tokens so the part matches the host site; follow
  the UX spec for layout and behaviour.
- Responsive within the SharePoint page canvas and section widths.
- Accessible per `react.md`.

---

## Property pane

- Expose genuine configuration (which list, how many items, display options) through the
  property pane with proper types and validation — don't hard-code what a site owner
  should control.
- Reconfiguring via the property pane re-renders correctly without a full reload.

---

## Build & ship

- Keep the solution packageable (`.sppkg`) and the manifest correct. Bundling and
  **app-catalog deployment / tenant configuration are the DevOps / Release Engineer's
  job** — the SPFx Engineer keeps it release-ready and hands off (§7).

---

## Do NOT

- Decide information architecture, content types, metadata, or permissions — that is the
  SharePoint Architect's spec.
- Manipulate the DOM directly or use jQuery.
- Hard-code site URLs, list GUIDs, or environment values — read from context/config.
- Build hand-rolled REST calls instead of the data library.
- Write Power Automate flows (that's the Power Automate Engineer) or own deployment.
