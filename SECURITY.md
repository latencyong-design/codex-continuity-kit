# Security Policy

## Reporting Security Issues

Do not publish real Codex session content, generated rescue files, API keys,
customer data, hostnames, or private workspace paths in public issues.

Open a public issue for general hardening requests. If a report requires
sensitive examples, describe the shape of the issue without including the
sensitive data.

## Data Handling Model

codex-continuity-kit reads local Codex JSONL session files and can generate
indexes or rescue extracts. Those generated files can contain private user
messages, commands, paths, hosts, errors, and credentials that appeared in a
chat.

Generated outputs should be treated as private by default. Use shareable or
redacted output modes before attaching examples to public issues.
