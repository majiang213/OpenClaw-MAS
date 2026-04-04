---
name: cmd_kotlin_test
description: "Implement Kotlin code using TDD with Kotest — write failing tests first, implement to pass, verify 80%+ coverage with Kover."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `kotlin-build-resolver` agent to implement Kotlin code using TDD.

Include in the task payload:
- What to implement (function, class, service)
- Kotlin version, platform (Android/KMP/JVM), and test framework (Kotest, JUnit5)
- Any existing test fixtures, mocks, or MockK configurations to reuse
- Coverage target (default: 80%)
- Whether coroutine testing (`runTest`) is needed

The agent writes Kotest specs first (RED), implements minimal code to pass (GREEN), then refactors — verifying coverage with `./gradlew koverHtmlReport`.

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
