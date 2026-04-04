---
name: cmd_e2e
description: "Generate, maintain, and run end-to-end tests for critical user flows using Playwright or Vercel Agent Browser."
user-invocable: true
origin: openclaw-mas
---

Delegate to the `e2e-runner` agent to handle E2E test generation and execution.

Include in the task payload:
- The user flows or features to test (e.g., "login flow", "checkout process")
- Base URL or dev server details if known
- Existing test files or framework configuration
- Whether to generate new tests, run existing ones, or both
- Any flaky tests to investigate or quarantine

The agent will generate test journeys, run them, upload artifacts (screenshots, traces), and report results.

---

First, reply to the user briefly to confirm you are delegating to `e2e-runner`.

Then call sessions_spawn:
```json
{
  "agentId": "e2e-runner",
  "sessionKey": "e2e-runner",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
