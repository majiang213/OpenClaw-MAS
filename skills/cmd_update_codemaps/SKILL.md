---
name: cmd_update_codemaps
description: "Regenerate CODEMAPS documentation for the codebase or specific modules via the doc-updater agent."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path>"
---

Delegate to the `doc-updater` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- The codebase root or specific modules to remap
- Whether this follows a significant refactor, new feature, or file restructure
- Any existing CODEMAPS to update vs. create from scratch

---

First, reply to the user briefly to confirm you are delegating to `doc-updater`.

Then call sessions_spawn:
```json
{
  "agentId": "doc-updater",
  "sessionKey": "doc-updater",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
