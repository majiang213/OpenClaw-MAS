---
name: cmd_gan_build
description: "GAN-style three-agent build loop (planner → generator → evaluator) — iterates until the build passes a quality threshold or max iterations."
user-invocable: true
origin: openclaw-mas
---

Run a GAN-style build harness using three specialist agents in sequence: `gan-planner` → `gan-generator` → `gan-evaluator`.

Include in the task payload:
- The user's build brief (one-line description of what to build)
- `--max-iterations N` (default 15) — maximum generator-evaluator cycles
- `--pass-threshold N` (default 7.0) — weighted score to pass
- `--skip-planner` if `gan-harness/spec.md` already exists
- `--eval-mode` (default `playwright`) — one of: `playwright`, `screenshot`, `code-only`

The planner produces `spec.md` and `eval-rubric.md`. The generator builds iteratively. The evaluator scores against the rubric and writes feedback. Loop continues until score ≥ threshold or max iterations reached.

---

Execute specialist agents in sequence: gan-planner → gan-generator → gan-evaluator

1. Reply to the user briefly, then call sessions_spawn:
```json
{
  "agentId": "gan-planner",
  "sessionKey": "gan-planner",
  "task": "<task description with full context from previous step>",
  "runTimeoutSeconds": 300
}
```
Wait for this agent to complete before proceeding.

2. Reply to the user briefly, then call sessions_spawn:
```json
{
  "agentId": "gan-generator",
  "sessionKey": "gan-generator",
  "task": "<task description with full context from previous step>",
  "runTimeoutSeconds": 300
}
```
Wait for this agent to complete before proceeding.

3. Reply to the user briefly, then call sessions_spawn:
```json
{
  "agentId": "gan-evaluator",
  "sessionKey": "gan-evaluator",
  "task": "<task description with full context from previous step>",
  "runTimeoutSeconds": 300
}
```
Wait for this agent to complete before proceeding.

Do not spawn the next agent until the current one completes. Do not spawn agents in parallel.
After all agents complete, return the final result to the user.
