---
name: cmd_cpp_review
description: "Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `cpp-reviewer` agent.

Include in the task payload:
- Files or modules to review (or 'all changed files' for a pre-commit review)
- Language version and key dependencies
- Whether this is a pre-commit review or a PR review
- Any specific concerns

---

First, reply to the user briefly to confirm you are delegating to `cpp-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "cpp-reviewer",
  "sessionKey": "cpp-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
