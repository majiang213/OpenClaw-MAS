---
name: cmd_code_review
description: "Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)"
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [PR#N or URL]"
---

Delegate to the `code-reviewer` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- Whether this is a local review (uncommitted changes) or a PR review
- PR number or URL if reviewing a GitHub PR
- Specific files, modules, or areas of concern if any
- Tech stack and any project-specific conventions

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
