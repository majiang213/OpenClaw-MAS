---
name: cmd_go_review
description: "Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `go-reviewer` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- Files or modules to review (or 'all changed files' for a pre-commit review)
- Language version and key dependencies
- Whether this is a pre-commit review or a PR review
- Any specific concerns

---

First, reply to the user briefly to confirm you are delegating to `go-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "go-reviewer",
  "sessionKey": "go-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
