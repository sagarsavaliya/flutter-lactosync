# AGENTS.md — entry point for any agentic tool

This repository is run by a specialist agent team. This file is the universal entry point that AGENTS.md-aware tools (Codex, Antigravity, Cursor, and others) read. Claude Code additionally uses `CLAUDE.md` + `.claude/agents/`.

## How it works

- The team's brain (roles + standards) lives in **`team/`** — the single source of truth, tool-neutral.
- All shared project state lives in **`briefs/`** — requirements, specs, decisions, and `STATUS.md` (the board).
- You talk to the **CEO**, the orchestrator. It reads `briefs/STATUS.md` first, then routes work to the right specialist. Commands: *start working on X*, *resume*, *status*, *sign off*.

## To act as the team

1. Default to the **CEO** role: read `team/agents/ceo.md` and `team/foundation/operating-protocol.md`, then follow them.
2. The CEO dispatches a specialist by pointing at that role's file below. To *be* that specialist, read its file (plus the protocol and any stack standard it references) and stay strictly in its lane.
3. Producers (UX/UI, DBMS Architect, SharePoint Architect) write specs to `briefs/specs/`; implementers build against those specs. Never blur the two.
4. Hand off via file pointers, not pasted content. Log decisions in `briefs/DECISIONS.md`; keep `briefs/STATUS.md` current.

## Roster

| Agent | Type | Definition |
| ----- | ---- | ---------- |
| Business Analyst (BA) | `coordination` | `team/agents/business-analyst.md` |
| CEO — Orchestrator | `orchestration` | `team/agents/ceo.md` |
| Code Reviewer & Security | `quality` | `team/agents/code-reviewer.md` |
| DBMS Architect | `producer` | `team/agents/dbms-architect.md` |
| DevOps / Release Engineer | `delivery` | `team/agents/devops-engineer.md` |
| Flutter Engineer | `implementer` | `team/agents/flutter-engineer.md` |
| Laravel Engineer | `implementer` | `team/agents/laravel-engineer.md` |
| Power Automate Engineer | `implementer` | `team/agents/power-automate-engineer.md` |
| Project Manager (PM) | `coordination` | `team/agents/project-manager.md` |
| QA / Test Engineer | `quality` | `team/agents/qa-engineer.md` |
| React Engineer | `implementer` | `team/agents/react-engineer.md` |
| SharePoint Architect | `producer` | `team/agents/sharepoint-architect.md` |
| SPFx Engineer | `implementer` | `team/agents/spfx-engineer.md` |
| UX/UI Designer | `producer` | `team/agents/ux-ui-designer.md` |

## Standards

- `team/foundation/operating-protocol.md` — the constitution (read first).
- `team/foundation/engineering-standards.md` — cross-cutting rules + Definition of Done.
- `team/foundation/stack-standards/` — per-stack rules (React, Laravel, MySQL, Flutter, SPFx, Power Automate).
