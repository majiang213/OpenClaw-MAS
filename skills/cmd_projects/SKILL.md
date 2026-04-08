---
name: cmd_projects
description: "List known projects and their instinct statistics"
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path>"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Projects Command

List project registry entries and per-project instinct/observation counts for continuous-learning-v2.

## Implementation

Run the instinct CLI using the plugin root path:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" projects
```

Or if `CLAUDE_PLUGIN_ROOT` is not set (manual installation):

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py projects
```

## Usage

```bash
/projects
```

## What to Do

1. Read `~/.claude/homunculus/projects.json`
2. For each project, display:
   - Project name, id, root, remote
   - Personal and inherited instinct counts
   - Observation event count
   - Last seen timestamp
3. Also display global instinct totals
