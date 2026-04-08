---
name: cmd_loop_start
description: "Start an autonomous agent loop (sequential, continuous-pr, rfc-dag, or infinite) via the loop-operator agent."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> <goal> [--mode loop|single] [--stop condition]"
---

Delegate to the `loop-operator` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- Loop pattern: sequential, continuous-pr, rfc-dag, or infinite
- Mode: safe (default) or fast
- The task or goal the loop should execute
- Explicit stop condition (required)

---

First, reply to the user briefly to confirm you are delegating to `loop-operator`.

Then call sessions_spawn:
```json
{
  "agentId": "loop-operator",
  "sessionKey": "loop-operator",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
