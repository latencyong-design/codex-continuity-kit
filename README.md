# codex-continuity-kit

English | [中文](#中文)

A small, local-first continuity kit for long Codex sessions.

It helps you keep task state outside the chat window, recover from broken or
compacted threads, and hand work to a fresh Codex conversation with evidence
instead of memory guesses.

## Why

Long AI coding sessions can fail in boring ways:

- the thread becomes too long;
- automatic compaction fails;
- the assistant forgets earlier boundaries;
- a new conversation loses the current file paths, blockers, and next step;
- the user has to reconstruct context by hand.

This kit keeps a small local continuity layer next to your workspace.

## What's Included

- `scripts/Export-CodexSessionIndex.ps1`
  - Scans local Codex session JSONL files.
  - Builds a Markdown `session-index.md`.
  - Optionally extracts recent turns into deterministic rescue files.
  - Uses `FileShare.ReadWrite`, so active JSONL files can still be read.
- `templates/GLOBAL_STATE_TEMPLATE.md`
  - A lightweight active-task registry.
- `templates/TASK_JOURNAL_TEMPLATE.md`
  - A durable per-task handoff journal.
- `templates/AGENTS_CONTINUITY_SNIPPET.md`
  - A snippet you can add to a workspace `AGENTS.md`.
- `examples/session-index.example.md`
  - Sanitized example output.

## Quick Start

Copy the kit into a workspace, then create your local continuity folder:

```powershell
mkdir .\codex-continuity
copy .\templates\GLOBAL_STATE_TEMPLATE.md .\codex-continuity\GLOBAL_STATE.md
copy .\templates\TASK_JOURNAL_TEMPLATE.md .\codex-continuity\TASK_JOURNAL_TEMPLATE.md
```

Generate a session index:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Export-CodexSessionIndex.ps1 -OutputRoot .\codex-continuity
```

Search for sessions containing a keyword:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Export-CodexSessionIndex.ps1 -OutputRoot .\codex-continuity -Keyword "deployment"
```

Create rescue extracts:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Export-CodexSessionIndex.ps1 -OutputRoot .\codex-continuity -Keyword "deployment" -CreateRescue -RecentTurns 10
```

## Privacy Warning

The kit itself is safe to publish, but its generated outputs are usually not.

Do not publish generated files such as:

- `session-index.md`;
- `rescues/*.md`;
- journals containing real paths, commands, hosts, tickets, or credentials;
- `GLOBAL_STATE.md` after you have filled it with private project state.

Generated rescue files can contain user messages, assistant messages, shell
commands, error output, file paths, hostnames, or secrets that appeared in the
chat. Review and redact before sharing.

## Suggested Workflow

At the start of a non-trivial task, ask Codex to read:

```text
codex-continuity/GLOBAL_STATE.md
```

Then ask it to create or update a task journal under:

```text
codex-continuity/journals/
```

Before risky operations, long remote work, scope switches, or final response,
ask it to update the journal.

## License

MIT

---

## 中文

[English](#codex-continuity-kit) | 中文

一个本地优先的 Codex 长对话连续性工具包。

它用于把任务状态保存在聊天窗口之外，帮助你从长线程、压缩失败、上下文丢失
或新对话接手中恢复，而不是靠记忆重新猜测现场。

## 为什么需要

长时间 AI 编程会遇到一些很实际的问题：

- 对话太长；
- 自动压缩失败；
- 助手忘记之前的边界；
- 新对话不知道当前路径、阻塞点和下一步；
- 用户被迫手动重建上下文。

这个工具包提供一个放在工作区旁边的本地连续性层。

## 包含内容

- `scripts/Export-CodexSessionIndex.ps1`
  - 扫描本地 Codex session JSONL 文件。
  - 生成 Markdown 格式的 `session-index.md`。
  - 可选生成 deterministic rescue 文件，提取最近若干轮对话。
  - 使用 `FileShare.ReadWrite`，可以读取仍在写入中的 JSONL。
- `templates/GLOBAL_STATE_TEMPLATE.md`
  - 轻量级活跃任务登记表。
- `templates/TASK_JOURNAL_TEMPLATE.md`
  - 每个任务的持久交接日志模板。
- `templates/AGENTS_CONTINUITY_SNIPPET.md`
  - 可加入工作区 `AGENTS.md` 的连续性规则片段。
- `examples/session-index.example.md`
  - 已脱敏的示例输出。

## 快速开始

把本工具包复制到你的工作区，然后创建本地连续性目录：

```powershell
mkdir .\codex-continuity
copy .\templates\GLOBAL_STATE_TEMPLATE.md .\codex-continuity\GLOBAL_STATE.md
copy .\templates\TASK_JOURNAL_TEMPLATE.md .\codex-continuity\TASK_JOURNAL_TEMPLATE.md
```

生成 session 索引：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Export-CodexSessionIndex.ps1 -OutputRoot .\codex-continuity
```

按关键词搜索 session：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Export-CodexSessionIndex.ps1 -OutputRoot .\codex-continuity -Keyword "deployment"
```

生成恢复摘录：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Export-CodexSessionIndex.ps1 -OutputRoot .\codex-continuity -Keyword "deployment" -CreateRescue -RecentTurns 10
```

## 隐私提醒

这个工具包本身可以公开，但它生成出来的内容通常不能直接公开。

不要直接发布这些生成文件：

- `session-index.md`；
- `rescues/*.md`；
- 包含真实路径、命令、主机、工单或凭据的 journals；
- 你已经填入真实项目状态后的 `GLOBAL_STATE.md`。

rescue 文件可能包含用户消息、助手消息、命令、错误输出、文件路径、主机名，
甚至对话中出现过的密钥。分享前必须审查和脱敏。

## 建议工作流

在非平凡任务开始时，让 Codex 先读取：

```text
codex-continuity/GLOBAL_STATE.md
```

然后让它创建或更新任务日志：

```text
codex-continuity/journals/
```

在执行高风险操作、长时间远程工作、切换范围或最终回复前，让它更新日志。

## 许可证

MIT
