# AgentSync

[中文](./README.md) | **English**

Lightweight multi-agent progress sync framework. Lets Claude Code, Codex, OpenCode, Kimi Code, OpenClaw, Grok Build, Antigravity, and Cursor coordinate on the same project by reading each other's progress logs.

## Install

```bash
mkdir -p ~/.claude/skills/agentsync
curl -fsSL https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/SKILL.md -o ~/.claude/skills/agentsync/SKILL.md
```

Then invoke `/agentsync` in any project.

## Features

Three commands:

1. **Init** — Guided setup. Select your agents and runtime environment; AgentSync generates the right rule files and directory structure.
2. **Handoff** — Session handoff. Reviews the current session, runs `git diff`, and writes a detailed report (context, decisions, changes, next steps).
3. **Sync** — Progress sync. Scans every agent's latest progress log, prints a summary table, and flags potential file conflicts.

## How It Works

Two types of data:

- **Progress** (automatic) — 5-line micro-logs written when a phase completes. For daily sync.
- **Handoff** (manual) — Detailed session reports triggered before switching agents. For deep transitions.

A shared `.progress/` directory plus project rule files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) tell each agent where to read others' progress and where to write its own.

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