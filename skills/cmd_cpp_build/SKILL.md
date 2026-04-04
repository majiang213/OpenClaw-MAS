---
name: cmd_cpp_build
description: "Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `cpp-build-resolver` agent to fix C++ build failures.

Include in the task payload:
- The full build error output (`cmake --build` or compiler errors)
- Build system in use (CMake, Makefile, Bazel, etc.)
- C++ standard version (C++17, C++20, etc.)
- Any recent changes that may have caused the breakage

The agent runs `cmake --build`, `clang-tidy`, and `cppcheck`, then fixes errors one at a time — verifying after each change.

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
