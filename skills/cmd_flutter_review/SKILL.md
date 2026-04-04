---
name: cmd_flutter_review
description: "Review Flutter/Dart code for widget best practices, state management patterns, performance issues, accessibility, and security."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `flutter-reviewer` agent for a comprehensive Flutter/Dart code review.

Include in the task payload:
- Files or widgets to review (or "all changed files" for a pre-commit review)
- Flutter version and state management solution (Riverpod, Bloc, Provider, etc.)
- Whether this is a pre-commit review or a PR review
- Any specific concerns (BuildContext after async, widget rebuilds, accessibility)

The agent checks for `BuildContext` after async gaps, missing `dispose()`, `GlobalScope` usage, missing error/loading states, and hardcoded strings. It runs `flutter analyze`.

---

First, reply to the user briefly to confirm you are delegating to `flutter-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "flutter-reviewer",
  "sessionKey": "flutter-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
