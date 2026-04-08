---
name: cmd_gan_build
description: "gan-build workflow"
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> <build description>"
---

Run specialist agents in sequence: gan-planner → gan-generator → gan-evaluator.

Include in the task payload:
- Project path (the absolute path the user provided as the first argument)
- The user's full request and build/design brief
- Any flags or configuration options (max iterations, pass threshold, etc.)
- Relevant codebase context



---

Execute specialist agents in sequence: gan-planner → gan-generator → gan-evaluator

1. Reply to the user briefly, then call sessions_spawn:
```json
{
  "agentId": "gan-planner",
  "sessionKey": "gan-planner",
  "task": "<task description with full context from previous step>",
  "runTimeoutSeconds": 0
}
```
Wait for this agent to complete before proceeding.

2. Reply to the user briefly, then call sessions_spawn:
```json
{
  "agentId": "gan-generator",
  "sessionKey": "gan-generator",
  "task": "<task description with full context from previous step>",
  "runTimeoutSeconds": 0
}
```
Wait for this agent to complete before proceeding.

3. Reply to the user briefly, then call sessions_spawn:
```json
{
  "agentId": "gan-evaluator",
  "sessionKey": "gan-evaluator",
  "task": "<task description with full context from previous step>",
  "runTimeoutSeconds": 0
}
```
Wait for this agent to complete before proceeding.

Do not spawn the next agent until the current one completes. Do not spawn agents in parallel.
After all agents complete, return the final result to the user.
