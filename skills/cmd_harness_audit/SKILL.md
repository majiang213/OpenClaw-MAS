---
name: cmd_harness_audit
description: "Audit the local agent harness for reliability, cost, and throughput — returns a prioritized scorecard with actionable improvements."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `harness-optimizer` agent to audit the agent harness configuration.

Include in the task payload:
- Scope: `repo` (full), `hooks`, `skills`, `commands`, or `agents` (default: repo)
- Output format preference: `text` (default) or `json` (for automation)
- Specific path to audit if not the current working directory
- Any known issues or areas of concern to prioritize

The agent runs the deterministic harness audit script, scores 7 categories (Tool Coverage, Context Efficiency, Quality Gates, Memory Persistence, Eval Coverage, Security Guardrails, Cost Efficiency), and returns the top 3 actions.

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
