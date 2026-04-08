---
name: cmd_instinct_import
description: "Import memory entries from a markdown export file, merging with MEMORY.md without duplicating."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> <file-or-url> [--dry-run] [--force]"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Memory Import

Imports memory entries from a markdown file (produced by /skill cmd_instinct_export
or written manually) into the workspace MEMORY.md. Duplicate sections are detected
and skipped. New sections are appended.

## Usage

```
/skill cmd_instinct_import <project-path> <file-path>
/skill cmd_instinct_import <project-path> https://example.com/memory.md
/skill cmd_instinct_import <project-path> team-memory.md --dry-run
/skill cmd_instinct_import <project-path> team-memory.md --force
```

## Flags

- `--dry-run` — show what would be added without writing anything
- `--force` — skip the confirmation prompt

## What to Do

1. Read the import source:
   - If the second argument starts with `http://` or `https://`, fetch it:
     ```bash
     curl -s "<url>"
     ```
   - Otherwise read the file directly.
   If the source cannot be read, report the error and stop.

2. Parse import sections: extract all `##`-level headings and their content blocks.
   Skip export header lines (`# Memory Export`, `# Exported:`, `# Source:`,
   `# Sections:`, and the `---` separator).

3. Read the existing `~/.openclaw/workspace-main/MEMORY.md`.
   Extract all existing `##`-level heading names for deduplication.

4. Classify each imported section:
   - **New**: heading name does not exist in current MEMORY.md (case-insensitive match)
   - **Duplicate**: heading name already exists — will be skipped

5. Report the analysis:
   ```
   Import Analysis: <source>
   ================================

   Found <N> sections in import file.

   New sections (<count>):
     + <heading name>
     + <heading name>

   Duplicate sections (<count>, will be skipped):
     = <heading name>
   ```

6. If `--dry-run` is set, stop here.

7. If there are no new sections, report "Nothing to import — all sections already exist." Stop.

8. If `--force` is not set, ask: "Import <count> new sections? (yes/no)"
   If the user declines, stop.

9. Append the new sections to `~/.openclaw/workspace-main/MEMORY.md`.

10. Re-index memory:
    ```bash
    openclaw memory index
    ```

11. Report:
    ```
    Import complete.
    Added: <count> sections
    Skipped: <count> duplicates
    MEMORY.md now has <total> sections.
    ```

## Notes

- Deduplication is by heading text (case-insensitive) — local version always wins on conflict
- Use --force in scripted/automated contexts to skip the confirmation prompt
