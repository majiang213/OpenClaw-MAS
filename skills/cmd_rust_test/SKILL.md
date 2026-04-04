---
name: cmd_rust_test
description: "Implement Rust code using TDD — write failing tests first, implement to pass, verify 80%+ coverage with cargo-llvm-cov."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `rust-build-resolver` agent to implement Rust code using TDD.

Include in the task payload:
- What to implement (function, struct, trait, module)
- Rust edition and any relevant crate dependencies
- Test approach preferred (unit tests, rstest parameterized, proptest, async with tokio::test)
- Coverage target (default: 80%)
- Any existing test helpers or fixtures to reuse

The agent writes tests in `#[cfg(test)]` modules first (RED), implements minimal code to pass (GREEN), then refactors — verifying coverage with `cargo llvm-cov`.

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
