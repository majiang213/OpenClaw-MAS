---
name: cmd_tdd
description: "Legacy slash-entry shim for the tdd-workflow skill. Prefer the skill directly."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `tdd-guide` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- What to build (feature, fix, or refactor)
- Relevant files, modules, or components involved
- Tech stack and test framework in use
- Any existing tests or coverage requirements to meet

---

First, reply to the user briefly to confirm you are delegating to `tdd-guide`.

Then call sessions_spawn:
```json
{
  "agentId": "tdd-guide",
  "sessionKey": "tdd-guide",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
