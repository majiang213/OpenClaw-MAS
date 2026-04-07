---
name: cmd_santa_loop
description: "Adversarial dual-review convergence loop — two independent model reviewers must both approve before code ships."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `code-reviewer` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- The files, glob pattern, or description of what to review
- Falls back to uncommitted changes if no scope given
- Any domain-specific rubric criteria to add

---

First, reply to the user briefly to confirm you are delegating to `code-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "code-reviewer",
  "sessionKey": "code-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
