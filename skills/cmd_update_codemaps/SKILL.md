---
name: cmd_update_codemaps
description: "Regenerate docs/CODEMAPS/* to reflect the current codebase structure, module boundaries, and key entry points."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `doc-updater` agent to regenerate codemaps.

Include in the task payload:
- The codebase root or specific modules to remap
- Whether this follows a significant refactor, new feature, or file restructure
- Any existing CODEMAPS to update vs. create from scratch

The agent runs `/update-codemaps`, generates `docs/CODEMAPS/*`, and ensures the maps reflect the current module structure.

---

First, reply to the user briefly to confirm you are delegating to `doc-updater`.

Then call sessions_spawn:
```json
{
  "agentId": "doc-updater",
  "sessionKey": "doc-updater",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
