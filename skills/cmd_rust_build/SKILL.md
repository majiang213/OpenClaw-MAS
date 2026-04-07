---
name: cmd_rust_build
description: "Fix Rust build errors, borrow checker issues, and dependency problems incrementally. Invokes the rust-build-resolver agent for minimal, surgical fixes."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `rust-build-resolver` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- The full build error output
- Language/framework version
- Any recent changes that may have caused the breakage

---

First, reply to the user briefly to confirm you are delegating to `rust-build-resolver`.

Then call sessions_spawn:
```json
{
  "agentId": "rust-build-resolver",
  "sessionKey": "rust-build-resolver",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
