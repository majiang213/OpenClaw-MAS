---
name: cmd_plan
description: "Create an implementation plan before writing code — restate requirements, identify risks, break down into phases, and wait for user confirmation before touching any code."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `planner` agent to produce a structured implementation plan.

Include in the task payload:
- The full feature or change request
- Relevant codebase context (tech stack, affected files/modules if known)
- Any constraints, deadlines, or preferences the user mentioned
- Whether this is a new feature, refactor, bug fix, or architectural change

The planner will restate requirements, identify risks, break the work into phases, and **wait for user confirmation before any code is written**.

---

First, reply to the user briefly to confirm you are delegating to `planner`.

Then call sessions_spawn:
```json
{
  "agentId": "planner",
  "sessionKey": "planner",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
