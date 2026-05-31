# Contributing

Thanks for helping improve codex-continuity-kit.

## Good First Issues

Good starting points are:

- clearer recovery examples;
- safer redaction behavior;
- compatibility notes for different Codex session formats;
- tests for session parsing edge cases.

## Before Opening an Issue

Please include:

- Codex client type and version if known;
- operating system;
- whether the session file was active while scanned;
- the command you ran;
- sanitized sample input or output.

Do not paste real session messages, customer data, tokens, hostnames, or private
workspace paths into public issues.

## Pull Requests

Keep parser changes small and include a sanitized sample or test case when the
behavior depends on a specific session JSONL shape.
