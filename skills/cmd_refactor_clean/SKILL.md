---
name: cmd_refactor_clean
description: "Remove dead code, unused exports, duplicate logic, and deprecated patterns. Runs analysis tools (knip, depcheck, ts-prune) to identify and safely delete unused code."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `refactor-cleaner` agent to identify and remove dead code.

Include in the task payload:
- Scope: specific files/directories or full codebase
- Tech stack (Node.js, TypeScript, Python, Go, Rust, etc.)
- Whether to auto-delete or report only
- Any known areas of dead code or unused exports to prioritize
- Constraints (e.g., "don't touch the public API surface")

The agent runs static analysis tools, identifies unused code, and removes it safely with minimal diffs — verifying tests pass after each deletion.

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
