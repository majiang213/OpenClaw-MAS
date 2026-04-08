---
name: cmd_agent_sort
description: "Classify ECC surfaces as DAILY vs LIBRARY to guide selective agent installation"
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Agent Sort

Classify ECC surfaces with concrete repo evidence to determine which agents are needed daily vs. occasionally.

## Steps

1. Analyze the project at the given path
2. Classify ECC surfaces as DAILY or LIBRARY based on actual usage patterns
3. Recommend which agents to install for this project
4. If an install change is needed, hand off to `configure-ecc` instead of re-implementing install logic

## Arguments

`$ARGUMENTS` (after the project path)
