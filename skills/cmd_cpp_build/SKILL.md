---
name: cmd_cpp_build
description: "Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path>"
---

Delegate to the `cpp-build-resolver` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- The full build error output
- Language/framework version
- Any recent changes that may have caused the breakage

---

First, reply to the user briefly to confirm you are delegating to `cpp-build-resolver`.

Then call sessions_spawn:
```json
{
  "agentId": "cpp-build-resolver",
  "sessionKey": "cpp-build-resolver",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
