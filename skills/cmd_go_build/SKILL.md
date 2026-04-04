---
name: cmd_go_build
description: "Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `go-build-resolver` agent to fix Go build failures.

Include in the task payload:
- The full build error output (`go build ./...` or `go vet ./...`)
- Go version and module path
- Any recent changes that may have caused the breakage
- Whether linter (`golangci-lint`, `staticcheck`) output is also available

The agent runs `go build`, `go vet`, and `staticcheck`, then fixes errors one at a time — verifying after each change.

---

First, reply to the user briefly to confirm you are delegating to `go-build-resolver`.

Then call sessions_spawn:
```json
{
  "agentId": "go-build-resolver",
  "sessionKey": "go-build-resolver",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
