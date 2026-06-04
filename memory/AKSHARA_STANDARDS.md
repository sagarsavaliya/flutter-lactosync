# AKSHARA TECHNOLOGIES — ENGINEERING STANDARDS
# This file is READ-ONLY. Never modify during project work.
# All developer agents must follow these standards without exception.

---

## SECTION 1 — TRANSACTION INTEGRITY & FAILURE HANDLING

### The Golden Rule
> Every multi-step operation must be resumable from exact point of failure.
> A user must NEVER lose their work due to a technical error.

### State Machine Pattern (Mandatory for all multi-step flows)
Every process with 2+ steps must have a `status` column:
```
PENDING → PROCESSING → COMPLETE
                    ↘ FAILED → ROLLED_BACK
```

Example — User Onboarding:
```
Step 1: INSERT user (status: PENDING)       ← safe, idempotent
Step 2: Send verification email             → if fails: status stays PENDING, user retries safely
Step 3: Email verified                      → status: EMAIL_VERIFIED
Step 4: Profile complete                    → status: PROFILE_COMPLETE
Step 5: Setup done                          → status: ACTIVE → redirect dashboard

On retry with same email:
→ Lookup existing record by email
→ Check status → resume from failed step
→ Never show "Email already exists" error
→ Show "Continue your registration" CTA
→ Zero support tickets
```

### Idempotency Rules (Mandatory on all CREATE operations)
- Every POST/CREATE endpoint accepts an `idempotency-key` header
- Same request sent twice = same result, no duplicates
- Store idempotency keys for minimum 24 hours
- Return cached response for duplicate requests

### Database Transaction Rules
- All multi-step DB operations wrapped in a single transaction
- On any failure → compensating transaction runs immediately (rollback)
- Soft deletes ONLY — never hard delete incomplete/partial records
- Audit log table for every critical operation (user_id, action, timestamp, old_value, new_value)
- Foreign key constraints enforced — no orphaned records

### API Failure Handling Rules
Every API call must handle all of:
- Network timeout → retry with exponential backoff (1s, 2s, 4s)
- 4xx errors → parse error code, show user-friendly message, stop retrying
- 5xx errors → retry max 3 times → if still failing, fail gracefully + save state
- Network drop mid-request → detect, save current state, allow resume

### User-Facing Error Messages
```
❌ Never: "SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry"
❌ Never: "500 Internal Server Error"
❌ Never: "Something went wrong"

✅ Always: "We couldn't complete your registration. Your progress is saved.
            Please try again or contact us at support@akshara.tech"
✅ Always: Include a resume token so user continues from exact step
✅ Always: Log the technical error server-side for debugging
```

### Retry & Resume Rules
- Max 3 automatic retries for transient failures
- After 3 retries → save state → show user clear next step
- Resume token stored in DB — user can continue from any device
- Never ask user to re-enter data they already submitted

---

## SECTION 2 — ALGORITHM & PERFORMANCE STANDARDS

### Performance Benchmarks (Non-negotiable before release)
| Operation | Maximum Allowed Time |
|---|---|
| Simple CRUD (create/read/update) | < 200ms |
| List/Table load (paginated) | < 500ms |
| Search results (any dataset size) | < 100ms |
| Dashboard load (all widgets) | < 800ms |
| Complex reports | < 2 seconds |
| File upload feedback | < 100ms (progress shown) |
| Background jobs | No limit (but show real-time progress) |

> Anything over 800ms for user-initiated action → must become a background job.

### Data Loading Rules
- NEVER load all records — server-side pagination mandatory
- Default page size: 25 records. Maximum: 100 records.
- Cursor-based pagination for datasets > 10,000 records (not offset-based)
- Skeleton screens mandatory — no blank loading states ever
- Lazy load images, heavy components, and below-fold content
- Debounce search inputs minimum 300ms before querying

### Algorithm Selection Rules
| Scenario | Use | Never Use |
|---|---|---|
| Search/lookup in collection | Hash map O(1) | Linear scan O(n) |
| Sorted data search | Binary search O(log n) | Linear search O(n) |
| Large list rendering | Virtual scrolling | Render all DOM nodes |
| Autocomplete | Trie / indexed search | Full string scan |
| Frequent reads, rare writes | Cache result | Query every time |
| Batch operations | Single bulk query | Loop with individual queries |

### Loop & Complexity Rules
- Flag any O(n²) algorithm on datasets > 100 items — must be optimized
- No database queries inside loops — EVER (N+1 problem = instant rejection)
- Use eager loading / JOINs — not lazy loading in loops
- Use bulk insert/update for batch operations

### Search Performance Rules (10L+ records)
```
For simple exact/prefix search:
→ B-tree index on search column → 40-80ms ✅

For full-text search (contains/partial):
→ GIN/GiST full-text index → 15-30ms ✅

For fuzzy/typo-tolerant search:
→ Trigram index (pg_trgm) or Meilisearch → 20-40ms ✅

For autocomplete (real-time as user types):
→ Redis sorted sets → 1-3ms ✅

For complex multi-field search on large datasets:
→ Elasticsearch/Meilisearch → 5-10ms ✅

NEVER: SELECT * WHERE name LIKE '%query%' on unindexed column
→ Full table scan → 3-8 seconds on 10L records ❌
```

