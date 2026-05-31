# Global State

This file is the workspace-local continuity registry. Keep it short, current,
and safe to read at the start of a new Codex thread.

## Active Tasks

### <task name>

- Status: `<active | blocked | done>`
- Journal: `codex-continuity/journals/<task>.md`
- Last verified: `<YYYY-MM-DD HH:mm>`
- Next safe step: `<one concrete action>`
- Boundaries: `<what not to touch>`

## Stable Workspace Facts

- Root: `<workspace path or repo-relative path>`
- Primary commands: `<test/build/run commands>`
- Important services: `<local or remote services>`

## Recovery Entrypoints

- Session index: `codex-continuity/session-index.md`
- Rescue extracts: `codex-continuity/rescues/`
- Task journals: `codex-continuity/journals/`

## Rules

- Prefer verified local state over memory.
- Update the relevant journal before risky operations and final response.
- Never publish filled continuity files without redaction.
