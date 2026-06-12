# codex-continuity-kit

English | [中文](#中文)

A small, local-first continuity kit for long Codex sessions.

It keeps task state outside the chat window, helps recover from broken or
compacted threads, and gives a fresh Codex conversation enough evidence to
continue without guessing.

## Platform Support

The export script is designed for PowerShell on Windows, macOS, and Linux.

Default session root:

```text
<home>/.codex/sessions
```

Use `-SessionsRoot` when your Codex session files live somewhere else.

## Why

Long AI coding sessions can fail in practical ways:

- the thread becomes too long;
- automatic compaction fails;
- a new conversation loses current file paths, blockers, and next steps;
- the assistant repeats old discovery work;
- the user has to reconstruct context manually.

This kit keeps a small local continuity layer next to your workspace.

## What's Included

- `scripts/Export-CodexSessionIndex.ps1`
  - Scans local Codex session JSONL files.
  - Builds a Markdown `session-index.md`.
  - Optionally extracts recent turns into rescue files.
  - Uses `FileShare.ReadWrite`, so active JSONL files can still be read.
  - Supports `-RedactPaths` and `-Shareable` for safer public examples.
- `templates/GLOBAL_STATE_TEMPLATE.md`
  - A lightweight active-task registry.
- `templates/TASK_JOURNAL_TEMPLATE.md`
  - A durable per-task handoff journal.
- `templates/AGENTS_CONTINUITY_SNIPPET.md`
  - A snippet you can add to a workspace `AGENTS.md`.
- `examples/session-index.example.md`
  - Sanitized example output.
- `examples/shareable-output.example.md`
  - Safe rescue and `-Shareable` before/after examples for public issues.

## Quick Start

Requirements:

- PowerShell 5.1+ on Windows, or PowerShell 7+ (`pwsh`) on macOS/Linux.

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

Generate output intended for public issue examples:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Export-CodexSessionIndex.ps1 -OutputRoot .\codex-continuity-public -Keyword "deployment" -CreateRescue -Shareable
```

`-Shareable` redacts common local user-profile path roots and excludes developer
messages even if `-IncludeDeveloperMessages` is passed. It is still your
responsibility to review generated files before publishing them.

## Privacy Warning

The kit itself is safe to publish, but generated outputs are usually not.

Do not publish generated files such as:

- `session-index.md`;
- `rescues/*.md`;
- journals containing real paths, commands, hosts, tickets, or credentials;
- `GLOBAL_STATE.md` after you have filled it with private project state.

Generated rescue files can contain user messages, assistant messages, shell
commands, error output, file paths, hostnames, or secrets that appeared in the
chat. Review and redact before sharing.

For public bug reports, prefer `-Shareable`, then manually inspect the output.

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

## Contributing

Issues and pull requests are welcome. Use the issue templates and do not paste
real session content, tokens, customer data, private hostnames, or private
workspace paths into public issues.

## License

MIT

---

## 中文

[English](#codex-continuity-kit) | 中文

一个本地优先的 Codex 长任务连续性工具包。

它把任务状态保存到聊天窗口之外，帮助你从长线程、压缩失败或上下文丢失中恢复，让新的
Codex 对话可以基于证据继续，而不是重新猜现场。

## 平台支持

导出脚本面向 Windows、macOS 和 Linux 上的 PowerShell。

默认 session 根目录：

```text
<home>/.codex/sessions
```

如果你的 Codex session 文件在其他位置，请显式传入 `-SessionsRoot`。

## 为什么需要

长时间 AI 编程会遇到一些实际问题：

- 对话太长；
- 自动压缩失败；
- 新对话丢失当前路径、阻塞点和下一步；
- 助手重复之前的探索；
- 用户被迫手动重建上下文。

这个工具包提供一个放在工作区旁边的本地连续性层。

## 包含内容

- `scripts/Export-CodexSessionIndex.ps1`
  - 扫描本地 Codex session JSONL 文件。
  - 生成 Markdown 格式的 `session-index.md`。
  - 可选生成 rescue 摘录文件，提取最近若干轮对话。
  - 使用 `FileShare.ReadWrite`，可以读取仍在写入中的 JSONL。
  - 支持 `-RedactPaths` 和 `-Shareable`，用于生成更适合公开 issue 的脱敏输出。
- `templates/GLOBAL_STATE_TEMPLATE.md`
  - 轻量级活跃任务登记表。
- `templates/TASK_JOURNAL_TEMPLATE.md`
  - 每个任务的持久交接日志模板。
- `templates/AGENTS_CONTINUITY_SNIPPET.md`
  - 可加入工作区 `AGENTS.md` 的连续性规则片段。
- `examples/session-index.example.md`
  - 已脱敏的示例输出。
- `examples/shareable-output.example.md`
  - 用于公开 issue 的安全 rescue 和 `-Shareable` 前后对照示例。

## 快速开始

依赖：

- Windows 上的 PowerShell 5.1+，或 macOS/Linux 上的 PowerShell 7+ (`pwsh`)。

把本工具包复制到工作区，然后创建本地连续性目录：

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

生成适合公开 issue 示例的输出：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Export-CodexSessionIndex.ps1 -OutputRoot .\codex-continuity-public -Keyword "deployment" -CreateRescue -Shareable
```

`-Shareable` 会脱敏常见本地用户目录路径，并且即使传入
`-IncludeDeveloperMessages` 也不会导出 developer messages。公开前仍然必须人工检查。

## 隐私提醒

工具包本身可以公开，但它生成的内容通常不能直接公开。

不要直接发布这些生成文件：

- `session-index.md`；
- `rescues/*.md`；
- 包含真实路径、命令、主机、工单或凭据的 journals；
- 已经填入真实项目状态后的 `GLOBAL_STATE.md`。

rescue 文件可能包含用户消息、助手消息、命令、错误输出、文件路径、主机名，甚至对话中
出现过的密钥。分享前必须审查和脱敏。

公开 bug report 时，优先使用 `-Shareable`，然后再人工检查输出。

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

## 参与贡献

欢迎提交 issue 和 pull request。公开 issue 中不要粘贴真实 session 内容、token、客户
数据、私有主机名或私有工作区路径。

## 许可证

MIT
