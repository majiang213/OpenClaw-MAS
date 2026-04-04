---
name: cmd_loop_start
description: "Start a managed autonomous agent loop — configure pattern (sequential, continuous-pr, rfc-dag, infinite), safety gates, and stop conditions."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `loop-operator` agent to configure and start an autonomous loop.

Include in the task payload:
- Loop pattern: `sequential`, `continuous-pr`, `rfc-dag`, or `infinite`
- Mode: `safe` (default, strict quality gates) or `fast` (reduced gates)
- The task or goal the loop should execute
- Explicit stop condition (required — loops must have a defined end)
- Current repository state (branch, test status)

The agent verifies safety checks, creates a loop plan and runbook under `.claude/plans/`, and returns the commands to start and monitor the loop.

---

First, reply to the user briefly to confirm you are delegating to `loop-operator`.

Then call sessions_spawn:
```json
{
  "agentId": "loop-operator",
  "sessionKey": "loop-operator",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
