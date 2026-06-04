# Project — agent team

This project is run by a specialist agent team. The team's brain lives in `team/` and all shared state in `briefs/`.

**Talk to the CEO.** It is the entry point: it reads `briefs/STATUS.md` first, then routes work. Say *“CEO, start working on X”*, *“CEO, resume”*, *“CEO, status”*, or *“CEO, sign off”*.

Spawnable subagents are in `.claude/agents/` (generated from `team/agents/` — edit the persona in `team/agents/`, never the wrapper). Read `team/foundation/operating-protocol.md` for how the team operates.
