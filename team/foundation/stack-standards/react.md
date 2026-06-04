# Stack Standard — React

For the **React Engineer** (SaaS frontend) and, where it overlaps, the **SPFx Engineer**.
Read alongside `engineering-standards.md`. Implements the UX/UI Designer's spec — it does
not invent flows or screens.

Exact versions of React, the build tool, and libraries are pinned per-project in
`briefs/`. This file is about patterns, which don't change with the version number.

---

## Non-negotiables

- **Functional components and hooks only.** No class components.
- **TypeScript, strict.** No `any` without a written reason. Props and state are typed.
- **Build against the UX spec.** Screens, flows, states, and responsive behaviour come
  from `briefs/specs/`. If the spec is missing a state, that's a clarification (§8 of the
  protocol), not a thing you invent.

---

## Project structure — feature-first

Organise by feature, not by file type. Code that changes together lives together.

```
src/
├── app/              # entry, providers, router setup
├── features/
│   └── invoices/
│       ├── components/    # UI for this feature only
│       ├── hooks/         # feature logic
│       ├── api/           # data access for this feature
│       └── types.ts
├── components/ui/    # shared, presentational, reusable primitives
├── hooks/            # shared hooks
├── lib/              # framework-agnostic helpers, clients
└── styles/           # tokens, globals
```

A shared component knows nothing about a feature. A feature may use shared components.
Dependencies point inward — this is clean architecture for the frontend.

---

## State — pick the right kind

Three distinct kinds of state; do not conflate them.

- **Server state** (data from the API): owned by a data-fetching library (e.g. TanStack
  Query). Never copy server data into local state "to be safe" — that creates two sources
  of truth. Caching, refetching, and loading/error states are the library's job.
- **Local UI state** (a toggle, an input value): `useState`/`useReducer`, kept as close
  to where it's used as possible.
- **Global client state** (theme, auth session, cross-feature UI): a lightweight store
  (e.g. Zustand) or Context — only for what is genuinely global. Don't reach for global
  state to avoid passing a prop one level.

---

## Components

- Small and focused. A component that renders *and* fetches *and* holds complex logic
  should be split: a container hook for logic, presentational components for UI.
- Presentational components take props and render; they don't fetch or hold business
  logic. This keeps them reusable and testable.
- No prop drilling more than ~2 levels — lift to a store/context or compose differently.
- Derive, don't duplicate. If a value can be computed from props/state, compute it; don't
  store it.

---

## Data fetching

- All network access goes through a typed client in `lib/` or the feature's `api/` — never
  raw `fetch` scattered in components.
- Every fetch has explicit **loading, empty, error, and success** states in the UI. No
  silent spinners forever.
- Mutations invalidate or update the relevant cached queries; the UI reflects the new
  state without a manual refetch hack.

---

## Forms

- Use a form library (e.g. React Hook Form) with a schema validator (e.g. Zod). The same
  schema validates input and types the form.
- Validate on the client for UX, but never trust the client — the API validates again.
- Show field-level errors next to fields, and a clear summary for submit failures.

---

## Styling

- Follow the design tokens from the UX spec (colours, spacing, type scale). No hard-coded
  magic colours or pixel values that bypass the token system.
- Utility-first (Tailwind) or the project's chosen system — be consistent; don't mix
  approaches in one codebase.
- Components are responsive per the spec's breakpoints. Mobile behaviour is specified, not
  guessed.

---

## Performance

- Code-split by route; lazy-load heavy, rarely-used components.
- Memoise (`memo`, `useMemo`, `useCallback`) only where a real render cost is proven —
  not reflexively. Premature memoisation is noise.
- Stable keys in lists (never the array index for dynamic lists).
- Don't put expensive computation in render; derive it in a memo or move it out.

---

## Accessibility

- Semantic HTML first; ARIA only to fill gaps semantics can't.
- Everything interactive is keyboard-reachable and focus-visible.
- Inputs have labels; images have alt text; colour is never the only signal.

---

## Do NOT

- Write class components, or reach for legacy lifecycle patterns.
- Write SQL, PHP, or any backend code. Need an endpoint? Emit a handoff to the Laravel
  Engineer (§7).
- Invent a screen, flow, or empty/error state the UX spec didn't define. Ask (§8).
- Mutate state directly, or store server data in `useState`.
- Leave `console.log` or commented-out code in a finished file.
