---
name: cmd_context_budget
description: "Legacy slash-entry shim for the context-budget skill. Prefer the skill directly."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `harness-optimizer` agent.

Include in the task payload:
- Whether to run in verbose mode
- Context window size if different from default (200K)
- Specific files, rules, or agents suspected of causing context bloat

---

First, reply to the user briefly to confirm you are delegating to `harness-optimizer`.

Then call sessions_spawn:
```json
{
  "agentId": "harness-optimizer",
  "sessionKey": "harness-optimizer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
