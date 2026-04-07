---
name: cmd_refactor_clean
description: "refactor-clean workflow"
user-invocable: true
origin: openclaw-mas
---

Delegate to the `refactor-cleaner` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- Scope: specific files/directories or full codebase
- Tech stack (Node.js, TypeScript, Python, Go, Rust, etc.)
- Whether to auto-delete or report only
- Any known areas of dead code or unused exports to prioritize

---

First, reply to the user briefly to confirm you are delegating to `refactor-cleaner`.

Then call sessions_spawn:
```json
{
  "agentId": "refactor-cleaner",
  "sessionKey": "refactor-cleaner",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
