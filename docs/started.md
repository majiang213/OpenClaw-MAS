# OpenClaw MAS — Getting Started

This guide covers how to use OpenClaw MAS after installation: skill invocation, development workflows, agent delegation, hook authoring, and skill creation.

> **Installing?** See the [README](../README.md) for installation instructions.

---

## Table of Contents

1. [Invoking Skills](#1-invoking-skills)
2. [Development Workflows](#2-development-workflows)
3. [Working with Agents](#3-working-with-agents)
4. [Writing Hooks](#4-writing-hooks)
5. [Creating Skills](#5-creating-skills)
6. [Quick Reference](#6-quick-reference)

---

## 1. Invoking Skills

### Syntax

```
/skill <skill_name> <project_path> [additional args]
```

The project path is almost always required as the first argument — it tells the agent where to work.

### Skill types

Skills fall into two categories:

| Type | Execution | Behavior |
|------|-----------|----------|
| **Type A** | Delegates to a specialist agent via `sessions_spawn` | Async — main agent waits for the `announce` callback |
| **Type B** | Main agent executes directly | Synchronous — result returned immediately |

**Type A examples:**
```
/skill cmd_tdd ~/.openclaw/projects/myapp implement JWT login
/skill cmd_code_review ~/.openclaw/projects/myapp
/skill cmd_plan ~/.openclaw/projects/myapp add payment integration
```

**Type B examples:**
```
/skill cmd_build_fix ~/.openclaw/projects/myapp
/skill cmd_save_session ~/.openclaw/projects/myapp
/skill cmd_hookify ~/.openclaw/projects/myapp prevent direct edits to eslint config
```

### Multi-agent pipelines (GAN)

GAN skills run agents **serially** — never in parallel:

```
/skill cmd_gan_build ~/.openclaw/projects/myapp build a real-time collaborative whiteboard
```

Pipeline: `gan-planner` → `gan-generator` → `gan-evaluator`

Each agent completes and sends an `announce` before the next one starts. The evaluator scores the output; if the score is below 7.0 it loops back to `gan-generator`.

---

## 2. Development Workflows

### New feature

```bash
# 1. Plan (waits for user approval before touching code)
/skill cmd_plan ~/.openclaw/projects/myapp <feature description>

# 2. Implement with TDD
/skill cmd_tdd ~/.openclaw/projects/myapp <what to build>

# 3. Review
/skill cmd_code_review ~/.openclaw/projects/myapp

# 4. Security scan (when touching auth or user input)
/skill cmd_security_scan ~/.openclaw/projects/myapp
```

**All-in-one guided workflow** (explore → design → implement → review):
```
/skill cmd_feature_dev ~/.openclaw/projects/myapp <feature description>
```

### Bug fix / build errors

```bash
/skill cmd_build_fix ~/.openclaw/projects/myapp       # fix build/type errors incrementally
/skill cmd_refactor_clean ~/.openclaw/projects/myapp  # remove dead code
```

### Code review

```bash
/skill cmd_code_review ~/.openclaw/projects/myapp            # local uncommitted changes
/skill cmd_code_review ~/.openclaw/projects/myapp PR#123     # GitHub PR
/skill cmd_review_pr ~/.openclaw/projects/myapp PR#123       # PR + test analysis

# Language-specific review
/skill cmd_rust_review ~/.openclaw/projects/myapp
/skill cmd_kotlin_review ~/.openclaw/projects/myapp
/skill cmd_python_review ~/.openclaw/projects/myapp
/skill cmd_go_review ~/.openclaw/projects/myapp
/skill cmd_cpp_review ~/.openclaw/projects/myapp
/skill cmd_flutter_review ~/.openclaw/projects/myapp
```

### TDD workflow

```
/skill cmd_tdd ~/.openclaw/projects/myapp <feature description>
```

The `tdd-guide` agent runs: **Scaffold** → **RED** (failing tests) → **GREEN** (minimal implementation) → **REFACTOR** → coverage ≥ 80%.

### Session management

```bash
/skill cmd_save_session ~/.openclaw/projects/myapp    # checkpoint current session
/skill cmd_resume_session ~/.openclaw/projects/myapp  # restore last checkpoint
/skill cmd_sessions ~/.openclaw/projects/myapp        # list all sessions
```

---

## 3. Working with Agents

### Agent workspace files

Each specialist agent has its own workspace. Only two files are loaded when a subagent starts:

| File | Loaded by subagent | Purpose |
|------|--------------------|---------|
| `AGENTS.md` | ✅ Yes | **Workflow instructions** — put all logic here |
| `TOOLS.md` | ✅ Yes | Available tools |
| `SOUL.md` | ❌ No | General personality |
| `IDENTITY.md` | ❌ No | Role anchor |
| `USER.md` | ❌ No | Collaboration notes |
| `HEARTBEAT.md` | ❌ No | Periodic tasks |

**Rule:** All workflow instructions must live in `AGENTS.md`. Subagents never load `SOUL.md`.

### sessions_spawn format

```json
{
  "agentId": "tdd-guide",
  "sessionKey": "tdd-guide",
  "task": "<full task description with all context — the subagent cannot see this conversation>",
  "runTimeoutSeconds": 0
}
```

The `task` field must be self-contained: include project path, requirements, relevant files, and any constraints. Subagents have no access to the calling agent's conversation history.

### Spawn depth

`maxSpawnDepth: 2` is required in `openclaw.json`:

- **Depth 1** — main agent → specialist agent (most skills)
- **Depth 2** — main agent → orchestrator → worker agents (GAN pipelines)

### Available specialist agents

| Agent | Role |
|-------|------|
| `tdd-guide` | TDD workflow |
| `planner` | Implementation planning |
| `code-reviewer` | Code review |
| `code-explorer` | Codebase exploration |
| `code-architect` | Architecture design |
| `security-reviewer` | Security analysis |
| `build-error-resolver` | General build error fixing |
| `rust-reviewer`, `kotlin-reviewer`, `go-reviewer`, etc. | Language-specific review |
| `cpp-build-resolver`, `kotlin-build-resolver`, etc. | Language-specific build fixing |
| `e2e-runner` | E2E test generation and execution |
| `database-reviewer` | Database query and schema review |
| `doc-updater` | Documentation updates |
| `refactor-cleaner` | Dead code removal and cleanup |
| `gan-planner`, `gan-generator`, `gan-evaluator` | GAN pipeline stages |

---

## 4. Writing Hooks

### Choosing the right hook system

| Use case | System |
|----------|--------|
| Intercept tool calls (Bash / Edit / Write) | **Plugin hook** — `before_tool_call` / `after_tool_call` |
| Session lifecycle (start / end) | **Plugin hook** — `session_start` / `session_end` |
| Message flow, conversation routing | **Internal hook** |
| Inject context at agent bootstrap | **Internal hook** — `agent:bootstrap` |
| Save state before compaction | **Internal hook** — `session:compact:before` |

### Internal hook structure

```
<project>/.openclaw/hooks/<hook-name>/
├── HOOK.md
└── handler.ts
```

**HOOK.md:**
```markdown
---
name: <hook-name>
description: "<what this hook warns about>"
events: ["<event:action>"]
enabled: true
emoji: "🛡️"
---
```

**handler.ts:**
```typescript
import type { InternalHookEvent } from "openclaw/plugin-sdk/hook-runtime";

const handler = async (event: InternalHookEvent) => {
  if (event.type !== "<type>" || event.action !== "<action>") return;

  const ctx = event.context as Record<string, unknown>;
  const content = (ctx.content ?? ctx.commandSource ?? '') as string;

  if (/<pattern>/i.test(content)) {
    event.messages.push('⚠️ Warning: <description>');
  }
};
export default handler;
```

**Limitation:** Internal hooks can only **warn** (push messages). They cannot block actions. To block, use a plugin hook with `before_tool_call`.

### Internal hook event reference

| Event | `type` | `action` | Key context fields |
|-------|--------|----------|--------------------|
| `command:new` | `command` | `new` | `commandSource`, `workspaceDir`, `sessionEntry` |
| `message:received` | `message` | `received` | `from`, `content`, `channelId` |
| `message:sent` | `message` | `sent` | `to`, `content`, `success` |
| `agent:bootstrap` | `agent` | `bootstrap` | `workspaceDir`, `bootstrapFiles`, `agentId` |
| `session:patch` | `session` | `patch` | `sessionEntry`, `patch` |
| `gateway:startup` | `gateway` | `startup` | `cfg`, `workspaceDir` |

### Plugin hook return values (`before_tool_call`)

```typescript
// Block execution entirely
return { block: true, blockReason: "reason" }

// Require user confirmation
return {
  requireApproval: {
    title: "Title",
    description: "Details",
    severity: "warning",          // "info" | "warning" | "critical"
    timeoutMs: 30000,
    timeoutBehavior: "deny",      // "allow" | "deny"
  }
}

// Modify parameters and allow through
return { params: { ...modifiedParams } }
```

`after_tool_call` is read-only — use it for logging, accumulation, and side effects. It cannot block.

### Generate hooks automatically

```bash
# Analyze conversation and auto-detect behaviors worth preventing
/skill cmd_hookify ~/.openclaw/projects/myapp

# Target a specific behavior
/skill cmd_hookify ~/.openclaw/projects/myapp prevent direct edits to tsconfig.json
/skill cmd_hookify ~/.openclaw/projects/myapp require confirmation before git push
```

Register the generated hook:
```bash
openclaw hooks enable <hook-name>
```

---

## 5. Creating Skills

### SKILL.md format

```markdown
---
name: <skill_name>        # [a-z0-9_], max 32 chars
description: "<one-line description>"
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:
1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# <Skill Title>

<Description>

## Usage

`/skill <name> <project-path> [args]`

## Workflow

<Steps>
```

### Type A skill (delegate to specialist agent)

```markdown
Delegate to the `<agent-id>` agent.

Include in the task payload:
- Project path
- <other required context>

---

First, reply to the user briefly to confirm you are delegating to `<agent-id>`.

Then call sessions_spawn:
```json
{
  "agentId": "<agent-id>",
  "sessionKey": "<agent-id>",
  "task": "<user's full request and all relevant context>",
  "runTimeoutSeconds": 0
}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
```

### Type B skill (direct execution)

Describe the steps directly. No `sessions_spawn` call.

### Generate skills from git history

```bash
/skill cmd_skill_create ~/.openclaw/projects/myapp
/skill cmd_skill_create ~/.openclaw/projects/myapp --commits 100
/skill cmd_skill_create ~/.openclaw/projects/myapp --instincts  # also generate instincts
```

### Skill locations

| Location | Purpose |
|----------|---------|
| `~/.openclaw/skills/` | Installed skills, shared across all agents |
| `openclaw/skills/cmd_*/` | Source for command skills |
| `openclaw/ecc-skills/` | Upstream ECC skills (read-only, synced from ECC) |

---

## 6. Quick Reference

### Development

| Skill | Type | Purpose |
|-------|------|---------|
| `cmd_plan` | A | Plan implementation — waits for approval before writing code |
| `cmd_tdd` | A | TDD workflow (RED → GREEN → REFACTOR) |
| `cmd_feature_dev` | A (multi) | Full feature cycle: explore → design → implement → review |
| `cmd_build_fix` | B | Fix build/type errors incrementally |
| `cmd_refactor_clean` | B | Remove dead code and clean up |

### Review & Security

| Skill | Type | Purpose |
|-------|------|---------|
| `cmd_code_review` | A | Review local changes or a GitHub PR |
| `cmd_review_pr` | A | PR review with test analysis |
| `cmd_security_scan` | A | Security vulnerability scan |
| `cmd_rust_review`, `cmd_go_review`, `cmd_kotlin_review`, etc. | A | Language-specific review |

### Testing

| Skill | Type | Purpose |
|-------|------|---------|
| `cmd_e2e` | A | Generate and run E2E tests |
| `cmd_test_coverage` | B | Check test coverage |
| `cmd_rust_test`, `cmd_go_test`, `cmd_kotlin_test`, etc. | A | Language-specific test runner |

### Build

| Skill | Type | Purpose |
|-------|------|---------|
| `cmd_build_fix` | B | General build error fixing |
| `cmd_gradle_build`, `cmd_kotlin_build`, `cmd_rust_build`, etc. | A | Language-specific build fixing |

### Session

| Skill | Type | Purpose |
|-------|------|---------|
| `cmd_save_session` | B | Save session state |
| `cmd_resume_session` | B | Restore session state |
| `cmd_sessions` | B | List sessions |
| `cmd_checkpoint` | B | Create a checkpoint |
| `cmd_context_budget` | B | Check context window usage |

### Hooks

| Skill | Type | Purpose |
|-------|------|---------|
| `cmd_hookify` | B | Create hook rules from conversation or description |
| `cmd_hookify_list` | B | List installed hooks |
| `cmd_hookify_configure` | B | Configure a hook |

### Knowledge & Rules

| Skill | Type | Purpose |
|-------|------|---------|
| `cmd_skill_create` | B | Generate skills from git history |
| `cmd_learn` | B | Extract reusable patterns from current session |
| `cmd_rules_distill` | B | Distill rules from session patterns |
| `cmd_update_docs` | A | Update documentation |

### Orchestration

| Skill | Type | Purpose |
|-------|------|---------|
| `cmd_orchestrate` | B | Coordinate multi-agent workflows |
| `cmd_devfleet` | B | Multi-project, multi-instance orchestration |
| `cmd_gan_build` | A (multi) | GAN pipeline: plan → generate → evaluate |
| `cmd_gan_design` | A (multi) | GAN design pipeline |

---

## Core Rules

1. **Type A skills must name the agent explicitly** — the main agent should not guess which agent to spawn.
2. **GAN pipelines must be serial** — never spawn the next agent before receiving the previous `announce`.
3. **All workflow logic goes in `AGENTS.md`** — subagents do not load `SOUL.md`.
4. **`task` payloads must be self-contained** — subagents cannot see the calling conversation.
5. **Internal hooks can only warn** — to block an action, use a plugin hook with `before_tool_call`.
6. **Set `maxSpawnDepth: 2`** — required for any two-level agent nesting.
