# OpenClaw MAS

A multi-agent development system that brings [Everything Claude Code](https://github.com/anthropics/everything-claude-code) workflows into [OpenClaw](https://docs.openclaw.ai). Use TDD, code review, build fixing, GAN loops, and 60+ other development workflows from any chat channel — Telegram, WhatsApp, Discord, or any channel OpenClaw supports.

---

## What's Included

- **37 specialist agents** — tdd-guide, rust-reviewer, code-reviewer, gan-planner, security-reviewer, and more
- **210 skills** — 142 upstream skills + 68 command skills covering the full development lifecycle
- **14 language rule sets** — Rust, Go, C++, Kotlin, Java, Python, Flutter, TypeScript, and more
- **Hooks** — safety guards, quality gates, and session memory, active automatically

---

## Requirements

- [OpenClaw](https://docs.openclaw.ai) installed and initialized (`~/.openclaw/openclaw.json` exists)
- `python3` available on your system
- This repository cloned locally

---

## Installation

### Option 1: Let your AI agent install it

Send this to your OpenClaw agent:

```
Clone https://github.com/majiang213/OpenClaw-MAS.git to ~/.openclaw/projects/OpenClaw-MAS, then read the README and follow the installation instructions.
```

The agent will clone the repo, run the install script, verify the result, and report back when done.

### Option 2: Install manually

```bash
git clone https://github.com/majiang213/OpenClaw-MAS.git
cd OpenClaw-MAS
bash install.sh
```

---

## Quick Start

Once installed, use `/skill <name>` in any OpenClaw chat. Always include the project path as the first argument:

```
/skill cmd_tdd ~/.openclaw/projects/myapp implement a login endpoint with JWT auth
/skill cmd_code_review ~/.openclaw/projects/myapp
/skill cmd_build_fix ~/.openclaw/projects/myapp
```

See [docs/started.md](./docs/started.md) for the full skill reference, development workflows, hook authoring, and skill creation.

---

## For AI Agents: Installation Instructions

> You are an AI agent reading this to install OpenClaw MAS on behalf of the user.
> Follow these steps exactly. Do not skip steps. Report progress after each step.

### Prerequisites

Verify the following before proceeding:

1. `openclaw` CLI is installed and `openclaw.json` exists at `~/.openclaw/openclaw.json`
2. `python3` is available
3. This repository (`everything-claude-code`) is cloned locally

If any prerequisite is missing, stop and tell the user what needs to be installed first.

### Installation

Run the install script from the repository root:

```bash
bash install.sh
```

The script will:
- Register 37 specialist agents into `openclaw.json`
- Install 210 skills into `~/.openclaw/skills/` (142 upstream skills + 68 command skills)
- Copy 14 language rule sets into each agent workspace
- Install hooks for safety checks, quality gates, and session memory
- Set `maxSpawnDepth: 2` and `commands.nativeSkills: true` in `openclaw.json`

### Verify Installation

After the script completes, confirm:

```bash
# Skills are installed
ls ~/.openclaw/skills/ | wc -l
# Should be 200+

# Agents are registered
grep -c '"id"' ~/.openclaw/openclaw.json
# Should be 37+
```

Then tell the user: "OpenClaw MAS is installed. You can now use `/skill <name>` in any OpenClaw chat."

---

## Further Reading

- [docs/started.md](./docs/started.md) — Skill invocation, workflows, hooks, and skill creation
- [docs/architecture.md](./docs/architecture.md) — How the multi-agent system works
- [docs/flow.md](./docs/flow.md) — End-to-end execution traces
- [docs/hooks-migration.md](./docs/hooks-migration.md) — Hooks reference
