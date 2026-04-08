---
name: cmd_docs
description: "Legacy slash-entry shim for the documentation-lookup skill. Prefer the skill directly."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [topic]"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Docs Command (Legacy Shim)

Use this only if you still reach for `/docs`. The maintained workflow lives in `skills/documentation-lookup/SKILL.md`.

## Canonical Surface

- Prefer the `documentation-lookup` skill directly.
- Keep this file only as a compatibility entry point.

## Arguments

`$ARGUMENTS`

## Delegation

Apply the `documentation-lookup` skill.
- If the library or the question is missing, ask for the missing part.
- Use live documentation through Context7 instead of training data.
- Return only the current answer and the minimum code/example surface needed.
