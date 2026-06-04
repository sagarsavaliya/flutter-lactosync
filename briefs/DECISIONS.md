# DECISIONS — <project name>

Every resolved question and decision is logged here — both PM escalations and peer-to-peer
clarifications. A decision that lives only in one exchange is invisible to QA, to the next
sprint, and to the human. Newest at the top.

Format per entry:

---

### <date> — <short title>

- **Context / question:** <what came up>
- **Decided by:** <peer-to-peer between X and Y | PM | human>
- **Decision:** <the answer, precisely>
- **Affects:** <stories / contracts / files impacted>
- **New work?** <no | yes → story S_ created>

---

### <date> — Example: invoice date format

- **Context / question:** React needed the date format returned by `GET /api/v1/invoices`.
- **Decided by:** peer-to-peer (React ↔ Laravel)
- **Decision:** API returns ISO 8601 UTC strings; client formats for display.
- **Affects:** S2 (invoice list UI), S5 (invoice API)
- **New work?** no
