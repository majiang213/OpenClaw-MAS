---
name: cmd_flutter_review
description: "Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [files or modules]"
---

Delegate to the `flutter-reviewer` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- Files or modules to review (or 'all changed files' for a pre-commit review)
- Language version and key dependencies
- Whether this is a pre-commit review or a PR review
- Any specific concerns

---

First, reply to the user briefly to confirm you are delegating to `flutter-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "flutter-reviewer",
  "sessionKey": "flutter-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
