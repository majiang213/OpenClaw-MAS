---
name: cmd_kotlin_review
description: "Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `kotlin-reviewer` agent.

Include in the task payload:
- Files or modules to review (or 'all changed files' for a pre-commit review)
- Language version and key dependencies
- Whether this is a pre-commit review or a PR review
- Any specific concerns

---

First, reply to the user briefly to confirm you are delegating to `kotlin-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "kotlin-reviewer",
  "sessionKey": "kotlin-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
