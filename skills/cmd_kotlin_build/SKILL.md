---
name: cmd_kotlin_build
description: "Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `kotlin-build-resolver` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- The full build error output
- Language/framework version
- Any recent changes that may have caused the breakage

---

First, reply to the user briefly to confirm you are delegating to `kotlin-build-resolver`.

Then call sessions_spawn:
```json
{
  "agentId": "kotlin-build-resolver",
  "sessionKey": "kotlin-build-resolver",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
