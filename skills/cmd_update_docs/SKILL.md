---
name: cmd_update_docs
description: "update-docs workflow"
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [what changed]"
---

Delegate to the `doc-updater` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- What changed (feature, API, config, architecture)
- Which docs need updating (README, CHANGELOG, API reference, guides)
- Any specific sections or files to focus on

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
