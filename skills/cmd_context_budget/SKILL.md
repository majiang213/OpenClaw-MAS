---
name: cmd_context_budget
description: "Analyze and optimize context window usage — inventories loaded context, detects bloat, and returns prioritized savings recommendations."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `harness-optimizer` agent to analyze context budget usage.

Include in the task payload:
- Whether to run in verbose mode (`--verbose` flag)
- Context window size if different from default (200K)
- Specific files, rules, or agents suspected of causing context bloat
- Whether this is a recurring issue or a one-time audit

The agent inventories all loaded context (rules, skills, agents, memory), detects inefficiencies, and returns a prioritized list of savings actions.

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
