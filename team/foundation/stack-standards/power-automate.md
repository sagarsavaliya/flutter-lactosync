# Stack Standard — Power Automate

For the **Power Automate Engineer** (JSON-defined cloud flows). Read alongside
`engineering-standards.md`. Implements the **SharePoint Architect's** flow design — the
Architect decides the flow's logic, error-handling strategy, and retry behaviour; this
agent builds it correctly and robustly. Flow design gaps are clarifications (§8) routed to
the Architect.

This is a different artifact from code: declarative flows (triggers, actions, expressions,
connectors), not TypeScript. It is its own lane for exactly that reason.

---

## Non-negotiables

- **Build to the Architect's flow design.** The trigger, the steps, the branching, the
  error-handling and retry approach come from the spec in `briefs/specs/`. The engineer
  implements them robustly — it does not redesign the business logic.
- **Every flow handles failure.** A flow with no error handling is not done. APIs fail,
  connectors throttle, items get deleted mid-run — the flow must behave predictably when
  they do.

---

## Solution-based development

- Build inside a **Solution**, not as standalone flows in My Flows. Solutions are how
  flows move between environments cleanly.
- Use **connection references** and **environment variables** for anything
  environment-specific (site URLs, list names, account connections) — never hard-code
  them into actions. This is what lets DevOps deploy dev → test → prod without editing the
  flow.
- Hand a deployable solution (managed for release) to the DevOps / Release Engineer; you
  don't own the environment deployment, but you make it deployable.

---

## Structure & readability

- **Rename every action** to say what it does — `Get pending approvals`, not
  `Get items 3`. A flow should read top-to-bottom like a sentence. This is the flow
  equivalent of clear naming, and the Code Reviewer checks for it.
- Group related steps into **Scopes** with meaningful names. Scopes also enable the
  try/catch pattern below.
- Add a note/comment on any non-obvious expression or branch (the *why*).
- Keep a single flow focused on one job. If it sprawls, split into child flows the
  Architect's design defines.

---

## Error handling — the try / catch / finally pattern

Structure substantive flows as scopes wired by **run-after** settings:

- **Try** scope: the main work.
- **Catch** scope: configured to run *only* when Try fails / times out / is skipped.
  It logs the failure with context (which item, which step, the error), notifies the right
  party per the design, and records the outcome.
- **Finally** scope (when needed): cleanup or status updates that must run either way.

Never leave a failed run silent. Surface it where the design says (a log list, a Teams/
email alert, a status field) with enough context to diagnose.

---

## Retry & resilience

- Configure **retry policy** on actions that call flaky or rate-limited APIs — exponential
  backoff, sensible count — per the Architect's design. Don't rely on the default blindly.
- Make flows **idempotent** where they can re-run: re-processing the same trigger item
  should not create duplicates or double-charge. Guard with a status flag, a check-then-
  act, or a key, as the design specifies.
- Handle throttling (429) and transient errors as retryable; handle genuine business
  failures (validation, not-found) as terminal with a clear outcome.
- Respect connector limits and concurrency — set concurrency control deliberately when
  ordering or rate matters.

---

## Data & SharePoint integration

- Reference lists, content types, and fields by the names/internal names the Architect
  specified, in the environment-variable form above.
- Filter at the source (OData filter queries) rather than pulling everything and filtering
  in the flow — the performance equivalent of avoiding N+1.
- When writing back to SharePoint, honour the content types, metadata, and permission
  model the Architect designed.

---

## Do NOT

- Redesign the business logic or the error/retry strategy — that's the Architect's spec.
- Hard-code site URLs, list names, or connections into actions — use environment variables
  and connection references.
- Ship a flow with no Catch scope or no logging on failure.
- Leave actions with default names like `Compose 2` / `Apply to each 3`.
- Build standalone flows outside a Solution, or own environment deployment (hand off to
  DevOps).
- Write SPFx / TypeScript (that's the SPFx Engineer's lane).
