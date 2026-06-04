#!/usr/bin/env python3
"""
generate-adapters.py — build the thin per-IDE wiring from the single source of truth.

Reads the frontmatter of every file in team/agents/ and (re)generates:
  - .claude/agents/<name>.md   (Claude Code spawnable subagents)
  - .cursor/rules/00-team.mdc  (Cursor always-applied rule)
  - AGENTS.md                  (universal entry point + roster)
  - .codex/ and .antigravity/  (pointers to AGENTS.md)

The agent personas live ONLY in team/agents/. These adapters just point back to them,
so editing a persona once updates every IDE. Run from the project root.
"""

import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AGENTS_DIR = os.path.join(ROOT, "team", "agents")

# neutral model tiers -> Claude Code model aliases
CLAUDE_MODEL = {"strong": "opus", "mid": "sonnet", "fast": "haiku"}

def parse_frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        return {}
    fm, out, key = m.group(1), {}, None
    for line in fm.splitlines():
        if re.match(r"^\s+", line) and key:            # continuation (folded scalar)
            out[key] = (out[key] + " " + line.strip()).strip()
            continue
        mm = re.match(r"^([a-zA-Z_]+):\s*(.*)$", line)
        if mm:
            key, val = mm.group(1), mm.group(2).strip()
            if val in (">", "|", ">-", "|-"):
                out[key] = ""
            else:
                out[key] = val.strip('"')
    return out

def load_agents():
    agents = []
    for fn in sorted(os.listdir(AGENTS_DIR)):
        if not fn.endswith(".md"):
            continue
        fm = parse_frontmatter(open(os.path.join(AGENTS_DIR, fn), encoding="utf-8").read())
        if fm.get("name"):
            fm["_file"] = fn
            agents.append(fm)
    return agents

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("  wrote", os.path.relpath(path, ROOT))

# ---------- Claude Code ----------
def gen_claude(agents):
    for a in agents:
        name, title = a["name"], a.get("title", a["name"])
        model = CLAUDE_MODEL.get(a.get("model", "mid"), "sonnet")
        desc = a.get("description", title).strip()
        read_only = a.get("access") == "read-only"
        tools = "tools: Read, Grep, Glob, Bash\n" if read_only else ""
        deny = "disallowedTools: Write, Edit, MultiEdit\n" if read_only else ""
        body = (
            f"---\n"
            f"name: {name}\n"
            f"description: {desc}\n"
            f"model: {model}\n"
            f"{tools}{deny}"
            f"---\n\n"
            f"You are the **{title}**.\n\n"
            f"Your authoritative instructions are in two files. Read them in full and embody "
            f"them completely before doing anything:\n\n"
            f"1. `team/agents/{a['_file']}` — your role, lane, and how you work.\n"
            f"2. `team/foundation/operating-protocol.md` — the team constitution.\n\n"
            f"Follow any stack-standard files your role file references. Those files are the "
            f"single source of truth; this wrapper only points to them.\n"
        )
        w(os.path.join(ROOT, ".claude", "agents", f"{name}.md"), body)
    # root CLAUDE.md so the main session knows the entry point
    w(os.path.join(ROOT, "CLAUDE.md"),
      "# Project — agent team\n\n"
      "This project is run by a specialist agent team. The team's brain lives in `team/` "
      "and all shared state in `briefs/`.\n\n"
      "**Talk to the CEO.** It is the entry point: it reads `briefs/STATUS.md` first, then "
      "routes work. Say *“CEO, start working on X”*, *“CEO, resume”*, *“CEO, status”*, or "
      "*“CEO, sign off”*.\n\n"
      "Spawnable subagents are in `.claude/agents/` (generated from `team/agents/` — edit "
      "the persona in `team/agents/`, never the wrapper). Read "
      "`team/foundation/operating-protocol.md` for how the team operates.\n")

