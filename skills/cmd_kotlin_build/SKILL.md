---
name: cmd_kotlin_build
description: "Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `kotlin-build-resolver` agent to fix Kotlin/Gradle build failures.

Include in the task payload:
- The full build error output (`./gradlew build` errors)
- Kotlin version and Gradle version
- Whether this is Android, KMP, or JVM-only
- Any recent dependency or API changes that may have caused the breakage

The agent runs `./gradlew build`, `detekt`, and `ktlintCheck`, then fixes errors one at a time — verifying after each change.

---

First, reply to the user briefly to confirm you are delegating to `kotlin-build-resolver`.

Then call sessions_spawn:
```json
{
  "agentId": "kotlin-build-resolver",
  "sessionKey": "kotlin-build-resolver",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
