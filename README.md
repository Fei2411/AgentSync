# AgentSync

**中文** | [English](./README.en.md)

轻量级多 Agent 进度同步框架，让 Claude Code、Codex、OpenCode、Kimi Code、OpenClaw、Grok Build、Antigravity、Cursor 等 AI 编码 Agent 在同一项目上协作时，能互相读到彼此的进度。

## 安装

一条命令安装到本机所有已检测到的 Agent（Claude Code、Grok Build、Cursor 等）：

**macOS / Linux / WSL：**
```bash
curl -fsSL https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/install.sh | bash
```

**Windows PowerShell：**
```powershell
irm https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/install.ps1 | iex
```

只安装到指定 Agent：
```bash
curl -fsSL https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/install.sh | bash -s -- --agents grok,claude
```

安装后在任意项目中输入 `/agentsync` 即可使用。

## 更新

更新命令与安装相同，会覆盖本地 `SKILL.md` 到最新版：

```bash
curl -fsSL https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/install.sh | bash
```

或在 Agent 里直接说：
```
/agentsync update
更新 agentsync
```

查看本地版本 vs 远程版本：
```bash
curl -fsSL https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/install.sh | bash -s -- --check
```

## 功能

运行 `/agentsync` 后出现三个选择框：

1. **Init** — 首次安装。选择 Agent 和运行环境，自动生成规则文件和目录结构。
2. **Handoff** — 会话交接。回顾当前会话，执行 `git diff`，生成并保存完整交接报告。
3. **Sync** — 完整交接同步。读取 handoff 完整报告 + progress 微日志，按分层策略呈现（大项目不会一次性读完所有 progress）。

典型流程：第一次选 **Init** → 长会话要迁移时选 **Handoff** → 新 Agent 接手或隔几天回来选 **Sync**。

## 工作原理

两种数据类型：

- **Progress**（自动）— 5 行微日志，Agent 在阶段完成时自动写入，用于日常同步。用户无需手动触发。
- **Handoff**（手动）— 完整会话报告，项目大、对话长、急需迁移时手动生成。不自动加载，避免 context 成本过高。

**Sync 怎么读 progress（大项目）**：每个 Agent 最新 2 条全文 + 更早的最多 20 条压成表格 + 其余只报数量。同时读取各 Agent 最新 handoff 全文。规则文件（`CLAUDE.md`、`AGENTS.md`、`GEMINI.md`）仍只负责 Progress 的日常自动读写（最新 2 条）。

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