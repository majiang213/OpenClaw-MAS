---
name: cmd_harness_audit
description: "harness-audit workflow"
user-invocable: true
origin: openclaw-mas
---

Delegate to the `harness-optimizer` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- Scope: repo (full), hooks, skills, commands, or agents (default: repo)
- Output format preference: text (default) or json
- Any known issues or areas of concern to prioritize

---

First, reply to the user briefly to confirm you are delegating to `harness-optimizer`.

Then call sessions_spawn:
```json
{
  "agentId": "harness-optimizer",
  "sessionKey": "harness-optimizer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
