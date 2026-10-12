# AgentSync

[中文](./README.md) | **English**

Lightweight multi-agent progress sync framework. Lets Claude Code, Codex, OpenCode, Kimi Code, OpenClaw, Grok Build, Antigravity, and Cursor coordinate on the same project by reading each other's progress logs.

## Install

One command installs to every detected agent host (Claude Code, Grok Build, Cursor, etc.):

**macOS / Linux / WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/Fei2411/AgentSync/main/agentsync/install.sh | bash
```

**Windows PowerShell:**
```powershell
irm https://raw.githubusercontent.com/Fei2411/AgentSync/main/agentsync/install.ps1 | iex
```

Install to specific agents only:
```bash
curl -fsSL https://raw.githubusercontent.com/Fei2411/AgentSync/main/agentsync/install.sh | bash -s -- --agents grok,claude
```

Then invoke `/agentsync` in any project.

## Update

The update command is the same as install — it overwrites the local `SKILL.md` with the latest release:

```bash
curl -fsSL https://raw.githubusercontent.com/Fei2411/AgentSync/main/agentsync/install.sh | bash
```

Or inside your agent:
```
/agentsync update
```

Check installed vs latest version:
```bash
curl -fsSL https://raw.githubusercontent.com/Fei2411/AgentSync/main/agentsync/install.sh | bash -s -- --check
```

## Features

Invoke `/agentsync` to get three choice boxes:

1. **Init** — First-time setup. Select agents and runtime environment; generates rule files and directory structure.
2. **Handoff** — Session handoff. Reviews the current session, runs `git diff`, and saves a complete handoff report.
3. **Sync** — Full handover sync. Reads handoff reports and progress logs using a tiered strategy (large projects do not load every progress file).

Typical flow: first run → **Init** → long session needs migration → **Handoff** → new agent or return after a break → **Sync**.

## How It Works

Two types of data:

- **Progress** (automatic) — 5-line micro-logs written when a phase completes. For daily sync. Not user-triggered.
- **Handoff** (manual) — Complete session reports for urgent migration when the project is large or the conversation is long. Not auto-loaded, to keep context cost low.

**How Sync reads progress at scale**: latest 2 entries per agent in full, up to 20 older entries as a compact table, everything beyond that as counts only. Also reads the latest handoff per agent in full. Rule files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) still handle daily auto-read (latest 2 only).

## Supported Agents

| Agent | Auto-reads rules | Status |
|-------|-----------------|--------|
| Claude Code | `CLAUDE.md` | ✅ Verified |
| Codex | `AGENTS.md` | ✅ Verified |
| OpenCode | `AGENTS.md` | ✅ Mostly works |
| Kimi Code | `AGENTS.md` | ✅ Verified |
| OpenClaw | `AGENTS.md` | 🔧 Untested |
| Grok Build | `AGENTS.md`, `.grok/rules/*.md` | ✅ Verified |
| Antigravity | `GEMINI.md` | 🔧 Untested |
| Cursor | `AGENTS.md` (also `.cursor/rules/*.mdc`) | ✅ Verified |

## License

MIT