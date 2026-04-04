---
name: cmd_verify
description: "Run the full verification loop — build, types, lint, tests, security checks, and diff review in the correct order for the current repo."
user-invocable: true
origin: openclaw-mas
---

# Verification Command (Legacy Shim)

Use this only if you still invoke `/verify`. The maintained workflow lives in `skills/verification-loop/SKILL.md`.

## Canonical Surface

- Prefer the `verification-loop` skill directly.
- Keep this file only as a compatibility entry point.

## Arguments

`$ARGUMENTS`

## Delegation

Apply the `verification-loop` skill.
- Choose the right verification depth for the user's requested mode.
- Run build, types, lint, tests, security/log checks, and diff review in the right order for the current repo.
- Report only the verdicts and blockers instead of maintaining a second verification checklist here.
