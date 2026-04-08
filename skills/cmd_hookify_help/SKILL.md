---
name: cmd_hookify_help
description: "Display comprehensive hookify documentation"
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Hookify Help

Display comprehensive hookify documentation.

## Hook System Overview

Hookify creates rule files that integrate with Claude Code's hook system to prevent unwanted behaviors.

### Event Types

- `bash`: triggers on Bash tool use and matches command patterns
- `file`: triggers on Write/Edit tool use and matches file paths
- `stop`: triggers when a session ends
- `prompt`: triggers on user message submission and matches input patterns
- `all`: triggers on all events

### Rule File Format

Files are stored as `<project-path>/.claude/hookify.{name}.local.md`:

```yaml
---
name: descriptive-name
enabled: true
event: bash|file|stop|prompt|all
action: block|warn
pattern: "regex pattern to match"
---
Message to display when rule triggers.
Supports multiple lines.
```

### Commands

- `/skill cmd_hookify <path> [description]` — creates new rules, auto-analyzes conversation when no description given
- `/skill cmd_hookify_list <path>` — lists configured rules
- `/skill cmd_hookify_configure <path>` — toggles rules on or off

### Pattern Tips

- Use regex syntax
- For `bash`, match against the full command string
- For `file`, match against the file path
- Test patterns before deploying
