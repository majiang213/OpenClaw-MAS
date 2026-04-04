#!/usr/bin/env python3
"""
把 everything-claude-code commands/ 批量转换为 OpenClaw user-invocable skills
输出到 openclaw/skills/（安装时会复制到 ~/.openclaw/skills/）
"""
import os
import re
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
REPO_DIR = SCRIPT_DIR.parent.parent
CMDS_SRC = REPO_DIR / "commands"
SKILLS_DST = SCRIPT_DIR.parent / "skills"

# ── 类型 A：command → 单个专家 agent ──────────────────────────
AGENT_MAP = {
    "tdd":            "tdd-guide",
    "e2e":            "e2e-runner",
    "plan":           "planner",
    "code-review":    "code-reviewer",
    "refactor-clean": "refactor-cleaner",
    "update-docs":    "doc-updater",
    "update-codemaps":"doc-updater",
    "cpp-build":      "cpp-build-resolver",
    "cpp-review":     "cpp-reviewer",
    "cpp-test":       "cpp-build-resolver",
    "go-build":       "go-build-resolver",
    "go-review":      "go-reviewer",
    "go-test":        "go-build-resolver",
    "kotlin-build":   "kotlin-build-resolver",
    "kotlin-review":  "kotlin-reviewer",
    "kotlin-test":    "kotlin-build-resolver",
    "rust-build":     "rust-build-resolver",
    "rust-review":    "rust-reviewer",
    "rust-test":      "rust-build-resolver",
    "python-review":  "python-reviewer",
    "java-build":     "java-build-resolver",
    "java-review":    "java-reviewer",
    "gradle-build":   "java-build-resolver",
    "flutter-review": "flutter-reviewer",
    "pytorch-build":  "pytorch-build-resolver",
    "security-scan":  "security-reviewer",
    "db-review":      "database-reviewer",
    "harness-audit":  "harness-optimizer",
    "context-budget": "harness-optimizer",
    "loop-start":     "loop-operator",
    "santa-loop":     "code-reviewer",
}

# ── 类型 A：command → 多个专家 agent 串行 ─────────────────────
GAN_MAP = {
    "gan-build":  ["gan-planner", "gan-generator", "gan-evaluator"],
    "gan-design": ["gan-generator", "gan-evaluator"],
}

# 所有 command 全部自动生成，无手写样本
SKIP_LIST = set()


def extract_frontmatter_and_body(content: str):
    """提取 description frontmatter 和 body 内容"""
    description = ""
    body = content

    # 检查是否有 frontmatter（以 --- 开头）
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            front = parts[1]
            body = parts[2].lstrip("\n")
            # 提取 description
            for line in front.splitlines():
                if line.startswith("description:"):
                    description = line[len("description:"):].strip()
                    description = description.strip('"\'')
                    break

    return description, body


def make_spawn_section(cmd_name: str) -> str:
    """生成 OpenClaw 执行说明（类型 A 追加，类型 B 返回空字符串）"""

    if cmd_name in AGENT_MAP:
        agent_id = AGENT_MAP[cmd_name]
        session_key = agent_id
        return f"""

---

First, reply to the user briefly to confirm you are delegating to `{agent_id}`.

Then call sessions_spawn:
```json
{{
  "agentId": "{agent_id}",
  "sessionKey": "{session_key}",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
"""

    if cmd_name in GAN_MAP:
        agents = GAN_MAP[cmd_name]
        agents_display = " → ".join(agents)
        steps = []
        for i, a in enumerate(agents):
            steps.append(f"""{i+1}. Reply to the user briefly, then call sessions_spawn:
```json
{{
  "agentId": "{a}",
  "sessionKey": "{a}",
  "task": "<task description with full context from previous step>",
  "runTimeoutSeconds": 300
}}
```
Wait for this agent to complete before proceeding.""")
        steps_str = "\n\n".join(steps)
        return f"""

---

Execute specialist agents in sequence: {agents_display}

{steps_str}

Do not spawn the next agent until the current one completes. Do not spawn agents in parallel.
After all agents complete, return the final result to the user.
"""

    return ""  # 类型 B，不追加


