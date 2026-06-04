# Stack Standard — Flutter

For the **Flutter Engineer** (Android / iOS). Read alongside `engineering-standards.md`.
Implements the UX/UI Designer's spec — it does not invent screens or flows.

Versions of Flutter and packages are pinned per-project in `briefs/`. This file is about
patterns.

---

## Non-negotiables

- **Clean architecture, three layers**: presentation → domain → data, dependencies
  pointing inward. The domain layer (entities, use-cases) knows nothing about Flutter,
  HTTP, or the database.
- **Build against the UX spec.** Screens, flows, states, look & feel come from
  `briefs/specs/`. A missing state is a clarification (§8), not an invention.

---

## Architecture & structure — feature-first

```
lib/
├── core/             # cross-cutting: theme/tokens, router, error types, network client
├── features/
│   └── orders/
│       ├── presentation/   # screens, widgets, controllers/notifiers
│       ├── domain/         # entities, use-cases, repository interfaces
│       └── data/           # repository impls, data sources, DTOs
└── main.dart
```

Presentation depends on domain; data implements domain's interfaces; domain depends on
nothing. This is what makes logic testable without a widget.

---

## State management

- Use the project's chosen solution (Riverpod by default for this team) consistently —
  never two state systems in one app.
- UI reads state and renders; it does not hold business logic. Logic lives in
  controllers/notifiers calling use-cases.
- Keep state immutable; produce new state rather than mutating.
- Every async-driven screen models **loading / data / empty / error** explicitly — no
  screen that silently shows nothing on failure.

---

## Navigation

- Declarative routing (e.g. go_router) defined in `core/`. Routes are named and typed;
  no scattered `Navigator.push` with string literals across the app.
- Deep-link and back-stack behaviour follow the UX spec.

---

## Networking & data

- One configured HTTP client (e.g. Dio) in `core/`, with interceptors for auth, logging,
  and error mapping. No raw clients spun up per call.
- API responses map to **DTOs** in the data layer, then to **domain entities** — the UI
  never touches raw JSON.
- Repository interfaces live in domain; implementations in data. The UI depends on the
  interface, so the data source can be swapped or mocked.

---

## UI & design system

- Centralise design tokens (colours, spacing, type, radii) in `core/` theme — from the UX
  spec. No hard-coded colours or magic paddings in widgets.
- Build small, composable widgets. A giant `build()` method is a smell — extract.
- Respect platform conventions where the spec calls for it (Material / Cupertino).
- Const constructors wherever possible; they cut rebuilds.

---

## Performance

- `const` widgets and stable keys to avoid needless rebuilds.
- Lists use lazy builders (`ListView.builder`), never building thousands of children
  eagerly.
- Keep `build()` cheap — no heavy work or I/O inside it.
- Dispose controllers, listeners, and streams.

---

## Quality & release

- Unit-test use-cases and repositories; widget-test key screens per the QA plan.
- Handle permissions, offline, and error states the spec defines — don't assume the happy
  path.
- Actual build/sign/ship steps for APK/AAB and IPA are the **DevOps / Release Engineer's**
  job. The Flutter Engineer keeps the project in a buildable, release-ready state and
  hands off (§7) — it does not own store deployment.

---

## Do NOT

- Mix two state-management approaches.
- Put business logic in widgets, or let the UI touch raw JSON / HTTP directly.
- Invent screens, flows, or states the UX spec didn't define. Ask (§8).
- Write backend, schema, or store-deployment config — hand off.
- Leave undisposed controllers, hard-coded design values, or unhandled async states.
