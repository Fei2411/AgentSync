---
name: agentsync
description: Multi-agent progress sync framework. Install a shared .progress/ directory and rule files so Claude Code, Codex, OpenCode, Kimi Code, OpenClaw, Grok Build, Antigravity, and Cursor can coordinate on the same project.
triggers: agentsync, agent sync, multi-agent, init progress sync, sync agents, collabkit
---

# AgentSync

Lightweight multi-agent coordination through shared progress files.

There are two types of data in this system:

- **Progress** (automatic) — 5-line micro-logs agents write when a phase completes. Lightweight, routine, for daily sync.
- **Handoff** (manual) — Detailed session reports generated on demand. Rich context, decisions, causality, for deep agent transitions.

When the user invokes this skill, present three options and execute the chosen one.

## Option Menu

Ask the user to choose:

1. **Init** - Set up the collaboration framework for this project
2. **Handoff** - Generate a detailed session handoff report (not the same as progress — this is a full session review with context, decisions, and next steps)
3. **Sync** - Scan and display all agents' latest progress

---

## Init

Guide the user through setup with a conversational flow. Ask one question at a time, wait for answers, then generate the correct files based on their environment.

### Agent Rule File Reference

| Agent | Auto-reads | Progress directory | Status |
|-------|-----------|-------------------|--------|
| Claude Code | `CLAUDE.md` | `.progress/claude/` | ✅ Verified |
| Codex | `AGENTS.md` | `.progress/codex/` | ✅ Verified |
| OpenCode | `AGENTS.md` | `.progress/opencode/` | ✅ Mostly works |
| Kimi Code | `AGENTS.md` | `.progress/kimi/` | ✅ Verified |
| OpenClaw | `AGENTS.md` | `.progress/openclaw/` | 🔧 Untested |
| Grok Build | `AGENTS.md`, `.grok/rules/*.md` | `.progress/grok/` | ✅ Verified |
| Antigravity | `GEMINI.md` | `.progress/antigravity/` | 🔧 Untested |
| Cursor | `AGENTS.md` (also `.cursor/rules/*.mdc`) | `.progress/cursor/` | ✅ Verified |

