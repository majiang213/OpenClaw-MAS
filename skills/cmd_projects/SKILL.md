---
name: cmd_projects
description: "List all OpenClaw agent workspaces with memory and session statistics."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path>"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Workspaces

Lists all OpenClaw agent workspaces and shows memory and session statistics for each.

## Usage

```
/skill cmd_projects <project-path>
```

## What to Do

1. List all workspace directories:
   ```bash
   ls -d ~/.openclaw/workspace-*/
   ```
   If none are found, report: "No OpenClaw workspaces found at ~/.openclaw/workspace-*/" and stop.

2. For each workspace directory, collect:

   a. **Name**: strip the `workspace-` prefix from the directory basename
      (e.g. `workspace-tdd-guide` → `tdd-guide`)

   b. **MEMORY.md stats**: check if `<workspace>/MEMORY.md` exists.
      If yes, count `##`-level headings (memory sections).
      If no, mark as `(no memory)`.

   c. **Sessions stats**: check if `<workspace>/sessions/` exists.
      If yes, count `*.md` files and find the most recently modified:
      ```bash
      ls -t <workspace>/sessions/*.md 2>/dev/null | head -1
      ```
      If no sessions directory, mark as `(no sessions)`.

3. Display as a table:

```
============================================================
  OPENCLAW WORKSPACES
============================================================

Workspace              MEMORY.md      Sessions      Latest Session
──────────────────────────────────────────────────────────────────
main                   12 sections    8 sessions    2026-04-07.md
tdd-guide              3 sections     2 sessions    2026-03-15.md
code-reviewer          (no memory)    5 sessions    2026-04-06.md
rust-reviewer          (no memory)    (no sessions) —
...

Total workspaces: <N>
```

4. Run the memory index status for the main workspace:
   ```bash
   openclaw memory status
   ```

## Notes

- Workspace discovery uses ~/.openclaw/workspace-*/ glob
- The "main" workspace is the primary long-term memory location
- This replaces the old ~/.claude/homunculus/projects.json registry
