---
name: cmd_hookify_list
description: "List all configured hookify rules in the project"
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Hookify List

Find and display all hookify rules in a formatted table.

## Steps

1. Find all `<project-path>/.claude/hookify.*.local.md` files
2. Read each file's frontmatter: `name`, `enabled`, `event`, `action`, `pattern`
3. Display as a table:

| Rule | Enabled | Event | Pattern | File |
|------|---------|-------|---------|------|

4. Show the rule count and remind the user that `/skill cmd_hookify_configure <path>` can change state.
