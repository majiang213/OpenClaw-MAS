---
name: cmd_cpp_test
description: "Implement C++ code using TDD with GoogleTest — write failing tests first, implement to pass, verify coverage with gcov/lcov."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `cpp-build-resolver` agent to implement C++ code using TDD.

Include in the task payload:
- What to implement (function, class, module)
- Test framework in use (GoogleTest, Catch2, doctest)
- CMake configuration and build directory
- Coverage target (default: 80%)
- Any existing test fixtures or helpers to reuse

The agent writes failing tests first (RED), implements minimal code to pass (GREEN), then refactors — verifying coverage with gcov/lcov.

---

First, reply to the user briefly to confirm you are delegating to `cpp-build-resolver`.

Then call sessions_spawn:
```json
{
  "agentId": "cpp-build-resolver",
  "sessionKey": "cpp-build-resolver",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
