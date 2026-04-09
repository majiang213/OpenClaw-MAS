#!/bin/bash
# ══════════════════════════════════════════════════════════════
# OpenClaw MAS · 一键卸载脚本
# ══════════════════════════════════════════════════════════════
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OC_HOME="$HOME/.openclaw"
OC_CFG="$OC_HOME/openclaw.json"
MANIFEST="$OC_HOME/.ecc-mas-manifest.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

banner() {
  echo ""
  echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
  echo -e "${RED}║       🦞  OpenClaw MAS Uninstaller       ║${NC}"
  echo -e "${RED}║    Remove MAS entries, preserve yours    ║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

log()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }

# ── 确认 ─────────────────────────────────────────────────────
confirm() {
  echo -e "${YELLOW}即将卸载 OpenClaw MAS 安装的所有内容。${NC}"
  echo -e "${YELLOW}只删除 manifest 中记录的 MAS skills、rules、hooks 和 agent workspace。${NC}"
  echo -e "${YELLOW}您自己添加的 skills、rules、hooks 不会被删除。${NC}"
  echo ""

  if [ ! -f "$MANIFEST" ]; then
    warn "未找到 manifest 文件（$MANIFEST）"
    warn "将根据 agents/ 目录推断要删除的内容，但无法确定 skills/rules/hooks 范围。"
    echo ""
  fi

  read -r -p "确认卸载？[y/N] " ans
  case "$ans" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "已取消。"; exit 0 ;;
  esac
}

# ── Step 1: 按 manifest 删除 MAS 安装的条目 ──────────────────
remove_manifest_entries() {
  info "按 manifest 删除 MAS 安装的 skills、rules、hooks..."

  if [ ! -f "$MANIFEST" ]; then
    warn "未找到 manifest（$MANIFEST），跳过 skills/rules/hooks 清理"
    warn "如需手动清理，请删除 ~/.openclaw/skills/ 中的 MAS skill 目录"
    return
  fi

  python3 << PYEOF
import json, pathlib, shutil

oc_home = pathlib.Path.home() / '.openclaw'
manifest_path = oc_home / '.ecc-mas-manifest.json'

manifest = json.loads(manifest_path.read_text())
entries = manifest.get('entries', {})

# 删除 skills
skills_removed = 0
for name in entries.get('skills', []):
    dst = oc_home / 'skills' / name
    if dst.exists():
        shutil.rmtree(dst)
        skills_removed += 1
print(f'  skills 已删除：{skills_removed} 个')

# 统计保留的用户 skills
skills_dir = oc_home / 'skills'
if skills_dir.exists():
    remaining = [d.name for d in skills_dir.iterdir() if d.is_dir()]
    if remaining:
        print(f'  保留用户 skills：{len(remaining)} 个（{", ".join(sorted(remaining)[:5])}{"..." if len(remaining) > 5 else ""}）')

# 删除 rules
rules_removed = 0
for name in entries.get('rules', []):
    dst = oc_home / 'rules' / name
    if dst.exists():
        shutil.rmtree(dst)
        rules_removed += 1
print(f'  rules 已删除：{rules_removed} 个')

# 统计保留的用户 rules
rules_dir = oc_home / 'rules'
if rules_dir.exists():
    remaining_rules = [d.name for d in rules_dir.iterdir() if d.is_dir()]
    if remaining_rules:
        print(f'  保留用户 rules：{len(remaining_rules)} 个（{", ".join(sorted(remaining_rules))}）')

# 删除 hooks
hooks_removed = 0
for name in entries.get('hooks', []):
    dst = oc_home / 'hooks' / name
    if dst.exists():
        shutil.rmtree(dst)
        hooks_removed += 1
print(f'  hooks 已删除：{hooks_removed} 个')

# 删除 manifest 本身
manifest_path.unlink()
print(f'  manifest 已删除：{manifest_path}')
PYEOF

  log "MAS 条目清理完成"
}

