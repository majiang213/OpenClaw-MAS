# OpenClaw MAS

A multi-agent development system that brings [Everything Claude Code](https://github.com/anthropics/everything-claude-code) workflows into [OpenClaw](https://docs.openclaw.ai). Use TDD, code review, build fixing, GAN loops, and 60+ other development workflows from any chat channel — Telegram, WhatsApp, Discord, or any channel OpenClaw supports.

---

## What's Included

- **37 specialist agents** — tdd-guide, rust-reviewer, code-reviewer, gan-planner, security-reviewer, and more
- **210 skills** — 142 ECC skills + 68 command skills covering the full development lifecycle
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

Clone the repo, then send this to your OpenClaw agent:

```
Read the README in the OpenClaw-MAS repo I just cloned and follow the installation instructions.
```

The agent will read this file, run the install script, verify the result, and report back when done.

### Option 2: Install manually

```bash
git clone https://github.com/majiang213/OpenClaw-MAS.git
cd OpenClaw-MAS
bash install-ecc.sh
```

---

## Quick Start

Once installed, use `/skill <name>` in any OpenClaw chat:

```
/skill tdd implement a login endpoint with JWT auth
/skill code_review
/skill build_fix
/skill rust_review
/skill security_scan
/skill gan_build build a real-time collaborative whiteboard
```

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
bash install-ecc.sh
```

The script will:
- Register 37 specialist agents into `openclaw.json`
- Install 210 skills into `~/.openclaw/skills/` (142 ECC skills + 68 command skills)
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

## Usage

Invoke any workflow with `/skill <name>` in your OpenClaw chat:

```
/skill tdd implement a login endpoint with JWT auth
/skill code_review
/skill code_review 42
/skill build_fix
/skill rust_review
/skill gan_build build a real-time collaborative whiteboard
/skill plan add payment integration
/skill security_scan
```

---

## Available Skills

### Development Workflow

| Skill | What it does |
|-------|-------------|
| `/skill tdd` | TDD: scaffold → RED → GREEN → REFACTOR → 80%+ coverage |
| `/skill plan` | Create implementation plan before writing code |
| `/skill code_review` | Review local changes or a PR (pass PR number as arg) |
| `/skill e2e` | Generate and run E2E tests with Playwright |
| `/skill refactor_clean` | Remove dead code, consolidate duplicates |
| `/skill build_fix` | Incrementally fix build/type errors |
| `/skill security_scan` | OWASP Top 10 security review |
| `/skill db_review` | PostgreSQL schema and query review |

### Multi-Agent Workflows

| Skill | What it does |
|-------|-------------|
| `/skill gan_build` | Autonomous build loop: plan → implement → evaluate → repeat until score ≥ 7.0 |
| `/skill gan_design` | Design quality loop focused on visual output |
| `/skill santa_loop` | Two reviewers in parallel, both must approve |
| `/skill orchestrate` | Custom multi-agent workflow |
| `/skill devfleet` | Parallel agent fleet for concurrent tasks |

### Language-Specific

| Language | Build | Review | Test |
|----------|-------|--------|------|
| Rust | `/skill rust_build` | `/skill rust_review` | `/skill rust_test` |
| Go | `/skill go_build` | `/skill go_review` | `/skill go_test` |
| C++ | `/skill cpp_build` | `/skill cpp_review` | `/skill cpp_test` |
| Kotlin | `/skill kotlin_build` | `/skill kotlin_review` | `/skill kotlin_test` |
| Java | `/skill java_build` | `/skill java_review` | — |
| Python | — | `/skill python_review` | — |
| Flutter | — | `/skill flutter_review` | — |
| PyTorch | `/skill pytorch_build` | — | — |

### Docs & Planning

| Skill | What it does |
|-------|-------------|
| `/skill update_docs` | Update project documentation |
| `/skill prp_prd` | Generate product requirements doc |
| `/skill prp_plan` | Generate implementation plan |
| `/skill prp_implement` | Implement from a PRP spec |

### Session & Learning

| Skill | What it does |
|-------|-------------|
| `/skill save_session` | Save current session state |
| `/skill resume_session` | Resume previous session |
| `/skill learn` | Extract reusable patterns from session |
| `/skill skill_create` | Generate new skill from git history |

---

## Further Reading

- [docs/architecture.md](./docs/architecture.md) — How the multi-agent system works
- [docs/flow.md](./docs/flow.md) — End-to-end execution traces
- [docs/hooks-migration.md](./docs/hooks-migration.md) — Hooks reference
