# AgentSync

**中文** | [English](./README.en.md)

轻量级多 Agent 进度同步框架，让 Claude Code、Codex、OpenCode、Kimi Code、OpenClaw、Grok Build、Antigravity、Cursor 等 AI 编码 Agent 在同一项目上协作时，能互相读到彼此的进度。

## 安装

```bash
mkdir -p ~/.claude/skills/agentsync
curl -fsSL https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/SKILL.md -o ~/.claude/skills/agentsync/SKILL.md
```

安装后在任意项目中输入 `/agentsync` 即可使用。

## 功能

提供三个命令：

1. **Init** — 引导式安装。选择你使用的 Agent、运行环境，自动生成规则文件和目录结构。
2. **Handoff** — 会话交接。回顾当前会话，执行 `git diff`，生成详细的交接报告（上下文、决策、变更、下一步）。
3. **Sync** — 进度同步。扫描所有 Agent 的最新进度日志，输出汇总表，自动检测文件冲突。

## 工作原理

两种数据类型：

- **Progress**（自动）— 5 行微日志，Agent 在阶段完成时自动写入，用于日常同步。
- **Handoff**（手动）— 详细会话报告，切换 Agent 时手动生成，包含完整上下文和决策链。

通过共享的 `.progress/` 目录和项目规则文件（`CLAUDE.md`、`AGENTS.md`、`GEMINI.md`），让每个 Agent 知道去哪读其他人的进度、往哪写自己的进度。

## 支持的 Agent

| Agent | 读取规则文件 | 状态 |
|-------|------------|------|
| Claude Code | `CLAUDE.md` | ✅ 已验证 |
| Codex | `AGENTS.md` | ✅ 已验证 |
| OpenCode | `AGENTS.md` | ✅ 基本可用 |
| Kimi Code | `AGENTS.md` | ✅ 已验证 |
| OpenClaw | `AGENTS.md` | 🔧 未测试 |
| Grok Build | `AGENTS.md`、`.grok/rules/*.md` | ✅ 已验证 |
| Antigravity | `GEMINI.md` | 🔧 未测试 |
| Cursor | `AGENTS.md`（也可用 `.cursor/rules/*.mdc`） | ✅ 已验证 |

## License

MIT