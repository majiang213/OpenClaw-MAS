---
name: cmd_update_docs
description: "Update project documentation — READMEs, guides, API docs, and changelogs — to reflect recent code changes."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `doc-updater` agent to update documentation.

Include in the task payload:
- What changed (feature, API, config, architecture)
- Which docs need updating (README, CHANGELOG, API reference, guides)
- Any specific sections or files to focus on
- Whether to run `/update-codemaps` as part of this update

The agent updates READMEs, guides, and other docs to match the current state of the codebase.

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
