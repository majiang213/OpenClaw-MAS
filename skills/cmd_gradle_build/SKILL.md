---
name: cmd_gradle_build
description: "Fix Gradle build errors for Android and KMP projects"
user-invocable: true
origin: openclaw-mas
---

Delegate to the `java-build-resolver` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- The full build error output
- Language/framework version
- Any recent changes that may have caused the breakage

---

First, reply to the user briefly to confirm you are delegating to `java-build-resolver`.

Then call sessions_spawn:
```json
{
  "agentId": "java-build-resolver",
  "sessionKey": "java-build-resolver",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