### Database Query Rules
- Every search/filter column MUST have an appropriate index
- Composite indexes for frequently combined filter columns
- Parameterized queries ONLY — no string concatenation (SQL injection prevention)
- Run EXPLAIN ANALYZE on any query touching > 1,000 rows
- SELECT only required columns — never SELECT * in production code
- Avoid N+1: use eager loading (with/include/join) always

### Caching Rules
| Data Type | Cache Location | TTL |
|---|---|---|
| Static reference data (dropdowns, config) | In-memory / Redis | 24 hours |
| Search results | Redis | 5 minutes |
| User session | Redis | 30 minutes (sliding) |
| Dashboard aggregates | Redis | 15 minutes |
| User-specific financial/sensitive data | NEVER CACHE | — |
| API responses (public, read-only) | HTTP Cache-Control | 1 hour |

Cache invalidation must be defined BEFORE caching anything.

---

## SECTION 3 — API DESIGN STANDARDS

### API Contract Rules
- API contract (request/response schema) designed and approved BEFORE any coding
- RESTful conventions strictly followed
- Versioning mandatory: `/api/v1/`, `/api/v2/` — never break existing clients
- All endpoints documented with OpenAPI/Swagger spec

### Request/Response Standards
- All responses: `{ success, data, error, meta }` structure
- Error responses: `{ success: false, error: { code, message, details, resumeToken } }`
- Never expose stack traces or DB errors in API responses
- Response payload size limits: max 1MB per response (paginate or compress otherwise)
- GZIP compression enabled on all API responses

### Idempotency & Rate Limiting
- POST/PUT endpoints support `Idempotency-Key` header
- Rate limits defined per endpoint type:
  - Auth endpoints: 5 requests/minute
  - Search endpoints: 30 requests/minute
  - Standard CRUD: 100 requests/minute
  - Background/bulk: queue-based, no rate limit

### Async Operations
- Operations > 800ms moved to background jobs
- Background jobs return `{ jobId, statusUrl }` immediately
- Client polls `statusUrl` or receives WebSocket/SSE update
- Job progress stored in Redis, retrievable by jobId

---

## SECTION 4 — CODE QUALITY STANDARDS

### General Rules (All Languages)
- Meaningful variable/function names — no single letters except loop counters
- Functions do ONE thing — max 30 lines per function
- No magic numbers — use named constants
- Comments explain WHY, not WHAT (code explains what)
- No commented-out code in commits — use git history
- Environment variables for all config — never hardcode credentials

### Security Standards
- Input validation on ALL user inputs (client + server side)
- Parameterized queries — zero tolerance for SQL injection
- HTTPS everywhere — no HTTP in production
- Auth tokens stored in httpOnly cookies — never localStorage
- Rate limiting on all auth endpoints
- OWASP Top 10 checklist before every release
- Sensitive data encrypted at rest (passwords: bcrypt, PII: AES-256)

### Frontend Standards (React/Flutter/SPFx)
- TypeScript mandatory for all React and SPFx projects
- Component files max 200 lines — split if larger
- Custom hooks for all reusable logic
- No inline styles — use design system tokens
- Accessibility attributes (aria-label, role, tabIndex) on all interactive elements
- All images have alt text
- Forms have proper label associations

### Mobile Standards (Flutter)
- BLoC or Riverpod for state management — no setState in business logic
- Offline-first where possible — cache critical data locally
- Handle no-internet gracefully — show clear offline state
- Test on low-end Android devices (not just flagship/emulator)

### Backend Standards (Laravel/ASP.NET)
- Repository pattern for data access layer
- Service layer for business logic — no business logic in controllers
- Request validation classes — not inline validation
- Jobs/Queues for heavy operations
- Event-driven architecture for cross-module communication

---

## SECTION 5 — QA GATE CHECKLIST
Before any code is marked complete, QA Agent verifies:

### Failure Scenarios
- [ ] What happens if network drops at step 2 of 5?
- [ ] Can this flow be safely retried without duplicates?
- [ ] What does user see on each failure type?
- [ ] Can user resume without support intervention?
- [ ] Are all DB operations properly rolled back on failure?

### Performance
- [ ] No N+1 queries (checked with query logger)
- [ ] All lists paginated (no full load)
- [ ] All search columns indexed
- [ ] Benchmark targets met (see Section 2)
- [ ] Load tested at 10x expected traffic

### Security
- [ ] All inputs validated and sanitized
- [ ] No sensitive data in logs or error messages
- [ ] Auth required on all protected endpoints
- [ ] Rate limiting active

### Design Compliance
- [ ] 3-second rule passed
- [ ] Mobile responsive verified
- [ ] WCAG 2.1 AA compliance checked
- [ ] Error states designed and implemented
- [ ] Loading states implemented
- [ ] Empty states implemented
