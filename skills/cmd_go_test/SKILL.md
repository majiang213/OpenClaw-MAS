---
name: cmd_go_test
description: "Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `go-build-resolver` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- What to implement (function, class, module)
- Language version and test framework in use
- Any existing test fixtures or helpers to reuse
- Coverage target (default: 80%)

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
