---
name: cmd_gradle_build
description: "Fix Gradle build errors for Android, KMP, and JVM projects — resolves compiler errors, dependency conflicts, and configuration issues."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `java-build-resolver` agent to fix Gradle build failures.

Include in the task payload:
- The full build error output (`./gradlew build` or `./gradlew assemble`)
- Project type (Android, KMP, pure JVM)
- Kotlin and Gradle versions
- Any recent dependency or API changes that may have caused the breakage

The agent detects the build configuration, runs the appropriate Gradle tasks, and fixes errors one at a time — verifying after each change.

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