def make_type_a_body(cmd_name: str, agent_id: str, description: str) -> str:
    """Generate lean Type A skill body following clawhub paradigm."""
    # Build context hints based on command type
    context_hints = {
        "tdd": "- What to build (feature, fix, or refactor)\n- Relevant files, modules, or components involved\n- Tech stack and test framework in use\n- Any existing tests or coverage requirements to meet",
        "e2e": "- The user flows or features to test\n- Base URL or dev server details if known\n- Existing test files or framework configuration\n- Whether to generate new tests, run existing ones, or both",
        "plan": "- The full feature or change request\n- Relevant codebase context (tech stack, affected files/modules if known)\n- Any constraints, deadlines, or preferences the user mentioned\n- Whether this is a new feature, refactor, bug fix, or architectural change",
        "code-review": "- Whether this is a local review (uncommitted changes) or a PR review\n- PR number or URL if reviewing a GitHub PR\n- Specific files, modules, or areas of concern if any\n- Tech stack and any project-specific conventions",
        "refactor-clean": "- Scope: specific files/directories or full codebase\n- Tech stack (Node.js, TypeScript, Python, Go, Rust, etc.)\n- Whether to auto-delete or report only\n- Any known areas of dead code or unused exports to prioritize",
        "update-docs": "- What changed (feature, API, config, architecture)\n- Which docs need updating (README, CHANGELOG, API reference, guides)\n- Any specific sections or files to focus on",
        "update-codemaps": "- The codebase root or specific modules to remap\n- Whether this follows a significant refactor, new feature, or file restructure\n- Any existing CODEMAPS to update vs. create from scratch",
        "security-scan": "- Files or modules to audit (or 'all changed files' for a pre-commit scan)\n- Tech stack and any known sensitive areas (auth, payments, user data)\n- Whether this is a pre-commit review or a PR review",
        "db-review": "- SQL queries, schema changes, or migrations to review\n- Database system (PostgreSQL, MySQL, SQLite, etc.)\n- Whether this is a new schema, migration, or query optimization request",
        "harness-audit": "- Scope: repo (full), hooks, skills, commands, or agents (default: repo)\n- Output format preference: text (default) or json\n- Any known issues or areas of concern to prioritize",
        "context-budget": "- Whether to run in verbose mode\n- Context window size if different from default (200K)\n- Specific files, rules, or agents suspected of causing context bloat",
        "loop-start": "- Loop pattern: sequential, continuous-pr, rfc-dag, or infinite\n- Mode: safe (default) or fast\n- The task or goal the loop should execute\n- Explicit stop condition (required)",
        "santa-loop": "- The files, glob pattern, or description of what to review\n- Falls back to uncommitted changes if no scope given\n- Any domain-specific rubric criteria to add",
    }

    build_resolver_hints = "- The full build error output\n- Language/framework version\n- Any recent changes that may have caused the breakage"
    reviewer_hints = "- Files or modules to review (or 'all changed files' for a pre-commit review)\n- Language version and key dependencies\n- Whether this is a pre-commit review or a PR review\n- Any specific concerns"
    tdd_hints = "- What to implement (function, class, module)\n- Language version and test framework in use\n- Any existing test fixtures or helpers to reuse\n- Coverage target (default: 80%)"

    if cmd_name in context_hints:
        hints = context_hints[cmd_name]
    elif "build" in cmd_name and "resolver" in agent_id:
        hints = build_resolver_hints
    elif "review" in cmd_name:
        hints = reviewer_hints
    elif "test" in cmd_name:
        hints = tdd_hints
    else:
        hints = "- The user's full request\n- Relevant codebase context\n- Any constraints or preferences"

    return f"""Delegate to the `{agent_id}` agent.

Include in the task payload:
{hints}

---

First, reply to the user briefly to confirm you are delegating to `{agent_id}`.

Then call sessions_spawn:
```json
{{
  "agentId": "{agent_id}",
  "sessionKey": "{agent_id}",
  "task": "<user's full request and all relevant context — the agent cannot see this conversation>",
  "runTimeoutSeconds": 300
}}
```

After sessions_spawn returns, relay the result to the user. Do not output anything after the spawn call until the result arrives.
"""


