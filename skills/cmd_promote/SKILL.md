---
name: cmd_promote
description: "Promote top short-term recalls to MEMORY.md using openclaw memory promote --apply."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [--dry-run] [--all]"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Promote Memories

Promotes short-term recalls from the OpenClaw recall store into the long-term
MEMORY.md. This is the native OpenClaw memory promotion workflow.

## Usage

```
/skill cmd_promote <project-path>              # Preview then confirm
/skill cmd_promote <project-path> --dry-run    # Preview only, no write
/skill cmd_promote <project-path> --all        # Apply all without confirmation
```

## What to Do

1. Run promotion preview to show candidates:
   ```bash
   openclaw memory promote
   ```
   Display the output so the user can see what is pending.

2. If `--dry-run` is set, stop here.

3. If `--all` is set, apply immediately:
   ```bash
   openclaw memory promote --apply
   ```
   Skip to step 6.

4. Ask the user: "Apply these promotions to MEMORY.md? (yes/no)"
   If the user declines, stop.

5. Apply the promotions:
   ```bash
   openclaw memory promote --apply
   ```

6. Re-index so searches reflect the new entries:
   ```bash
   openclaw memory index
   ```

7. Report:
   ```
   Promotions applied.
   MEMORY.md updated: ~/.openclaw/workspace-main/MEMORY.md

   Run /skill cmd_instinct_status <project-path> to see the full memory state.
   ```

## Notes

- openclaw memory promote scores and ranks short-term recalls automatically
- --apply appends the top-ranked recalls as new sections in MEMORY.md
- MEMORY.md is the single source of truth for long-term knowledge in OpenClaw
