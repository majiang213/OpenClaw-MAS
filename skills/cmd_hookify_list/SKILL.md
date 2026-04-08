---
name: cmd_hookify_list
description: "List all configured OpenClaw hooks for the project"
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path>"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Hookify List

Display all OpenClaw hooks configured for this project.

## Steps

1. Run `openclaw hooks list` to get all registered hooks
2. Also scan `<project-path>/.openclaw/hooks/` for local hook directories
3. For each hook, read its `HOOK.md` to extract: name, description, events, enabled status
4. Display as a table:

| Hook | Enabled | Events | Description |
|------|---------|--------|-------------|

5. Show total count and remind the user:
   - `openclaw hooks enable <name>` — enable a hook
   - `openclaw hooks disable <name>` — disable a hook
   - `/skill cmd_hookify_configure <path>` — toggle hooks interactively
