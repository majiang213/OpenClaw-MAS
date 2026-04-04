---
name: cmd_rust_review
description: "Review Rust code for ownership correctness, lifetime issues, unsafe usage, error handling patterns, and idiomatic style."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `rust-reviewer` agent for a comprehensive Rust code review.

Include in the task payload:
- Files or modules to review (or "all changed files" for a pre-commit review)
- Rust edition and toolchain version
- Whether this is a pre-commit review or a PR review
- Any specific concerns (unsafe blocks, async patterns, performance)

The agent checks for unchecked `unwrap()`, `unsafe` without `// SAFETY:` comments, unnecessary clones, blocking in async context, and security issues. It runs `cargo clippy -- -D warnings` and `cargo audit`.

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
