---
name: cmd_instinct_status
description: "Show current workspace memory: MEMORY.md contents, pending recalls, and index status."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path>"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Memory Status

Shows the current state of long-term memory (MEMORY.md) and short-term recalls
pending promotion for the active OpenClaw workspace.

## Usage

```
/skill cmd_instinct_status <project-path>
```

## What to Do

1. Read MEMORY.md from the main workspace:
   ```bash
   cat ~/.openclaw/workspace-main/MEMORY.md
   ```
   If the file does not exist or is empty, note: "No MEMORY.md found — workspace has no long-term memory yet."

2. Count the `##`-level headings in MEMORY.md to get the total number of memory sections.

3. Run memory status to show the index:
   ```bash
   openclaw memory status
   ```

4. Run promotion preview to show what is pending:
   ```bash
   openclaw memory promote
   ```
   (without `--apply` — preview only)

5. Display the output:

```
============================================================
  MEMORY STATUS
============================================================

  Workspace: ~/.openclaw/workspace-main/
  MEMORY.md sections: <count>

## LONG-TERM MEMORY (MEMORY.md)

<full MEMORY.md content>

## SHORT-TERM RECALLS (pending promotion)

<output from openclaw memory promote>

## MEMORY INDEX

<output from openclaw memory status>
```

## Notes

- MEMORY.md is injected at every agent bootstrap via the session-bootstrap hook
- Short-term recalls are stored in ~/.openclaw/memory/main.sqlite
- Run /skill cmd_promote to apply pending promotions to MEMORY.md
