---
name: cmd_python_review
description: "Review Python code for PEP 8 compliance, type hints, security vulnerabilities, and Pythonic idioms."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `python-reviewer` agent for a comprehensive Python code review.

Include in the task payload:
- Files or modules to review (or "all changed files" for a pre-commit review)
- Python version and key dependencies/framework (Django, FastAPI, Flask, etc.)
- Whether this is a pre-commit review or a PR review
- Any specific concerns (SQL injection, type safety, async patterns)

The agent checks for injection vulnerabilities, mutable defaults, missing type hints, bare `except` clauses, and PEP 8 violations. It runs `ruff`, `mypy`, `bandit`, and `black --check`.

---

First, reply to the user briefly to confirm you are delegating to `python-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "python-reviewer",
  "sessionKey": "python-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
