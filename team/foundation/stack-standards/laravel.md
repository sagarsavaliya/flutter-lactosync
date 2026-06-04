# Stack Standard — Laravel

For the **Laravel Engineer** (API + migrations). Read alongside `engineering-standards.md`.
Implements the DBMS Architect's schema and the API contract — it does not design the
schema itself.

Versions are pinned per-project in `briefs/`. This file is about patterns.

---

## Non-negotiables

- **Thin controllers.** A controller validates, delegates to a single action/service, and
  returns a response. No business logic, no queries, no conditionals on domain rules.
- **Build migrations to the schema spec.** The DBMS Architect decides tables, columns,
  types, relations, and indexes (`briefs/specs/`). The Laravel Engineer turns that into
  migrations and Eloquent models faithfully — it does not freelance the schema. A schema
  gap is a clarification (§8), routed to the DBMS Architect.

---

## Architecture — clean, layered

```
app/
├── Http/
│   ├── Controllers/Api/V1/   # thin: validate → delegate → respond
│   ├── Requests/             # FormRequest validation (one per action)
│   └── Resources/            # API response shaping (never return raw models)
├── Actions/  (or Services/)  # one use-case each; the business logic lives here
├── Models/                   # Eloquent; relations + casts + scopes only
├── Policies/                 # authorisation
└── Jobs/                     # async work
```

The use-case layer (Actions/Services) is the heart. It knows the business rules and knows
nothing about HTTP. You could call it from a controller, a command, or a job unchanged —
that's the clean-architecture test.

---

## API design

- **Version every API**: `/api/v1/...`. Breaking changes go to `v2`, never silently.
- **Resource-oriented routes**, RESTful verbs. Plural nouns: `/api/v1/invoices`.
- **Consistent response envelope** for every endpoint — success and error share one
  shape. Decide it once per project (in the brief) and never deviate. Example shape:
  `{ data, meta }` on success, `{ message, errors }` on failure.
- **Correct status codes**: 200/201/204, 422 for validation, 401/403 for auth, 404, 409,
  500. Never return 200 with an error body.
- **API Resources** shape every response. Never return an Eloquent model or array
  directly — that leaks columns and couples the API to the schema.

---

## Validation

- Every write endpoint has a **FormRequest**. Validation rules and authorisation
  (`authorize()`) live there, out of the controller.
- Validate types, presence, ranges, and relationships (e.g. `exists`). Fail with 422 and
  field-level messages.

---

## Eloquent

- **Eager-load to kill N+1.** Any time you loop over a collection and touch a relation,
  it must be eager-loaded (`with()`). The Code Reviewer specifically hunts for this.
- Relations, casts, and query scopes belong on the model. Business logic does not.
- Use mass-assignment protection (`$fillable`) deliberately.
- Heavy reads use pagination, never unbounded `all()`.
- Wrap multi-write operations in transactions.

---

## Authentication & authorisation

- API auth via tokens (e.g. Sanctum) per the project brief.
- **Authorise every protected action** with Policies — authentication is not
  authorisation. Check this user may act on this resource.

---

## Async & reliability

- Anything slow or external (email, third-party API, heavy compute) goes to a **queued
  Job**, not the request cycle.
- Jobs are **idempotent** where they can be retried, and have sensible retry/backoff and a
  failure handler. A failed job logs context, never disappears.

---

## Errors

- Centralise API error handling so every failure returns the project's error envelope —
  no stack traces or SQL to the client.
- Expected failures (not-found, validation, forbidden) return their proper codes;
  unexpected ones log full context server-side and return a safe generic 500.

---

## Testing

- **Feature tests** for every endpoint: happy path, validation failure, auth failure,
  not-found. Use Pest (or the project's chosen runner).
- **Unit tests** for non-trivial actions/services.
- Use factories and a transactional/refreshing test database.

---

## Do NOT

- Put business logic or queries in controllers.
- Return raw models/arrays from the API (always a Resource).
- Design or alter the schema on your own — that's the DBMS Architect's spec.
- Write frontend, SQL-by-hand, or deploy config. Hand off (§7).
- Leave an N+1, an unbounded query, or an untransacted multi-write.
