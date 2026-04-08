---
name: cmd_e2e
description: "Legacy slash-entry shim for the e2e-testing skill. Prefer the skill directly."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [user flow description]"
---

Delegate to the `e2e-runner` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- The user flows or features to test
- Base URL or dev server details if known
- Existing test files or framework configuration
- Whether to generate new tests, run existing ones, or both

---

First, reply to the user briefly to confirm you are delegating to `e2e-runner`.

Then call sessions_spawn:
```json
{
  "agentId": "e2e-runner",
  "sessionKey": "e2e-runner",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
