---
name: agentsync
description: Multi-agent progress sync framework. Install a shared .progress/ directory and rule files so Claude Code, Codex, OpenCode, Kimi Code, OpenClaw, Grok Build, Antigravity, and Cursor can coordinate on the same project. Use when updating the skill with /agentsync update or "update agentsync".
triggers: agentsync, agent sync, multi-agent, init progress sync, sync agents, collabkit, update agentsync, agentsync update
allowed-tools: AskUserQuestion, Read, Write, Glob, Grep, Shell
metadata:
  version: "1.1.0"
---

# AgentSync

Lightweight multi-agent coordination through shared progress files.

There are two types of data in this system:

- **Progress** (automatic) — 5-line micro-logs agents write when a phase completes. Lightweight, routine, for daily sync. Agents read these automatically via rule files; the user does not trigger this.
- **Handoff** (manual) — Detailed session reports generated on demand. Rich context, decisions, causality. For urgent agent migration when the project is large or the conversation is long. Not for daily use.

## Interaction Rules

**Language** — Before any prompt, detect the user's language from conversation context. Use **Chinese** when any of these is true:
- The user's latest message is in Chinese
- The project `README.md` is primarily Chinese (e.g. bilingual repo with Chinese first)
- The workspace path contains CJK characters

Otherwise use English. **Never default to English** when context is Chinese.

**Choice UI** — Every user decision MUST use the choice-box tool, not plain chat:
- Grok Build / Claude Code → `AskUserQuestion`
- Cursor → `AskQuestion`

**Forbidden:** listing numbered options in chat and waiting for a typed reply. **Required:** call the choice-box tool first, then act on the answer.

When the user invokes this skill, **immediately** show the option menu via the choice-box tool. Do not skip the menu or guess the option.

## Option Menu

Call `AskUserQuestion` (or `AskQuestion` in Cursor) with exactly these three options. Localize `question`, `header`, `label`, and `description` to the detected language.

**English example:**

```
AskUserQuestion({
  questions: [{
    header: "Action",
    question: "What do you want to do?",
    multiSelect: false,
    options: [
      { label: "Init", description: "First-time setup — create .progress/ and agent rule files" },
      { label: "Handoff", description: "Generate a full session handoff report" },
      { label: "Sync", description: "Read handoffs + progress and present full sync" }
    ]
  }]
})
```

**Chinese example:**

```
AskUserQuestion({
  questions: [{
    header: "操作",
    question: "你想做什么？",
    multiSelect: false,
    options: [
      { label: "Init 初始化", description: "首次安装 — 创建 .progress/ 目录和 Agent 规则文件" },
      { label: "Handoff 交接", description: "生成本次会话的完整交接报告" },
      { label: "Sync 同步", description: "读取 handoff + progress，呈现完整同步视图" }
    ]
  }]
})
```

Typical flow:
- First run → **Init**
- Long session, switching agents → **Handoff**
- New agent or returning after a break → **Sync**

### Update shortcut

If the user says **update agentsync**, **更新 agentsync**, or passes `update` as an argument (`/agentsync update`), skip the menu and run the updater script for the current agent host:

