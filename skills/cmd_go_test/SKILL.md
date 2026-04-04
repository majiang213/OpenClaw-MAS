---
name: cmd_go_test
description: "Implement Go code using TDD with table-driven tests — write failing tests first, implement to pass, verify 80%+ coverage with go test -cover."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `go-build-resolver` agent to implement Go code using TDD.

Include in the task payload:
- What to implement (function, method, package)
- Go version and module path
- Any existing test helpers or fixtures to reuse
- Coverage target (default: 80%)
- Whether to use subtests, benchmarks, or fuzz tests

The agent writes table-driven tests first (RED), implements minimal code to pass (GREEN), then refactors — verifying coverage with `go test -cover`.

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
