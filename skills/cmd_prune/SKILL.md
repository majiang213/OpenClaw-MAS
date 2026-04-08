---
name: cmd_prune
description: "Remove stale session files from the workspace sessions/ directory older than a given age."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [--max-age N] [--dry-run]"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Prune Sessions

Removes old session files from `~/.openclaw/workspace-main/sessions/` that are
older than the specified age threshold. Helps keep the workspace tidy.

## Usage

```
/skill cmd_prune <project-path>               # Delete sessions older than 30 days
/skill cmd_prune <project-path> --max-age 60  # Custom age threshold (days)
/skill cmd_prune <project-path> --dry-run     # Preview without deleting
```

## Flags

- `--max-age <N>` — age threshold in days (default: 30)
- `--dry-run` — show what would be deleted without deleting

## What to Do

1. Determine the sessions directory: `~/.openclaw/workspace-main/sessions/`
   If it does not exist or is empty, report: "No sessions found." Stop.

2. Parse `--max-age` from arguments (default: 30 days).

3. List all `*.md` files in the sessions directory and check their modification time:
   ```bash
   find ~/.openclaw/workspace-main/sessions/ -name "*.md" -mtime +<max-age>
   ```

4. If no files match, report: "No sessions older than <max-age> days found." Stop.

5. Show the files that would be deleted:
   ```
   Sessions to delete (<count>, older than <max-age> days):
     - session-2026-01-01.md  (modified: 2026-01-01)
     - session-2026-01-15.md  (modified: 2026-01-15)
   ```

6. If `--dry-run` is set, stop here.

7. Ask: "Delete <count> session files? (yes/no)"
   If the user declines, stop.

8. Delete the files:
   ```bash
   find ~/.openclaw/workspace-main/sessions/ -name "*.md" -mtime +<max-age> -delete
   ```

9. Report:
   ```
   Pruned <count> session files older than <max-age> days.
   Sessions directory: ~/.openclaw/workspace-main/sessions/
   ```

## Notes

- Only session files in workspace-main/sessions/ are pruned
- The latest session file is always safe — the find command uses mtime, not the filename
- MEMORY.md is never touched by this command