Official sources:
- Grok Build: reads `AGENTS.md` and `.grok/rules/*.md` (Grok Build user guide: Project Rules)
- Antigravity: reads `GEMINI.md` by default ([Gemini CLI context files](https://geminicli.com/docs/cli/gemini-md/)); Antigravity CLI is the successor to Gemini CLI
- Cursor: reads root and nested `AGENTS.md` ([Cursor rules docs](https://cursor.com/docs/context/rules)); `.cursor/rules/*.mdc` is an optional alternative

### Step 1: Which agents do you use?

Ask the user to select all that apply:

- Claude Code
- Codex
- OpenCode
- Kimi Code
- OpenClaw
- Grok Build
- Antigravity
- Cursor
- Other (ask for the name)

### Step 2: Project location

Ask: Where is your project located?

Example answer: `E:\webnovel.agent` or `/home/user/project`

Store this as the `project_path`.

### Step 3: Environment for each agent

For each agent the user selected, ask: What environment does [agent] run in?

Options:
- **Windows native** — uses Windows paths like `E:\...`
- **WSL** — uses `/mnt/e/...` style paths
- **macOS / Linux native** — uses Unix paths like `/home/...`
- **Docker / remote** — ask for the path mapping

This determines the path format each agent's rule file will use.

Example scenario:
- Claude Code → WSL (needs `/mnt/e/webnovel.agent`)
- Codex → Windows native (needs `E:\webnovel.agent`)

### Step 4: Existing files?

Ask:
- Does the project already have a CLAUDE.md? (yes/no)
- Does the project already have an AGENTS.md? (yes/no)
- Does the project already have a GEMINI.md? (yes/no, only if Antigravity is selected)
- Does the project already have `.grok/rules/` files? (yes/no, only if Grok Build is selected)

If yes, ask whether to overwrite or append.

### Step 5: Create directories

```bash
mkdir -p .progress/{selected_agents...},handoffs
```

Only create directories for the agents the user selected.

### Step 6: Generate CLAUDE.md

If the user uses Claude Code, create a CLAUDE.md with paths adjusted to the environment from Step 3.

**Example: Claude Code in WSL, project at `E:\webnovel.agent`**

```
# Multi-Agent Progress Sync

I am Claude Code.

The Windows project path `E:\webnovel.agent` maps to this WSL path:

`/mnt/e/webnovel.agent`

Use the shared progress directory inside the project:

- Read the latest 2 `.md` reports from `/mnt/e/webnovel.agent/.progress/codex/`.
- Read the latest 2 `.md` reports from `/mnt/e/webnovel.agent/.progress/opencode/`.
- Read the latest 2 `.md` reports from `/mnt/e/webnovel.agent/.progress/kimi/`.
- When a phase is completed, work is paused, or handoff is needed, write progress to `/mnt/e/webnovel.agent/.progress/claude/YYYY-MM-DD-HHmm.md`.

Keep each progress report to at most 5 lines:

- time:
- task:
- status:
- changed:
- note:

Only write to `.progress/claude/`. Do not delete old progress files.
```

**Example: Claude Code on macOS/Linux, project at `/home/user/project`**

```
# Multi-Agent Progress Sync

I am Claude Code.

Use the shared progress directory inside the project:

- Read the latest 2 `.md` reports from `.progress/codex/`.
- Read the latest 2 `.md` reports from `.progress/opencode/`.
- Read the latest 2 `.md` reports from `.progress/kimi/`.
- When a phase is completed, work is paused, or handoff is needed, write progress to `.progress/claude/YYYY-MM-DD-HHmm.md`.

Keep each progress report to at most 5 lines:

- time:
- task:
- status:
- changed:
- note:

Only write to `.progress/claude/`. Do not delete old progress files.
```

Adjust the "Read from" lines based on which agents the user selected. Only include directories for agents that exist.

### Step 7: Generate AGENTS.md

If the user uses Codex, OpenCode, Kimi Code, OpenClaw, Grok Build, or Cursor, create an AGENTS.md with "If you are X" blocks for each selected agent. Antigravity uses `GEMINI.md` (Step 8), not AGENTS.md.

```
# Multi-Agent Progress Sync

This project uses `.progress/` for lightweight multi-agent progress sync.

If you are Codex:
- Read the latest 2 `.md` reports from `.progress/opencode/` and `.progress/claude/`.
- Write progress only to `.progress/codex/YYYY-MM-DD-HHmm.md`.

If you are OpenCode:
- Read the latest 2 `.md` reports from `.progress/codex/` and `.progress/claude/`.
- Write progress only to `.progress/opencode/YYYY-MM-DD-HHmm.md`.

If you are Kimi Code:
- Read the latest 2 `.md` reports from `.progress/codex/` and `.progress/claude/` and `.progress/opencode/`.
- Write progress only to `.progress/kimi/YYYY-MM-DD-HHmm.md`.

If you are Grok Build:
- Read the latest 2 `.md` reports from `.progress/codex/` and `.progress/claude/` and `.progress/cursor/`.
- Write progress only to `.progress/grok/YYYY-MM-DD-HHmm.md`.

If you are Cursor:
- Read the latest 2 `.md` reports from `.progress/codex/` and `.progress/claude/` and `.progress/grok/`.
- Write progress only to `.progress/cursor/YYYY-MM-DD-HHmm.md`.

Write progress only when a phase is completed, work is paused, or handoff is needed.

Keep each progress report to at most 5 lines:

- time:
- task:
- status:
- changed:
- note:

Only write to your own directory. Do not delete old progress files.
```

Only include "If you are X" blocks for agents the user actually uses. Remove the others. Each agent's "Read from" lines should list every other selected agent's directory except its own.

If the user selected Grok Build but not other AGENTS.md consumers, also create `.grok/rules/agentsync.md` with the Grok Build block content (Grok scans this directory natively).

### Step 8: Generate GEMINI.md

If the user uses Antigravity, create a `GEMINI.md` with paths adjusted to the environment from Step 3. Antigravity CLI (Google's `agy`, successor to Gemini CLI) loads `GEMINI.md` from the project root and ancestor directories by default.

**Example: Antigravity on Windows native, project at `E:\webnovel.agent`**

```
# Multi-Agent Progress Sync

I am Antigravity.

Use the shared progress directory inside the project:

- Read the latest 2 `.md` reports from `E:\webnovel.agent\.progress\codex\`.
- Read the latest 2 `.md` reports from `E:\webnovel.agent\.progress\claude\`.
- Read the latest 2 `.md` reports from `E:\webnovel.agent\.progress\cursor\`.
- When a phase is completed, work is paused, or handoff is needed, write progress to `E:\webnovel.agent\.progress\antigravity\YYYY-MM-DD-HHmm.md`.

Keep each progress report to at most 5 lines:

- time:
- task:
- status:
- changed:
- note:

Only write to `.progress/antigravity/`. Do not delete old progress files.
```

**Example: Antigravity on macOS/Linux, project at `/home/user/project`**

```
# Multi-Agent Progress Sync

I am Antigravity.

Use the shared progress directory inside the project:

- Read the latest 2 `.md` reports from `.progress/codex/`.
- Read the latest 2 `.md` reports from `.progress/claude/`.
- Read the latest 2 `.md` reports from `.progress/cursor/`.
- When a phase is completed, work is paused, or handoff is needed, write progress to `.progress/antigravity/YYYY-MM-DD-HHmm.md`.

Keep each progress report to at most 5 lines:

- time:
- task:
- status:
- changed:
- note:

Only write to `.progress/antigravity/`. Do not delete old progress files.
```

Adjust the "Read from" lines based on which agents the user selected. Only include directories for agents that exist.

### Step 9: Git exclusion

Ask: Do you want to exclude AGENTS.md, GEMINI.md, and .progress/ from git?

If yes, update `.git/info/exclude` (not .gitignore, to avoid polluting the project):

```
AGENTS.md
GEMINI.md
.progress/
```

### Step 10: Confirm

Summarize what was created:
- Which directories under .progress/
- Which rule files (CLAUDE.md, AGENTS.md, GEMINI.md, `.grok/rules/agentsync.md`) and where they were placed
- Path mappings applied (e.g., `E:\` → `/mnt/e/` for WSL)
- Git exclusion status
- Any existing files that were preserved or appended to

---

## Handoff

When the user chooses this option:

1. Review the current session's conversation context.
2. Run `git diff` to see all changes made in this session.
3. Generate a detailed handoff report with these sections:

```
# Session Handoff - [Agent Name] - [Date Time]

## Context
Why this work was done. What was the starting state.

## Decisions
Key choices made and why. Include alternatives considered.

## Changes
For each file changed:
- What was modified
- Why it was modified
- Any breaking changes

## Issues Encountered
Problems hit, how they were resolved, what to watch out for.

## Next Steps
What should be done next. Any pending tasks.

## Notes for Other Agents
Anything the next agent needs to know before picking up work.
```

4. Save to `.progress/handoffs/[agentname]_session_[YYYYMMDD]_[HHmm].md`
   - Claude Code → `claudecode_session_20260610_1435.md`
   - Codex → `codex_session_20260610_1435.md`
   - OpenCode → `opencode_session_20260610_1435.md`
   - Kimi Code → `kimi_session_20260610_1435.md`
   - OpenClaw → `openclaw_session_20260610_1435.md`
   - Grok Build → `grok_session_20260610_1435.md`
   - Antigravity → `antigravity_session_20260610_1435.md`
   - Cursor → `cursor_session_20260610_1435.md`

---

## Sync

When the user chooses this option:

1. Scan all `.progress/` subdirectories (excluding handoffs/).
2. Read the latest file in each directory.
3. Present a summary table:

```
| Agent | Last Active | Task | Status |
|-------|------------|------|--------|
| Claude | 2026-06-07 23:57 | Douyin analytics scan | done |
| Codex | 2026-06-06 00:30 | Deploy Worker | done |
```

4. If two agents' latest reports mention the same file, flag a warning:

```
Potential conflict: Claude and Codex both modified src/auth.ts
```

5. If any agent has no reports yet, show "No reports" for that agent.
