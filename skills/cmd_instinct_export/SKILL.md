---
name: cmd_instinct_export
description: "Export MEMORY.md to a timestamped markdown file for sharing or backup."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [output-file]"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Memory Export

Exports the workspace MEMORY.md to a shareable file. Use this to:
- Share curated knowledge with teammates
- Back up memory before a reinstall
- Transfer knowledge to another workspace

## Usage

```
/skill cmd_instinct_export <project-path>
/skill cmd_instinct_export <project-path> my-team-memory.md
```

The optional second argument is the output file path. If omitted, the file is
written to the project directory as `memory-export-YYYY-MM-DD.md`.

## What to Do

1. Read MEMORY.md from the main workspace:
   ```bash
   cat ~/.openclaw/workspace-main/MEMORY.md
   ```
   If the file does not exist or is empty, report: "Nothing to export — MEMORY.md is empty." Stop.

2. Count the `##`-level headings to get the section count.

3. Determine the output path:
   - If a second argument was provided, use it as-is
   - Otherwise: `<project-path>/memory-export-<today-YYYY-MM-DD>.md`

4. Write the export file:
   ```markdown
   # Memory Export
   # Exported: <YYYY-MM-DD HH:MM>
   # Source: ~/.openclaw/workspace-main/MEMORY.md
   # Sections: <count>

   ---

   <full MEMORY.md content verbatim>
   ```

5. Report:
   ```
   Memory exported: <output-path>
   Sections exported: <count>

   To import into another workspace:
     /skill cmd_instinct_import <project-path> <output-path>
   ```

## Notes

- The export format is plain markdown — no YAML instinct schema
- Import using /skill cmd_instinct_import
