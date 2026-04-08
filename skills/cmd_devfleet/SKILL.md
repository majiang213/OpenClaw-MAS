---
name: cmd_devfleet
description: "Legacy slash-entry shim for the claude-devfleet skill. Prefer the skill directly."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path>"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# DevFleet (Legacy Shim)

Use this only if you still call `/devfleet`. The maintained workflow lives in `skills/claude-devfleet/SKILL.md`.

## Canonical Surface

- Prefer the `claude-devfleet` skill directly.
- Keep this file only as a compatibility entry point while command-first usage is retired.

## Arguments

`$ARGUMENTS`

## Delegation

Apply the `claude-devfleet` skill.
- Plan from the user's description, show the DAG, and get approval before dispatch unless the user already said to proceed.
- Prefer polling status over blocking waits for long missions.
- Report mission IDs, files changed, failures, and next steps from structured mission reports.
