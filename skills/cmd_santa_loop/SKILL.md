---
name: cmd_santa_loop
description: "Adversarial dual-review convergence loop — two independent model reviewers must both approve before code ships. Up to 3 fix rounds."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `code-reviewer` agent to run the santa-loop dual-review protocol.

Include in the task payload:
- The files, glob pattern, or description of what to review
- Falls back to uncommitted changes (`git diff --name-only HEAD`) if no scope given
- Any domain-specific rubric criteria to add (beyond the defaults: correctness, security, error handling, completeness, consistency, no regressions)

The agent runs two independent reviewers in parallel (Claude Opus + external model if available). Both must return PASS before code is pushed. If either fails, all issues are fixed and fresh reviewers re-run — up to 3 rounds. Escalates to user if unresolved after 3 iterations.

---

First, reply to the user briefly to confirm you are delegating to `code-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "code-reviewer",
  "sessionKey": "code-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
