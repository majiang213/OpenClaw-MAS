---
name: cmd_go_review
description: "Review Go code for idiomatic patterns, concurrency safety, error handling, and security vulnerabilities."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `go-reviewer` agent for a comprehensive Go code review.

Include in the task payload:
- Files or packages to review (or "all changed files" for a pre-commit review)
- Go version and any relevant module dependencies
- Whether this is a pre-commit review or a PR review
- Any specific concerns (goroutine leaks, race conditions, error handling)

The agent checks for race conditions, goroutine leaks, missing error context, non-idiomatic patterns, and security issues. It runs `go vet`, `staticcheck`, and `golangci-lint`.

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
