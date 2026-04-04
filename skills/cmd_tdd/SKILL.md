---
name: cmd_tdd
description: "Implement a feature or fix using test-driven development — write failing tests first, then implement to pass, then refactor. Enforces RED → GREEN → REFACTOR cycle with 80%+ coverage."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `tdd-guide` agent to implement using strict TDD.

Include in the task payload:
- What to build (feature, fix, or refactor)
- Relevant files, modules, or components involved
- Tech stack and test framework in use
- Any existing tests or coverage requirements to meet
- Whether a plan already exists (pass it along if so)

The agent will write tests first (RED), implement minimally to pass (GREEN), then refactor (IMPROVE). It enforces 80%+ coverage and will not skip the RED phase.

---

First, reply to the user briefly to confirm you are delegating to `tdd-guide`.

Then call sessions_spawn:
```json
{
  "agentId": "tdd-guide",
  "sessionKey": "tdd-guide",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
