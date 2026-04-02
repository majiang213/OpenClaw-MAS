#!/bin/bash
# ══════════════════════════════════════════════════════════════
# 从 ECC agents/*.md 生成 OpenClaw 格式的 agent 文件
# ══════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTS_SRC="$REPO_DIR/../agents"
AGENTS_DST="$REPO_DIR/agents"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }

# 读取 YAML frontmatter 字段
get_field() {
  local file="$1"
  local field="$2"
  grep -m1 "^${field}:" "$file" | cut -d: -f2- | xargs
}

# 生成 SOUL.md
generate_soul() {
  local name="$1"
  local desc="$2"
  local content="$3"
  
  cat > "$AGENTS_DST/$name/SOUL.md" << EOF
# SOUL.md - Who You Are

_${desc}._

## Core Truths

**Be genuinely helpful, not performatively helpful.** Skip the "Great question!" and filler words — just help.

**Be resourceful before asking.** Try to figure it out. Read files. Check context. _Then_ ask if stuck.

**Earn trust through competence.** Be careful with external actions. Be bold with internal ones.

## Your Role

$(echo "$content" | grep -A 100 "## Your Role\|## Role\|## 职责" | grep -v "^##" | head -10)

## Work Process

$(echo "$content" | grep -A 100 "##.*[Pp]rocess\|##.*[Ww]orkflow\|##.*流程" | grep -v "^##" | head -15)

## Boundaries

- Private things stay private. Period.
- When in doubt, ask before acting externally.
- Never send half-baked replies.

## Continuity

Each session, you wake up fresh. These files _are_ your memory. Read them. Update them.

---

🥬 _我是 $name，很高兴认识你。_
EOF
}

# 生成 IDENTITY.md
generate_identity() {
  local name="$1"
  local desc="$2"
  local emoji="$3"
  
  cat > "$AGENTS_DST/$name/IDENTITY.md" << EOF
# IDENTITY.md - Who Am I?

- **Name:** $name
- **Role:** $desc
- **Emoji:** $emoji

## Purpose

专注于完成与 $name 相关的任务，提供专业、高质量的工作成果。

## Capabilities

- ✅ 理解自然语言请求
- ✅ 使用可用工具完成任务
- ✅ 遵循最佳实践
- ✅ 主动沟通和反馈

---

$emoji _专业、高效、可靠。_
EOF
}

# 生成 AGENTS.md
generate_agents() {
  local name="$1"
  local desc="$2"
  local content="$3"
  
  cat > "$AGENTS_DST/$name/AGENTS.md" << EOF
# AGENTS.md - $name

## Role

$desc

## Responsibilities

$(echo "$content" | grep -A 50 "##.*[Rr]esponsibilities\|##.*[Rr]ole\|##.*职责" | grep -v "^##" | head -10)

## Workflow

\`\`\`
用户请求 → 分析需求 → 执行任务 → 返回结果
\`\`\`

## Notes

- 通过 /dispatch 命令或直接调用触发
- 专注于 $name 相关任务
- 主动沟通进展和阻塞

EOF
}

# 生成 TOOLS.md
generate_tools() {
  local name="$1"
  local tools="$2"
  
  cat > "$AGENTS_DST/$name/TOOLS.md" << EOF
# TOOLS.md - Available Tools

## Core Tools

| Tool | Description |
|------|-------------|
| Read | 读取文件内容 |
| Write | 创建或覆盖文件 |
| Edit | 精确编辑文件 |
| Glob | 文件名匹配搜索 |
| Grep | 内容搜索 |
| Bash | Shell 命令执行 |

## Agent Tools

$(echo "$tools" | tr ',' '\n' | while read tool; do
  tool=$(echo "$tool" | xargs | tr -d '"[]')
  if [ -n "$tool" ]; then
    echo "- \`$tool\`"
  fi
done)

## Usage

通过 /dispatch 命令或直接调用触发。
EOF
}

# 生成 USER.md
generate_user() {
  local name="$1"
  
  cat > "$AGENTS_DST/$name/USER.md" << EOF
# USER.md - About Your Human

- **Name:** (待补充)
- **What to call them:** 用户
- **Timezone:** UTC+8

## Context

用户通过 /dispatch 命令或直接调用来请求 $name 相关的帮助。

## Common Requests

- 具体请求取决于 agent 职责
- 使用自然语言描述需求
- 提供必要的上下文信息

---

理解需求，高效完成。
EOF
}

# 生成 HEARTBEAT.md
generate_heartbeat() {
  local name="$1"
  
  cat > "$AGENTS_DST/$name/HEARTBEAT.md" << 'EOF'
# HEARTBEAT.md

# Keep this file empty (or with only comments) to skip heartbeat API calls.

# Add tasks below when you want the agent to check something periodically.
EOF
}

# 生成 BOOTSTRAP.md
generate_bootstrap() {
  local name="$1"
  
  echo "[MISSING] Expected at: ~/.openclaw/workspace-$name/BOOTSTRAP.md" > "$AGENTS_DST/$name/BOOTSTRAP.md"
}

# 主函数
main() {
  info "从 ECC agents/*.md 生成 OpenClaw 格式..."
  
  COUNT=0
  
  for agent_file in "$AGENTS_SRC"/*.md; do
    if [ -f "$agent_file" ]; then
      name=$(get_field "$agent_file" "name")
      desc=$(get_field "$agent_file" "description")
      tools=$(grep -m1 "^tools:" "$agent_file" | cut -d: -f2-)
      content=$(cat "$agent_file")
      
      # 跳过没有 name 的文件
      if [ -z "$name" ]; then
        warn "跳过没有 name 的文件：$agent_file"
        continue
      fi
      
      # 创建目录
      mkdir -p "$AGENTS_DST/$name"
      
      # 选择 emoji（根据 agent 类型）
      case "$name" in
        *planner*|*architect*) emoji="📋" ;;
        *review*|*audit*) emoji="🔍" ;;
        *build*|*generator*) emoji="🏗️" ;;
        *test*|*e2e*) emoji="🧪" ;;
        *security*) emoji="🔒" ;;
        *docs*) emoji="📝" ;;
        *gan*) emoji="🎯" ;;
        *dispatch*) emoji="🎯" ;;
        *) emoji="🤖" ;;
      esac
      
      # 生成所有文件
      generate_soul "$name" "$desc" "$content"
      generate_identity "$name" "$desc" "$emoji"
      generate_agents "$name" "$desc" "$content"
      generate_tools "$name" "$tools"
      generate_user "$name"
      generate_heartbeat "$name"
      generate_bootstrap "$name"
      
      log "$name ($emoji)"
      COUNT=$((COUNT + 1))
    fi
  done
  
  echo ""
  log "已生成 $COUNT 个 agent"
}

main "$@"
