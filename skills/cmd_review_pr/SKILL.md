---
name: cmd_review_pr
description: "Comprehensive PR review using multiple specialized agents: code-reviewer, comment-analyzer, pr-test-analyzer, silent-failure-hunter, type-design-analyzer, code-simplifier"
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Review PR

Run a comprehensive multi-perspective review of a pull request.

## Usage

`/skill cmd_review_pr <project-path> multi-agent PR review #<PR-number>`

If no PR is specified, review the current branch's PR. If no focus is specified, run the full review stack.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- PR number or URL (if provided)
- Focus area (if provided)
- Tech stack and any project-specific conventions

## Steps

1. Identify the PR — use `gh pr view` to get PR details, changed files, and diff
2. Find project guidance — look for `CLAUDE.md`, lint config, TypeScript config, repo conventions
3. Run specialized review agents in parallel:

```json
{ "agentId": "code-reviewer", "sessionKey": "code-reviewer", "task": "<project path, PR details and diff>", "runTimeoutSeconds": 0 }
```
```json
{ "agentId": "comment-analyzer", "sessionKey": "comment-analyzer", "task": "<project path, changed files>", "runTimeoutSeconds": 0 }
```
```json
{ "agentId": "pr-test-analyzer", "sessionKey": "pr-test-analyzer", "task": "<project path, PR details and changed files>", "runTimeoutSeconds": 0 }
```
```json
{ "agentId": "silent-failure-hunter", "sessionKey": "silent-failure-hunter", "task": "<project path, changed files>", "runTimeoutSeconds": 0 }
```
```json
{ "agentId": "type-design-analyzer", "sessionKey": "type-design-analyzer", "task": "<project path, changed files>", "runTimeoutSeconds": 0 }
```
```json
{ "agentId": "code-simplifier", "sessionKey": "code-simplifier", "task": "<project path, changed files>", "runTimeoutSeconds": 0 }
```

4. Aggregate results — dedupe overlapping findings, rank by severity
5. Report findings grouped by severity

## Confidence Rule

Only report issues with confidence >= 80:
- **Critical**: bugs, security, data loss
- **Important**: missing tests, quality problems, style violations
- **Advisory**: suggestions only when explicitly requested
