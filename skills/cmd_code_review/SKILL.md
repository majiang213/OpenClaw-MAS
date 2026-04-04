---
name: cmd_code_review
description: "Review code for quality, security, and correctness — local uncommitted changes or a GitHub PR (pass PR number or URL for PR mode)."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `code-reviewer` agent for a comprehensive code review.

Include in the task payload:
- Whether this is a local review (uncommitted changes) or a PR review
- PR number or URL if reviewing a GitHub PR
- Specific files, modules, or areas of concern if any
- Tech stack and any project-specific conventions
- Whether to post the review back to GitHub or report locally only

The agent covers correctness, type safety, security, performance, pattern compliance, and completeness. It will approve, request changes, or block based on severity of findings.

---

First, reply to the user briefly to confirm you are delegating to `code-reviewer`.

Then call sessions_spawn:
```json
{
  "agentId": "code-reviewer",
  "sessionKey": "code-reviewer",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