**macOS / Linux / WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/install.sh | bash
```

**Windows PowerShell:**
```powershell
irm https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/install.ps1 | iex
```

To update only specific agents, append flags:
```bash
curl -fsSL .../install.sh | bash -s -- --agents grok,claude
```

After the script finishes, read the local `SKILL.md` version from `metadata.version` and confirm the update to the user in their language.

---

## Init

Guide the user through setup with **choice-box prompts only** — one `AskUserQuestion` call per step. Do not ask setup questions in plain chat. After each answer, call the next `AskUserQuestion` until all steps are done, then generate files.

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

`AskUserQuestion` with `multiSelect: true`. Options (localize labels):

- Claude Code
- Codex
- OpenCode
- Kimi Code
- OpenClaw
- Grok Build
- Antigravity
- Cursor

If the user picks "Other", follow up with one more `AskUserQuestion` or accept free text only for the custom agent name.

### Step 2: Project location

`AskUserQuestion` with `multiSelect: false`:

- **Current workspace** — use the workspace path from session context (preferred default)
- **Other** — user provides a custom path via the tool's Other field

Store the result as `project_path`.

### Step 3: Environment for each agent

First `AskUserQuestion`: "Do all selected agents share the same runtime environment?" (Yes / No).

- **Yes** → one environment `AskUserQuestion` for all agents
- **No** → one environment `AskUserQuestion` per selected agent

Environment options (localize):

- **Windows native** — paths like `E:\...`
- **WSL** — paths like `/mnt/e/...`
- **macOS / Linux native** — paths like `/home/...`
- **Docker / remote** — user provides path mapping via Other

Example: Claude Code → WSL (`/mnt/e/webnovel.agent`); Codex → Windows native (`E:\webnovel.agent`).

### Step 4: Existing files?

Check which rule files already exist, then `AskUserQuestion` per file that exists (skip missing ones). Only ask about `GEMINI.md` if Antigravity is selected; only ask about `.grok/rules/` if Grok Build is selected.

Options per file: **Overwrite** / **Append** / **Skip**

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

`AskUserQuestion`: exclude `AGENTS.md`, `GEMINI.md`, and `.progress/` from git? Options: **Yes** / **No** (localize).

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

When the user chooses this option, perform a **full sync** for agent handover. Sync reads both data types:

- **Handoffs** — complete session reports (`.progress/handoffs/`)
- **Progress** — 5-line micro-logs (`.progress/{agent}/`)

A large project may accumulate many progress files. Do **not** read them all verbatim. Use the tiered strategy below to stay useful without blowing the context budget.

### Sync reading limits

| Tier | Source | What to read | Default cap |
|------|--------|--------------|-------------|
| **Full** | Handoffs | Latest report per agent | 1 per agent, full content |
| **Full** | Progress | Most recent entries | 2 per agent, full 5 lines each |
| **Compact** | Progress | Older entries | Up to 20 per agent, metadata table only |
| **Omit** | Progress | Everything older | Count only — do not load content |

Global cap: stop adding compact rows after **80 total** across all agents. Note what was omitted.

Sort all files by timestamp (parse `YYYY-MM-DD-HHmm` from filename; fall back to file mtime).

### Sync procedure

1. **Discover** — List every `.progress/{agent}/` subdirectory (exclude `handoffs/`). If `.progress/` is missing, tell the user to run **Init** first.

2. **Handoffs (full tier)** — In `.progress/handoffs/`:
   - Group files by agent prefix (`claude`, `codex`, `grok`, …).
   - Read the **latest** report per agent in full.
   - Older handoffs → compact index table only (filename + date + first heading).
   - If no handoffs exist, say so — progress alone may still be enough for short gaps.

3. **Progress (full tier)** — For each agent directory:
   - Read the **latest 2** `.md` files in full (same depth agents use in rule files).
   - Present under `## Progress — Recent`.

4. **Progress (compact tier)** — For older files (3rd newest and beyond):
   - Parse only the 5 fields: `time`, `task`, `status`, `changed`, `note`.
   - Present as a table — do not repeat full note text if longer than one line; truncate.

```
| Agent | Time | Task | Status | Changed |
|-------|------|------|--------|---------|
| Codex | 2026-07-01 09:00 | auth refactor | done | src/auth.ts |
```

5. **Progress (omit tier)** — If an agent has more entries than the compact cap:

```
Codex: 47 older entries omitted — see .progress/codex/
```

6. **Alerts** — Scan full + compact tiers for:
   - `status: blocked` → flag prominently
   - `status: in_progress` on multiple agents touching the same path in `changed:` → potential conflict
   - No progress from an agent in 7+ days → stale
   - Handoff exists but is older than the latest progress from that agent → note that progress may be more current

7. **Present** — Output in this order:

```
# AgentSync — Full Sync

## Summary
(one paragraph: who did what recently, active/blocked items, whether handoffs exist)

## Alerts
(only if any)

## Handoffs
(full content — latest per agent)

## Progress — Recent
(full 5-line entries — latest 2 per agent)

## Progress — History
(compact table — older entries)

## Omitted
(counts only, if any)
```

8. **Optional deep dive** — If one agent has heavy history and the user cares, ask whether to expand that agent's compact window (e.g. 10 more rows). Do not expand automatically.

### Sync vs automatic progress

- Agents auto-read the latest 2 progress files on session start (via rule files).
- Sync is the **manual, full handover** view: handoffs + tiered progress + alerts.
- Sync is user-triggered; the agent should not run Sync on every session start.
