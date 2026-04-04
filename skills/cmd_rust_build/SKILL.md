---
name: cmd_rust_build
description: "Fix Rust build errors, borrow checker issues, and dependency problems incrementally. Invokes the rust-build-resolver agent for minimal, surgical fixes."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `rust-build-resolver` agent to fix Rust build failures.

Include in the task payload:
- The full error output from `cargo check` or `cargo build`
- Rust edition and toolchain version (stable/nightly)
- Any recent changes that may have caused the breakage
- Whether clippy or fmt issues are also present

The agent runs `cargo check`, `cargo clippy`, and `cargo fmt --check`, then fixes errors one at a time — verifying after each change.

---

First, reply to the user briefly to confirm you are delegating to `rust-build-resolver`.

Then call sessions_spawn:
```json
{
  "agentId": "rust-build-resolver",
  "sessionKey": "rust-build-resolver",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