def generate_skill(cmd_file: Path):
    cmd_name = cmd_file.stem  # e.g. "code-review"
    skill_name = "cmd_" + cmd_name.replace("-", "_")  # e.g. "cmd_code_review"
    skill_dir = SKILLS_DST / skill_name

    # 跳过手写样本
    if cmd_name in SKIP_LIST:
        return "skip", skill_name

    # 已存在则跳过
    if skill_dir.exists():
        return "exists", skill_name

    skill_dir.mkdir(parents=True, exist_ok=True)

    content = cmd_file.read_text(encoding="utf-8")
    description, _ = extract_frontmatter_and_body(content)

    if not description:
        description = f"{cmd_name} workflow"

    # 转义 description 里的双引号
    description = description.replace('"', "'")

    spawn_section = make_spawn_section(cmd_name)
    skill_type = "A" if spawn_section else "B"

    if skill_type == "A" and cmd_name in AGENT_MAP:
        # Type A: lean operational body (clawhub paradigm)
        agent_id = AGENT_MAP[cmd_name]
        body = make_type_a_body(cmd_name, agent_id, description)
        skill_content = f"""---
name: {skill_name}
description: "{description}"
user-invocable: true
origin: openclaw-mas
---

{body}"""
    elif skill_type == "A" and cmd_name in GAN_MAP:
        # GAN multi-agent: keep spawn section, use lean intro
        agents = GAN_MAP[cmd_name]
        agents_display = " → ".join(agents)
        skill_content = f"""---
name: {skill_name}
description: "{description}"
user-invocable: true
origin: openclaw-mas
---

Run specialist agents in sequence: {agents_display}.

Include in the task payload:
- The user's full request and build/design brief
- Any flags or configuration options (max iterations, pass threshold, etc.)
- Relevant codebase context

{spawn_section}"""
    else:
        # Type B: include original body
        _, body = extract_frontmatter_and_body(content)
        skill_content = f"""---
name: {skill_name}
description: "{description}"
user-invocable: true
origin: openclaw-mas
---

{body}"""

    (skill_dir / "SKILL.md").write_text(skill_content, encoding="utf-8")
    return skill_type, skill_name


def main():
    print(f"生成 Command Skills")
    print(f"来源：{CMDS_SRC}")
    print(f"目标：{SKILLS_DST}")
    print()

    SKILLS_DST.mkdir(parents=True, exist_ok=True)

    count = {"A": 0, "B": 0, "skip": 0, "exists": 0}

    for cmd_file in sorted(CMDS_SRC.glob("*.md")):
        result, skill_name = generate_skill(cmd_file)
        count[result] = count.get(result, 0) + 1

        if result == "A":
            agent = AGENT_MAP.get(cmd_file.stem) or " → ".join(GAN_MAP.get(cmd_file.stem, []))
            print(f"  ✅ {skill_name} → {agent}")
        elif result == "B":
            print(f"  ✅ {skill_name} [直接执行]")
        elif result == "skip":
            print(f"  ⏭  {skill_name} [手写样本，跳过]")
        elif result == "exists":
            print(f"  ⚠️  {skill_name} [已存在，跳过]")

    print()
    print("完成！")
    print(f"  类型 A（spawn 专家 agent）：{count.get('A', 0)} 个")
    print(f"  类型 B（直接执行）：{count.get('B', 0)} 个")
    print(f"  手写样本（跳过）：{count.get('skip', 0)} 个")
    print(f"  已存在（跳过）：{count.get('exists', 0)} 个")
    total = sum(count.values())
    print(f"  总计处理：{total} 个 command 文件")


if __name__ == "__main__":
    main()
