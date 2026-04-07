---
name: cmd_python_review
description: "Comprehensive Python code review for PEP 8 compliance, type hints, security, and Pythonic idioms. Invokes the python-reviewer agent."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `python-reviewer` agent.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- Files or modules to review (or 'all changed files' for a pre-commit review)
- Language version and key dependencies
- Whether this is a pre-commit review or a PR review
- Any specific concerns

---

First, reply to the user briefly to confirm you are delegating to `python-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "python-reviewer",
  "sessionKey": "python-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
