#!/bin/bash
# ══════════════════════════════════════════════════════════════
# OpenClaw MAS · 一键卸载脚本
# ══════════════════════════════════════════════════════════════
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OC_HOME="$HOME/.openclaw"
OC_CFG="$OC_HOME/openclaw.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

banner() {
  echo ""
  echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
  echo -e "${RED}║       🦞  OpenClaw MAS Uninstaller       ║${NC}"
  echo -e "${RED}║    Remove agents, skills, hooks, rules   ║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

log()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }

# ── 确认 ─────────────────────────────────────────────────────
confirm() {
  echo -e "${YELLOW}即将卸载 OpenClaw MAS 安装的所有内容（agents、skills、rules、hooks、plugin）。${NC}"
  echo -e "${YELLOW}此操作不可撤销（备份目录不会被删除）。${NC}"
  echo ""
  read -r -p "确认卸载？[y/N] " ans
  case "$ans" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "已取消。"; exit 0 ;;
  esac
}

# ── Step 1: 移除 Agent Workspace ─────────────────────────────
remove_workspaces() {
  info "移除 Agent Workspace..."

  AGENTS_DIR="$REPO_DIR/agents"
  COUNT=0

  if [ ! -d "$AGENTS_DIR" ]; then
    warn "未找到 agents 目录：$AGENTS_DIR，跳过 workspace 清理"
  else
    for agent_dir in "$AGENTS_DIR"/*/; do
      [ -d "$agent_dir" ] || continue
      agent_name=$(basename "$agent_dir")
      ws="$OC_HOME/workspace-$agent_name"
      if [ -d "$ws" ]; then
        rm -rf "$ws"
        COUNT=$((COUNT + 1))
      fi
    done
  fi

  # 从 openclaw.json 移除 OpenClaw MAS agent 条目
  if [ -f "$OC_CFG" ]; then
    python3 << PYEOF
import json, pathlib

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'
cfg = json.loads(cfg_path.read_text())

agents_dir = pathlib.Path('$AGENTS_DIR')
mas_ids = set()
if agents_dir.is_dir():
    mas_ids = {d.name for d in agents_dir.iterdir() if d.is_dir()}

agents_cfg = cfg.get('agents', {})
existing = agents_cfg.get('list', [])
kept = [a for a in existing if a['id'] not in mas_ids]
removed = len(existing) - len(kept)
agents_cfg['list'] = kept
cfg['agents'] = agents_cfg

cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
print(f'  已从 agents.list 移除 {removed} 个 OpenClaw MAS agent（保留 {len(kept)} 个）')
PYEOF
  fi

  log "Agent Workspace 已移除：$COUNT 个目录"
}

# ── Step 2: 移除 Skills ───────────────────────────────────────
remove_skills() {
  info "移除 Skills..."

  SKILLS_DST="$OC_HOME/skills"
  if [ -d "$SKILLS_DST" ]; then
    rm -rf "$SKILLS_DST"
    log "Skills 目录已删除：$SKILLS_DST"
  else
    warn "Skills 目录不存在，跳过"
  fi

  # 同时清理 repo 内生成的 command-skill
  CMD_SKILLS_SRC="$REPO_DIR/skills"
  if [ -d "$CMD_SKILLS_SRC" ]; then
    rm -rf "$CMD_SKILLS_SRC"
    log "Command-skill 生成目录已清理：$CMD_SKILLS_SRC"
  fi
}

# ── Step 3: 移除 Rules ────────────────────────────────────────
remove_rules() {
  info "移除 Rules..."

  RULES_DST="$OC_HOME/rules"
  if [ -d "$RULES_DST" ]; then
    rm -rf "$RULES_DST"
    log "Rules 目录已删除：$RULES_DST"
  else
    warn "Rules 目录不存在，跳过"
  fi
}

# ── Step 4: 移除 Hooks ────────────────────────────────────────
remove_hooks() {
  info "移除 Hooks..."

  # Internal hooks
  INT_HOOKS_SRC="$REPO_DIR/hooks"
  INT_HOOKS_DST="$OC_HOME/hooks"

  if [ -d "$INT_HOOKS_SRC" ] && [ -d "$INT_HOOKS_DST" ]; then
    for hook_dir in "$INT_HOOKS_SRC"/*/; do
      [ -d "$hook_dir" ] || continue
      hook_name=$(basename "$hook_dir")
      if [ -d "$INT_HOOKS_DST/$hook_name" ]; then
        rm -rf "$INT_HOOKS_DST/$hook_name"
      fi
    done
    log "Internal hooks 已移除"
  fi

  # Plugin
  PLUGIN_DST="$OC_HOME/plugins/ecc-hooks"
  if [ -d "$PLUGIN_DST" ]; then
    rm -rf "$PLUGIN_DST"
    log "ecc-hooks plugin 已移除：$PLUGIN_DST"
  else
    warn "ecc-hooks plugin 目录不存在，跳过"
  fi
}

