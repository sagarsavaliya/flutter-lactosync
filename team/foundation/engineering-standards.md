# Engineering Standards (cross-cutting)

Every implementer obeys these, regardless of stack. Per-stack rules live in
`stack-standards/<stack>.md`; this file is what they all share. Reference the slice you
need — do not re-paste this file into your context.

The guiding value: **code is read far more often than it is written.** Optimise for the
next human (or agent) who opens this file cold. Clear beats clever, every time.

---

## Core principles

- **Clean architecture.** Dependencies point inward. Business logic does not know about
  the framework, the database, or the UI. You can swap the delivery mechanism (HTTP,
  CLI, queue) without touching the rules. Each stack standard says how this maps locally.
- **Single responsibility.** A unit (function, class, component, module) does one thing
  and has one reason to change. If you struggle to name it without "and", split it.
- **Explicit over implicit.** No hidden side effects, no magic globals, no spooky
  action at a distance. A reader should be able to predict what a unit does from its
  signature and name.
- **Composition over inheritance.** Prefer small pieces wired together over deep class
  trees.
- **Fail loud, fail early.** Validate at the boundary, reject bad input immediately, and
  surface errors with enough context to act on. Never swallow an error silently.
- **No premature abstraction.** Don't build a framework for a problem you don't have yet.
  Duplicate twice before you abstract; abstract on the third.

---

## Definition of Done

Code is **not done** until all of these are true. The Code Reviewer enforces this list;
an implementer self-checks against it before handing off.

1. **Meets the spec.** It does exactly what the brief/story said — no more (no scope
   creep), no less.
2. **Clean architecture respected.** Layers are honoured; no business logic leaking into
   controllers, widgets, or components.
3. **Readable.** Clear names, small units, no dead code, no commented-out blocks, no
   debug logging left in.
4. **Typed.** Strong typing throughout where the language supports it. No `any`, no
   untyped escape hatches without a written reason.
5. **Errors handled.** Every failure path is handled or deliberately propagated.
   User-facing failures are graceful; internal failures are logged with context.
6. **Secure.** Meets the security baseline below.
7. **Tested.** Has the tests the stack standard requires, and they pass.
8. **No N+1 / no obvious perf trap.** Queries, loops, and renders are checked for the
   common waste described in the stack standard.
9. **Self-documenting + minimal comments.** Names carry the meaning; comments explain
   *why*, never *what*.
10. **STATUS.md and DECISIONS.md updated.** The story line reflects reality; any decision
    made during the work is logged.

---

## Naming

- Names describe intent, not implementation. `activeSubscriptions`, not `arr2`.
- Booleans read as questions: `isActive`, `hasAccess`, `canPublish`.
- Functions are verbs (`calculateInvoiceTotal`), values are nouns (`invoiceTotal`).
- No abbreviations except the universally known (`id`, `url`, `http`). No `usr`, `qty`,
  `tmp`.
- Be consistent with the stack's casing convention (see each stack standard). Never mix.

---

## Error handling

- Validate input at the system boundary (request, form, API edge). Inside the boundary,
  assume data is valid — don't re-check everywhere.
- Errors carry context: what failed, with what input, where. A bare "error occurred" is
  a defect.
- Distinguish *expected* failures (validation, not-found, unauthorised) — handled and
  returned cleanly — from *unexpected* ones (bugs, outages) — logged and surfaced as a
  safe generic message to the user.
- Never catch-and-ignore. Never `catch (e) {}`.

---

## Security baseline

Applies everywhere; stacks add specifics.

- **No secrets in code or git.** Credentials, keys, and tokens come from environment /
  secret stores, never literals, never committed.
- **Validate and sanitise all external input.** Treat everything from a client, a
  third-party API, or a file as hostile until validated.
- **Parameterise queries.** Never build SQL (or any query language) by string
  concatenation.
- **Authorise every protected action**, not just authenticate. Check that *this* user may
  do *this* thing to *this* resource.
- **Least privilege.** Tokens, DB users, service accounts, and SharePoint groups get the
  minimum access they need.
- **Encode output** to its context (HTML, URL, attribute) to prevent injection/XSS.
- **Don't leak internals** in error responses (no stack traces, no SQL, no paths to the
  client).

---

## Comments & documentation

- The code explains *what*. Comments explain *why* — a non-obvious decision, a tradeoff,
  a workaround for an external constraint.
- A public unit (exported function, API endpoint, reusable component) gets a one-line doc
  of its contract: inputs, output, and what it guarantees.
- Delete comments that merely restate the code. They rot and mislead.

---

## Version control

- Small, focused commits. One logical change per commit.
- Commit messages: imperative mood, present tense — `add invoice retry handler`, not
  `added` or `adding`. First line ≤ ~70 chars; body explains *why* if not obvious.
- Conventional prefixes encouraged: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`,
  `docs:`.
- Never commit secrets, build artefacts, or `node_modules`/`vendor`.

---

## Performance baseline

- No work in a loop that belongs outside it.
- No query inside a loop (the N+1 trap) — batch or eager-load.
- Don't load more data than you render or use.
- Cache deliberately and invalidate explicitly; an undocumented cache is a future bug.
- Measure before optimising anything non-obvious. Don't trade readability for speed you
  haven't proven you need.