# ---------- Cursor ----------
def gen_cursor(agents):
    roster = "\n".join(
        f"- **{a.get('title', a['name'])}** (`@{a['name']}` → `team/agents/{a['_file']}`) — "
        f"{a.get('type','')}"
        for a in agents)
    body = (
        "---\n"
        "description: Specialist agent team — roles, protocol, and how to act as one\n"
        "globs:\n"
        "alwaysApply: true\n"
        "---\n\n"
        "# Agent team\n\n"
        "This project is run by a specialist agent team. The brain lives in `team/`, shared "
        "state in `briefs/`.\n\n"
        "**Entry point:** act as the **CEO** unless told otherwise. The CEO reads "
        "`briefs/STATUS.md` first, then routes work. Commands: *start working on X*, "
        "*resume*, *status*, *sign off*.\n\n"
        "**To act as a specialist,** open and fully follow that role's file in "
        "`team/agents/`, plus `team/foundation/operating-protocol.md` (the constitution) and "
        "any stack standard the role references. Stay strictly in that role's lane.\n\n"
        "## Roster\n" + roster + "\n\n"
        "## Always\n"
        "- Read `briefs/STATUS.md` before answering “where are we / what's next”.\n"
        "- Hand off via pointers to files in `briefs/`, never by pasting their contents.\n"
        "- Log decisions in `briefs/DECISIONS.md`; keep `briefs/STATUS.md` current.\n"
        "- Obey the producer→implementer boundaries; never let one agent do another's job.\n")
    w(os.path.join(ROOT, ".cursor", "rules", "00-team.mdc"), body)

# ---------- AGENTS.md (universal) ----------
def gen_agents_md(agents):
    rows = "\n".join(
        f"| {a.get('title', a['name'])} | `{a.get('type','')}` | `team/agents/{a['_file']}` |"
        for a in agents)
    body = (
        "# AGENTS.md — entry point for any agentic tool\n\n"
        "This repository is run by a specialist agent team. This file is the universal entry "
        "point that AGENTS.md-aware tools (Codex, Antigravity, Cursor, and others) read. "
        "Claude Code additionally uses `CLAUDE.md` + `.claude/agents/`.\n\n"
        "## How it works\n\n"
        "- The team's brain (roles + standards) lives in **`team/`** — the single source of "
        "truth, tool-neutral.\n"
        "- All shared project state lives in **`briefs/`** — requirements, specs, decisions, "
        "and `STATUS.md` (the board).\n"
        "- You talk to the **CEO**, the orchestrator. It reads `briefs/STATUS.md` first, then "
        "routes work to the right specialist. Commands: *start working on X*, *resume*, "
        "*status*, *sign off*.\n\n"
        "## To act as the team\n\n"
        "1. Default to the **CEO** role: read `team/agents/ceo.md` and "
        "`team/foundation/operating-protocol.md`, then follow them.\n"
        "2. The CEO dispatches a specialist by pointing at that role's file below. To *be* "
        "that specialist, read its file (plus the protocol and any stack standard it "
        "references) and stay strictly in its lane.\n"
        "3. Producers (UX/UI, DBMS Architect, SharePoint Architect) write specs to "
        "`briefs/specs/`; implementers build against those specs. Never blur the two.\n"
        "4. Hand off via file pointers, not pasted content. Log decisions in "
        "`briefs/DECISIONS.md`; keep `briefs/STATUS.md` current.\n\n"
        "## Roster\n\n"
        "| Agent | Type | Definition |\n| ----- | ---- | ---------- |\n" + rows + "\n\n"
        "## Standards\n\n"
        "- `team/foundation/operating-protocol.md` — the constitution (read first).\n"
        "- `team/foundation/engineering-standards.md` — cross-cutting rules + Definition of "
        "Done.\n"
        "- `team/foundation/stack-standards/` — per-stack rules (React, Laravel, MySQL, "
        "Flutter, SPFx, Power Automate).\n")
    w(os.path.join(ROOT, "AGENTS.md"), body)

# ---------- pointers for AGENTS.md-based tools ----------
def gen_pointers():
    for tool in (".codex", ".antigravity"):
        w(os.path.join(ROOT, tool, "README.md"),
          f"# {tool[1:].title()} wiring\n\n"
          f"This tool reads **`AGENTS.md`** at the repository root as the entry point for the "
          f"agent team. Nothing tool-specific is needed here — the team's brain is in `team/` "
          f"and state in `briefs/`. Open the project and ask the **CEO** to start, resume, or "
          f"report status.\n")

def main():
    agents = load_agents()
    if not agents:
        sys.exit("No agents found in team/agents/")
    print(f"Generating adapters from {len(agents)} agents...")
    gen_claude(agents)
    gen_cursor(agents)
    gen_agents_md(agents)
    gen_pointers()
    print("Done.")

if __name__ == "__main__":
    main()
