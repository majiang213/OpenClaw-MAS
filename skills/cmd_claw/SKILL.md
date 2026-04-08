---
name: cmd_claw
description: "Legacy slash-entry shim for the nanoclaw-repl skill. Prefer the skill directly."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path>"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Claw Command (Legacy Shim)

Use this only if you still reach for `/claw` from muscle memory. The maintained implementation lives in `skills/nanoclaw-repl/SKILL.md`.

## Canonical Surface

- Prefer the `nanoclaw-repl` skill directly.
- Keep this file only as a compatibility entry point while command-first usage is retired.

## Arguments

`$ARGUMENTS`

## Delegation

Apply the `nanoclaw-repl` skill and keep the response focused on operating or extending `scripts/claw.js`.
- If the user wants to run it, use `node scripts/claw.js` or `npm run claw`.
- If the user wants to extend it, preserve the zero-dependency and markdown-backed session model.
- If the request is really about long-running orchestration rather than NanoClaw itself, redirect to `dmux-workflows` or `autonomous-agent-harness`.
