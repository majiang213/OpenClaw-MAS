---
name: cmd_sessions
description: "List and inspect OpenClaw session files from the workspace sessions/ directory."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [list|load|info] [session-file]"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Sessions

Lists and inspects OpenClaw session files stored in
`~/.openclaw/workspace-main/sessions/`.

## Usage

```
/skill cmd_sessions <project-path>                   # List all sessions
/skill cmd_sessions <project-path> list              # Same as above
/skill cmd_sessions <project-path> load <file>       # Show a session's content
/skill cmd_sessions <project-path> info <file>       # Show session metadata
```

## Actions

### List Sessions

Show all session files with their date and size, newest first.

```bash
ls -lt ~/.openclaw/workspace-main/sessions/*.md 2>/dev/null
```

Display as a table:

```
Sessions in ~/.openclaw/workspace-main/sessions/
════════════════════════════════════════════════

  #   Filename                        Modified        Size
  ─────────────────────────────────────────────────────────
  1   session-2026-04-08.md           2026-04-08      12 KB   ← latest
  2   session-2026-04-07.md           2026-04-07       8 KB
  3   session-2026-04-06.md           2026-04-06       5 KB
  ...

Total: <N> sessions
```

If no sessions exist, report: "No session files found in workspace-main/sessions/"

### Load Session

Display the full content of a session file.

```bash
cat ~/.openclaw/workspace-main/sessions/<file>
```

If the file is not found, list available sessions and stop.

### Info

Show the first 30 lines of a session file (typically contains the session header
with date, project, branch, and summary).

```bash
head -30 ~/.openclaw/workspace-main/sessions/<file>
```

## Notes

- Session files are written by the session-bootstrap hook at the end of each session
- The latest session file is injected into the agent context at bootstrap
- Use /skill cmd_prune to remove old session files
- Use /skill cmd_save_session to create a new session checkpoint
