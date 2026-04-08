---
name: cmd_hookify_configure
description: "Enable or disable OpenClaw hooks interactively"
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Hookify Configure

Interactively enable or disable OpenClaw hooks.

## Steps

1. Run `openclaw hooks list` to get all hooks and their current state
2. Also scan `<project-path>/.openclaw/hooks/` for local hooks
3. Present the list with current enabled / disabled status
4. Ask the user which hooks to toggle
5. For each selected hook, run:
   - `openclaw hooks enable <name>` to enable
   - `openclaw hooks disable <name>` to disable
6. Confirm the updated state by running `openclaw hooks list` again
