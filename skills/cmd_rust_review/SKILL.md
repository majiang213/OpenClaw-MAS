---
name: cmd_rust_review
description: "Comprehensive Rust code review for ownership, lifetimes, error handling, unsafe usage, and idiomatic patterns. Invokes the rust-reviewer agent."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `rust-reviewer` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- Files or modules to review (or 'all changed files' for a pre-commit review)
- Language version and key dependencies
- Whether this is a pre-commit review or a PR review
- Any specific concerns

---

First, reply to the user briefly to confirm you are delegating to `rust-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "rust-reviewer",
  "sessionKey": "rust-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