# ── Step 2: 移除 Agent Workspace ─────────────────────────────
remove_workspaces() {
  info "移除 Agent Workspace..."

  # 优先从 manifest 读取 agent 列表
  if [ -f "$MANIFEST" ]; then
    AGENT_NAMES=$(python3 -c "
import json, pathlib
m = json.loads((pathlib.Path('$MANIFEST')).read_text())
print(' '.join(m.get('entries', {}).get('agents', [])))
" 2>/dev/null || echo "")
  else
    # fallback：从 agents/ 目录推断
    AGENT_NAMES=""
    if [ -d "$REPO_DIR/agents" ]; then
      AGENT_NAMES=$(ls -1 "$REPO_DIR/agents/" 2>/dev/null | tr '\n' ' ')
    fi
  fi

  COUNT=0
  for agent_name in $AGENT_NAMES; do
    ws="$OC_HOME/workspace-$agent_name"
    if [ -d "$ws" ]; then
      rm -rf "$ws"
      COUNT=$((COUNT + 1))
    fi
  done

  # 从 openclaw.json 中移除 MAS agents（保留用户自定义 agent）
  if [ -n "$AGENT_NAMES" ] && [ -f "$OC_CFG" ]; then
    python3 << PYEOF
import json, pathlib

cfg_path = pathlib.Path('$OC_CFG')
cfg = json.loads(cfg_path.read_text())

mas_agents = set('$AGENT_NAMES'.split())
agents_cfg = cfg.get('agents', {})
existing = agents_cfg.get('list', [])
kept = [a for a in existing if a.get('id') not in mas_agents]
removed_count = len(existing) - len(kept)
agents_cfg['list'] = kept

cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
print(f'  从 agents.list 移除 {removed_count} 个 MAS agent（保留 {len(kept)} 个）')
PYEOF
  fi

  log "Agent Workspace 已移除：$COUNT 个目录"
}

# ── Step 3: 还原 openclaw.json 配置项 ────────────────────────
revert_config() {
  info "还原 openclaw.json 配置..."

  if [ ! -f "$OC_CFG" ]; then
    warn "未找到 openclaw.json，跳过配置还原"
    return
  fi

  python3 << 'PYEOF'
import json, pathlib

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'
cfg = json.loads(cfg_path.read_text())

changed = False

# 还原 commands（只移除 MAS 设置的值，不动用户其他 commands 配置）
commands = cfg.get('commands', {})
for key in ['text', 'nativeSkills', 'native']:
    if key in commands:
        del commands[key]
        changed = True
        print(f'  - 移除 commands.{key}')
if not commands:
    cfg.pop('commands', None)

# 还原 agents.defaults.subagents
agents_cfg = cfg.get('agents', {})
defaults = agents_cfg.get('defaults', {})
subagents = defaults.get('subagents', {})
for key in ['maxSpawnDepth', 'maxChildrenPerAgent']:
    if key in subagents:
        del subagents[key]
        changed = True
        print(f'  - 移除 agents.defaults.subagents.{key}')

# 还原 agents.list[main].subagents.allowAgents
agents_list = agents_cfg.get('list', [])
main_agent = next((a for a in agents_list if a.get('id') == 'main'), None)
if main_agent and main_agent.get('subagents', {}).get('allowAgents') == ['*']:
    del main_agent['subagents']['allowAgents']
    if not main_agent.get('subagents'):
        main_agent.pop('subagents', None)
    changed = True
    print('  - 移除 agents.list[main].subagents.allowAgents')

# 还原 hooks.internal（只禁用 MAS hooks，不删除用户 hooks 配置）
hooks_cfg = cfg.get('hooks', {})
internal = hooks_cfg.get('internal', {})
entries = internal.get('entries', {})
for hook_name in ['session-bootstrap', 'pre-compact']:
    if hook_name in entries:
        del entries[hook_name]
        changed = True
        print(f'  - 移除 hooks.internal.entries.{hook_name}')
if not entries:
    internal.pop('entries', None)
if not internal:
    hooks_cfg.pop('internal', None)

if changed:
    cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
    print('  openclaw.json 已还原')
else:
    print('  openclaw.json 无需修改')
PYEOF

  log "配置还原完成"
}

# ── Step 4: 移除 Plugin ───────────────────────────────────────
remove_plugin() {
  info "移除 ecc-hooks plugin..."

  PLUGIN_DST="$OC_HOME/plugins/ecc-hooks"
  if [ -d "$PLUGIN_DST" ]; then
    rm -rf "$PLUGIN_DST"
    log "ecc-hooks plugin 已移除：$PLUGIN_DST"
  else
    warn "ecc-hooks plugin 目录不存在，跳过"
  fi
}

# ── Step 5: 重启 Gateway ─────────────────────────────────────
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
remove_manifest_entries
remove_workspaces
revert_config
remove_plugin
restart_gateway

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅  OpenClaw MAS 已完全卸载。                   ║${NC}"
echo -e "${GREEN}║  您自定义的 skills/rules/hooks 已完整保留。      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
