---
name: cmd_rules_distill
description: "Legacy slash-entry shim for the rules-distill skill. Prefer the skill directly."
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Rules Distill (Legacy Shim)

Use this only if you still invoke `/rules-distill`. The maintained workflow lives in `skills/rules-distill/SKILL.md`.

## Canonical Surface

- Prefer the `rules-distill` skill directly.
- Keep this file only as a compatibility entry point.

## Arguments

`$ARGUMENTS`

## Delegation

Apply the `rules-distill` skill and follow its inventory, cross-read, and verdict workflow instead of duplicating that logic here.