# ── Step 5: 还原配置 ─────────────────────────────────────────
restore_config() {
  info "还原 OpenClaw 配置..."

  if [ ! -f "$OC_CFG" ]; then
    warn "未找到 openclaw.json，跳过配置还原"
    return
  fi

  python3 << 'PYEOF'
import json, pathlib

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'
cfg = json.loads(cfg_path.read_text())

# ── 1. 移除 commands 配置 ─────────────────────────────────────
commands = cfg.get('commands', {})
for key in ('text', 'nativeSkills', 'native'):
    if key in commands:
        del commands[key]
        print(f'  - 移除 commands.{key}')
if not commands:
    cfg.pop('commands', None)
else:
    cfg['commands'] = commands

# ── 2. 还原 agents.defaults.subagents ────────────────────────
agents_cfg = cfg.get('agents', {})
defaults = agents_cfg.get('defaults', {})
subagents = defaults.get('subagents', {})
for key in ('maxSpawnDepth', 'maxChildrenPerAgent'):
    if key in subagents:
        del subagents[key]
        print(f'  - 移除 agents.defaults.subagents.{key}')
if not subagents:
    defaults.pop('subagents', None)
if not defaults:
    agents_cfg.pop('defaults', None)
if agents_cfg:
    cfg['agents'] = agents_cfg

# ── 3. 移除 hooks 配置 ────────────────────────────────────────
hooks_cfg = cfg.get('hooks', {})
internal = hooks_cfg.get('internal', {})
for hook_name in ('session-bootstrap', 'pre-compact'):
    entries = internal.get('entries', {})
    if hook_name in entries:
        del entries[hook_name]
        print(f'  - 移除 hooks.internal.entries.{hook_name}')
if not internal.get('entries'):
    hooks_cfg.pop('internal', None)
if not hooks_cfg:
    cfg.pop('hooks', None)
else:
    cfg['hooks'] = hooks_cfg

# ── 4. 移除 plugins 配置 ─────────────────────────────────────
plugins = cfg.get('plugins', {})
load = plugins.get('load', {})
paths = load.get('paths', [])
plugins_dir = str(pathlib.Path.home() / '.openclaw' / 'plugins')
if plugins_dir in paths:
    paths.remove(plugins_dir)
    print(f'  - 从 plugins.load.paths 移除 {plugins_dir}')
if not paths:
    load.pop('paths', None)
if not load:
    plugins.pop('load', None)
if not plugins:
    cfg.pop('plugins', None)
else:
    cfg['plugins'] = plugins

cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
print('配置已还原')
PYEOF

  log "配置还原完成"
}

# ── Step 6: 重启 Gateway ─────────────────────────────────────
restart_gateway() {
  info "重启 OpenClaw Gateway..."

  if openclaw gateway restart 2>/dev/null; then
    log "Gateway 重启成功"
    sleep 2
  else
    warn "Gateway 重启失败，请手动重启：openclaw gateway restart"
  fi
}

# ── Main ─────────────────────────────────────────────────────
banner
confirm
remove_workspaces
remove_skills
remove_rules
remove_hooks
restore_config
restart_gateway

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅  OpenClaw MAS 已完全卸载。                   ║${NC}"
echo -e "${GREEN}║  备份保留在 ~/.openclaw/backups/                 ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
