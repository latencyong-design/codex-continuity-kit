# Shareable Output Examples

These examples show the shape of safe issue attachments without using real
session content. Treat generated continuity files as private until you review
them manually.

## Minimal Sanitized Rescue Example

````markdown
# Codex Rescue Extract

> Review and redact before sharing. This file may contain private conversation content.

- Thread id: `example-thread`
- Timestamp: `2026-05-31T12:00:00Z`
- Last write: `2026-05-31 12:34:56`
- CWD: `<home>/workspace/example-repo`
- Model: `gpt-example`
- Source JSONL: `<home>/.codex/sessions/2026/05/31/rollout-example.jsonl`

## Recent Turns

### User
The build fails after the config change. Please inspect the error.

### Assistant
I found the failing command and narrowed it to `src/config.example.ts`.

## Recent Commands

```text
npm run build
```

## Recent Error-Like Output

```text
Error: expected EXAMPLE_API_URL to be set
```
````

This example keeps the useful debugging shape while replacing local paths,
project-specific names, and any real hostnames or credentials.

## `-Shareable` Before and After

Before review, a rescue extract can contain local details:

```text
- CWD: `C:\Users\alice\Desktop\client-repo`
- Source JSONL: `/Users/alice/.codex/sessions/2026/05/31/rollout.jsonl`
- Recent command: `curl https://internal.example.invalid/api -H "Authorization: Bearer sk-live-secret"`
- Recent error-like output: `Failed reading /home/bob/customer-data/export.csv`
```

After generating with `-Shareable` and manually reviewing:

```text
- CWD: `<home>/Desktop/client-repo`
- Source JSONL: `<home>/.codex/sessions/2026/05/31/rollout.jsonl`
- Recent command: `curl https://<redacted-host>/api -H "Authorization: Bearer <redacted-token>"`
- Recent error-like output: `Failed reading <home>/customer-data/export.csv`
```

`-Shareable` handles common local user-profile path roots and excludes developer
messages. It does not know every private hostname, token format, ticket number,
customer name, or project-specific secret.

## Manual Review Checklist

Before attaching generated output to a public issue, check for:

- usernames in paths, prompts, command output, or file names
- API keys, bearer tokens, cookies, SSH hosts, or private URLs
- customer names, ticket IDs, repository names, branch names, or internal hosts
- absolute paths outside the redacted home directory pattern
- commands that reveal deployment targets, credentials, or private data files
- generated journals or state files that describe unreleased product strategy

If any item is present, replace it with a placeholder such as `<home>`,
`<redacted-host>`, `<redacted-token>`, `<private-repo>`, or
`<customer-file.csv>` before sharing.
