---
name: cmd_gan_design
description: "GAN-style design loop (generator → evaluator) focused on frontend visual quality — iterates until design score passes threshold."
user-invocable: true
origin: openclaw-mas
---

Run a GAN-style design harness using two specialist agents in sequence: `gan-generator` → `gan-evaluator`.

Include in the task payload:
- The design brief (description of what to create — this becomes the spec directly, no planner step)
- `--max-iterations N` (default 10) — maximum design-evaluate cycles
- `--pass-threshold N` (default 7.5) — weighted score to pass (higher than gan-build for design quality)

The generator focuses on visual excellence over feature completeness. The evaluator uses a design-weighted rubric (Design Quality 35%, Originality 30%, Craft 25%, Functionality 10%). Loop continues until score ≥ threshold.

---

Execute specialist agents in sequence: gan-generator → gan-evaluator

1. Reply to the user briefly, then call sessions_spawn:
```json
{
  "agentId": "gan-generator",
  "sessionKey": "gan-generator",
  "task": "<task description with full context from previous step>",
  "runTimeoutSeconds": 300
}
```
Wait for this agent to complete before proceeding.

2. Reply to the user briefly, then call sessions_spawn:
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
