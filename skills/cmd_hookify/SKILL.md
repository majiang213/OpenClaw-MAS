---
name: cmd_hookify
description: "Create hook rules to prevent unwanted Claude Code behaviors"
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Hookify

Create hook rules to prevent unwanted Claude Code behaviors by analyzing conversation patterns or explicit user instructions.

## Usage

`/skill cmd_hookify <project-path> [description of behavior to prevent]`

If no description is provided after the project path, use the `conversation-analyzer` agent to find behaviors worth preventing.

## Workflow

### Step 1: Gather Behavior Info

- With description: parse the user's description of the unwanted behavior
- Without description: delegate to `conversation-analyzer` agent to find:
  - Explicit corrections
  - Frustrated reactions to repeated mistakes
  - Reverted changes
  - Repeated similar issues

### Step 2: Present Findings

Show the user:
- Behavior description
- Proposed event type
- Proposed pattern or matcher
- Proposed action

### Step 3: Generate Rule Files

For each approved rule, create a file at `<project-path>/.claude/hookify.{name}.local.md`:

```yaml
---
name: rule-name
enabled: true
event: bash|file|stop|prompt|all
action: block|warn
pattern: "regex pattern"
---
Message shown when rule triggers.
```

### Step 4: Confirm

Report created rules and how to manage them with `/skill cmd_hookify_list` and `/skill cmd_hookify_configure`.
