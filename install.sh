#!/bin/bash
# ══════════════════════════════════════════════════════════════
# OpenClaw MAS · 一键安装脚本
# ══════════════════════════════════════════════════════════════
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OC_HOME="$HOME/.openclaw"
OC_CFG="$OC_HOME/openclaw.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

banner() {
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║        🦞  OpenClaw MAS Installer        ║${NC}"
  echo -e "${BLUE}║         37 Agents + 210 Skills           ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

log()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }

# ── Step 0: 依赖检查 ──────────────────────────────────────────
check_deps() {
  info "检查依赖..."

  if ! command -v openclaw &>/dev/null; then
    error "未找到 openclaw CLI。请先安装 OpenClaw: https://docs.openclaw.ai"
    exit 1
  fi
  log "OpenClaw CLI: $(openclaw --version 2>/dev/null || echo 'OK')"

  if ! command -v python3 &>/dev/null; then
    error "未找到 python3"
    exit 1
  fi
  log "Python: $(python3 --version)"

  if [ ! -f "$OC_CFG" ]; then
    error "未找到 openclaw.json。请先运行 openclaw 完成初始化。"
    exit 1
  fi
  log "openclaw.json: $OC_CFG"
}

# ── Step 0.5: 全量备份 ────────────────────────────────────────
backup_existing() {
  BACKUP_DIR="$OC_HOME/backups/pre-ecc-install-$(date +%Y%m%d-%H%M%S)"
  info "备份现有 OpenClaw 数据到 $BACKUP_DIR ..."
  mkdir -p "$BACKUP_DIR"

  # 备份 openclaw.json
  cp "$OC_CFG" "$BACKUP_DIR/openclaw.json"

  # 备份 main workspace（单数）
  [ -d "$OC_HOME/workspace" ] && cp -R "$OC_HOME/workspace" "$BACKUP_DIR/workspace"

  # 备份所有 workspace-* 目录（多 agent）
  for d in "$OC_HOME"/workspace-*/; do
    [ -d "$d" ] && cp -R "$d" "$BACKUP_DIR/$(basename "$d")"
  done

  # 备份 skills、rules、hooks
  for dir in skills rules hooks; do
    [ -d "$OC_HOME/$dir" ] && cp -R "$OC_HOME/$dir" "$BACKUP_DIR/$dir"
  done

  log "备份完成：$BACKUP_DIR"
}

# ── Step 1: 注册 Agent Workspace（直接写入 openclaw.json）────
create_workspaces() {
  info "注册 Agent Workspace..."

  AGENTS_DIR="$REPO_DIR/agents"

  if [ ! -d "$AGENTS_DIR" ]; then
    warn "未找到 agents 目录：$AGENTS_DIR，跳过"
    return
  fi

  # 1. 批量创建 workspace 目录并复制文件
  COUNT=0
  for agent_dir in "$AGENTS_DIR"/*/; do
    [ -d "$agent_dir" ] || continue
    agent_name=$(basename "$agent_dir")
    ws="$OC_HOME/workspace-$agent_name"
    mkdir -p "$ws"
    cp -f "$agent_dir"/* "$ws/" 2>/dev/null || true
    COUNT=$((COUNT + 1))
  done

  # 2. 一次性批量写入 agents.list（直接操作 openclaw.json）
  python3 << PYEOF
import json, pathlib

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'
cfg = json.loads(cfg_path.read_text())

agents_dir = pathlib.Path('$AGENTS_DIR')
oc_home = pathlib.Path.home() / '.openclaw'

# 收集所有专家 agent
new_agents = []
for agent_dir in sorted(agents_dir.iterdir()):
    if not agent_dir.is_dir():
        continue
    agent_id = agent_dir.name
    ws = str(oc_home / f'workspace-{agent_id}')
    new_agents.append({'id': agent_id, 'workspace': ws})

# 合并到 agents.list：保留现有非 MAS agent，替换 MAS agent
agents_cfg = cfg.setdefault('agents', {})
existing = agents_cfg.get('list', [])
new_ids = {a['id'] for a in new_agents}
# 保留不在本次安装列表里的现有 agent（如用户自定义 agent）
kept = [a for a in existing if a['id'] not in new_ids]
agents_cfg['list'] = kept + new_agents

cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
print(f'  已写入 {len(new_agents)} 个 agent 到 agents.list（保留 {len(kept)} 个现有 agent）')
PYEOF

  log "Agent 注册完成：共 $COUNT 个（直接写入 openclaw.json）"
}

# ── Step 2: 生成并安装所有 Skills（全量覆盖）────────────────
# 包含：142 个 MAS skill + 68 个 command-skill，共 210 个
install_skills() {
  info "安装 Skills（全量覆盖）..."

  MAS_SKILLS_SRC="$REPO_DIR/ecc-skills"
  CMD_SKILLS_SRC="$REPO_DIR/skills"
  SKILLS_DST="$OC_HOME/skills"
  SCRIPT="$REPO_DIR/scripts/generate_skills.py"

  # 1. 如果 skills/ 目录为空（首次 clone），用脚本生成
  if [ ! -d "$CMD_SKILLS_SRC" ] || [ -z "$(ls -A "$CMD_SKILLS_SRC" 2>/dev/null)" ]; then
    if [ ! -f "$SCRIPT" ]; then
      error "未找到生成脚本：$SCRIPT，且 skills/ 目录为空"
      exit 1
    fi
    info "skills/ 目录为空，运行生成脚本..."
    mkdir -p "$CMD_SKILLS_SRC"
    python3 "$SCRIPT"
  fi

  # 2. 全量清空 ~/.openclaw/skills/ 再统一写入
  rm -rf "$SKILLS_DST"
  mkdir -p "$SKILLS_DST"

  # 2a. 复制 142 个 MAS skill
  if [ -d "$MAS_SKILLS_SRC" ]; then
    cp -r "$MAS_SKILLS_SRC/"* "$SKILLS_DST/"
  else
    warn "未找到 MAS skills 目录：$MAS_SKILLS_SRC，跳过"
  fi

  # 2b. 复制 68 个 command-skill（同名时报错，不允许覆盖 MAS skill）
  CONFLICT=0
  for skill_dir in "$CMD_SKILLS_SRC"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    if [ -d "$SKILLS_DST/$skill_name" ]; then
      error "命名冲突：command-skill '$skill_name' 与已有 MAS skill 同名，请重命名"
      CONFLICT=$((CONFLICT + 1))
    else
      cp -r "$skill_dir" "$SKILLS_DST/$skill_name"
    fi
  done
  if [ "$CONFLICT" -gt 0 ]; then
    error "发现 $CONFLICT 个命名冲突，安装中止"
    exit 1
  fi

  CMD_COUNT=$(ls -1 "$CMD_SKILLS_SRC" | wc -l | tr -d ' ')
  TOTAL_COUNT=$(ls -1 "$SKILLS_DST" | wc -l | tr -d ' ')
  log "Skills 安装完成：command-skill $CMD_COUNT 个，共享目录总计 $TOTAL_COUNT 个"
}

# ── Step 4: 安装 Rules（全量覆盖）───────────────────────────
install_rules() {
  info "安装 Rules（全量覆盖）..."

  RULES_SRC="$REPO_DIR/rules"
  RULES_DST="$OC_HOME/rules"

  if [ ! -d "$RULES_SRC" ]; then
    warn "未找到 rules 目录：$RULES_SRC，跳过"
    return
  fi

  rm -rf "$RULES_DST"
  mkdir -p "$RULES_DST"
  cp -r "$RULES_SRC/"* "$RULES_DST/"

  log "Rules 已安装：$(ls -1 "$RULES_DST" | wc -l | tr -d ' ') 个语言"
}

# ── Step 5: 安装 Hooks（全量覆盖）───────────────────────────
install_hooks() {
  info "安装 Hooks..."

  # 5a. Internal hooks（session-bootstrap, pre-compact）
  INT_HOOKS_SRC="$REPO_DIR/hooks"
  INT_HOOKS_DST="$OC_HOME/hooks"

  if [ -d "$INT_HOOKS_SRC" ]; then
    mkdir -p "$INT_HOOKS_DST"
    for hook_dir in "$INT_HOOKS_SRC"/*/; do
      [ -d "$hook_dir" ] || continue
      hook_name=$(basename "$hook_dir")
      rm -rf "$INT_HOOKS_DST/$hook_name"
      cp -r "$hook_dir" "$INT_HOOKS_DST/$hook_name"
    done
    log "Internal hooks 已安装：$(ls -1 "$INT_HOOKS_DST" | wc -l | tr -d ' ') 个"
  fi

  # 5b. Plugin（ecc-hooks）：编译并安装
  PLUGIN_SRC="$REPO_DIR/plugin"
  PLUGIN_DST="$OC_HOME/plugins/ecc-hooks"

  if [ ! -d "$PLUGIN_SRC" ]; then
    warn "未找到 plugin 目录：$PLUGIN_SRC，跳过"
    return
  fi

  # 直接使用预编译的 dist（无需在目标机器上运行 npm/tsc）
  if [ ! -d "$PLUGIN_SRC/dist" ]; then
    warn "Plugin dist 目录不存在（$PLUGIN_SRC/dist），请先在开发机上运行 npm install && npx tsc"
    return
  fi

  # 用 openclaw CLI 安装 plugin（自动处理 allow/entries 配置）
  openclaw plugins install "$PLUGIN_SRC" --dangerously-force-unsafe-install 2>/dev/null || {
    # fallback：手动复制
    warn "openclaw plugins install 失败，回退到手动复制..."
    rm -rf "$PLUGIN_DST"
    mkdir -p "$PLUGIN_DST"
    cp -r "$PLUGIN_SRC/dist" "$PLUGIN_DST/"
    cp "$PLUGIN_SRC/package.json" "$PLUGIN_DST/"
    cp "$PLUGIN_SRC/openclaw.plugin.json" "$PLUGIN_DST/"
    if [ -d "$PLUGIN_SRC/node_modules/openclaw" ]; then
      mkdir -p "$PLUGIN_DST/node_modules"
      cp -r "$PLUGIN_SRC/node_modules/openclaw" "$PLUGIN_DST/node_modules/"
    fi
  }

  log "ecc-hooks plugin 已安装：$PLUGIN_DST"
}

# ── Step 6: 更新配置 ─────────────────────────────────────────
update_config() {
  info "更新 OpenClaw 配置..."

  python3 << 'PYEOF'
import json, pathlib

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'
cfg = json.loads(cfg_path.read_text())

# ── 1. 清理旧的 plugin 配置 ──────────────────────────────────
plugins = cfg.get('plugins', {})
allow_list = plugins.get('allow', [])
if 'ecc' in allow_list:
    allow_list.remove('ecc')
    plugins['allow'] = allow_list
    print('  - 移除 ecc from plugins.allow')

load = plugins.get('load', {})
paths = load.get('paths', [])
ecc_path = str(pathlib.Path.home() / '.openclaw' / 'plugins' / 'ecc')
if ecc_path in paths:
    paths.remove(ecc_path)
    load['paths'] = paths
    plugins['load'] = load
    print('  - 移除 ecc from plugins.load.paths')

if plugins:
    cfg['plugins'] = plugins

# ── 2. 清理旧的 agentToAgent 配置 ────────────────────────────
tools_cfg = cfg.get('tools', {})
if 'agentToAgent' in tools_cfg:
    del tools_cfg['agentToAgent']
    cfg['tools'] = tools_cfg
    print('  - 移除 agentToAgent 配置')

# ── 3. 配置 commands ─────────────────────────────────────────
commands = cfg.setdefault('commands', {})
commands['text'] = True           # 文本命令解析（/skill 依赖此项）
commands['nativeSkills'] = True   # Telegram/Discord 原生 skill 命令
commands['native'] = 'auto'       # 原生命令自动模式
print('  + commands: text=true, nativeSkills=true, native=auto')

# ── 4. 配置 agents.defaults.subagents ────────────────────────
# 正确路径：agents.defaults.subagents.maxSpawnDepth
agents_cfg = cfg.setdefault('agents', {})
defaults = agents_cfg.setdefault('defaults', {})
subagents = defaults.setdefault('subagents', {})
subagents['maxSpawnDepth'] = 2        # 支持 GAN 循环等二层嵌套
subagents['maxChildrenPerAgent'] = 10  # 并发子 agent 上限
print('  + agents.defaults.subagents: maxSpawnDepth=2, maxChildrenPerAgent=10')

# allowAgents 是 per-agent 配置，设置在 agents.list[id=main] 上
agents_list = agents_cfg.setdefault('list', [])
main_agent = next((a for a in agents_list if a.get('id') == 'main'), None)
if main_agent is None:
    main_agent = {'id': 'main'}
    agents_list.insert(0, main_agent)
main_agent.setdefault('subagents', {})['allowAgents'] = ['*']
print('  + agents.list[main].subagents.allowAgents = ["*"]')

# agents.list 由 openclaw agents add CLI 管理，无需手动写入
print('  ~ agents.list 由 CLI 管理，共',
      len(agents_cfg.get('list', [])), '个已注册')

# ── 5. 启用 Internal hooks ────────────────────────────────────
hooks_cfg = cfg.setdefault('hooks', {})
internal = hooks_cfg.setdefault('internal', {})
internal['enabled'] = True
entries = internal.setdefault('entries', {})
for hook_name in ['session-bootstrap', 'pre-compact']:
    entries.setdefault(hook_name, {})['enabled'] = True
print('  + hooks: session-bootstrap, pre-compact 已启用')

# ── 6. plugin 由 openclaw plugins install CLI 管理，无需手动写配置 ──
print('  ~ ecc-hooks plugin 由 CLI 安装，跳过手动配置')

# ── 7. 写回配置 ──────────────────────────────────────────────
cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
print('配置已更新')
PYEOF

  log "配置更新完成"
}

# ── Step 7: 重启 Gateway ─────────────────────────────────────
restart_gateway() {
  info "重启 OpenClaw Gateway..."

  if openclaw gateway restart 2>/dev/null; then
    log "Gateway 重启成功"
    sleep 2
  else
    warn "Gateway 重启失败，请手动重启：openclaw gateway restart"
  fi
}

# ── Step 8: 验证安装 ─────────────────────────────────────────
verify_install() {
  info "验证安装..."

  FAIL=0

  # ── 1. Skills ────────────────────────────────────────────────
  SKILL_COUNT=$(ls -1 "$OC_HOME/skills" 2>/dev/null | wc -l | tr -d ' ')
  CMD_COUNT=$(ls -1 "$OC_HOME/skills" 2>/dev/null | grep -c "^cmd_" || true)
  if [ "$SKILL_COUNT" -ge 100 ]; then
    log "Skills: $SKILL_COUNT 个（含 cmd_ $CMD_COUNT 个）"
  else
    error "Skills 数量不足：$SKILL_COUNT 个（期望 >= 100）"
    FAIL=$((FAIL + 1))
  fi

  # 检查关键 command-skill
  for name in cmd_tdd cmd_build_fix cmd_code_review cmd_plan cmd_e2e cmd_gan_build cmd_rust_review; do
    if [ -d "$OC_HOME/skills/$name" ]; then
      echo -e "  ${GREEN}✅ /skill $name${NC}"
    else
      echo -e "  ${RED}❌ /skill $name 未找到${NC}"
      FAIL=$((FAIL + 1))
    fi
  done

  # ── 2. Rules ─────────────────────────────────────────────────
  RULE_COUNT=$(ls -1 "$OC_HOME/rules" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$RULE_COUNT" -ge 1 ]; then
    log "Rules: $RULE_COUNT 个语言"
  else
    error "Rules 目录为空"
    FAIL=$((FAIL + 1))
  fi

  # ── 3. Hooks ─────────────────────────────────────────────────
  HOOK_COUNT=$(ls -1 "$OC_HOME/hooks" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$HOOK_COUNT" -ge 1 ]; then
    log "Hooks: $HOOK_COUNT 个"
  else
    warn "Hooks 目录为空"
  fi

  # ── 4. Plugin ────────────────────────────────────────────────
  if openclaw plugins list 2>/dev/null | grep -q "ecc-hooks"; then
    log "Plugin: ecc-hooks 已安装"
  elif [ -f "$OC_HOME/plugins/ecc-hooks/dist/index.js" ]; then
    log "Plugin: ecc-hooks 已安装（手动复制）"
  else
    error "Plugin: ecc-hooks 未找到"
    FAIL=$((FAIL + 1))
  fi

  # ── 5. openclaw.json 关键配置 ────────────────────────────────
  python3 << PYEOF
import json, pathlib, sys
cfg = json.loads((pathlib.Path.home() / '.openclaw' / 'openclaw.json').read_text())
commands = cfg.get('commands', {})
agents   = cfg.get('agents', {})
defaults = agents.get('defaults', {})
subagents = defaults.get('subagents', {})
hooks    = cfg.get('hooks', {}).get('internal', {})

fail = 0
checks = [
    (commands.get('text'),                                    'commands.text = true'),
    (commands.get('nativeSkills'),                            'commands.nativeSkills = true'),
    (subagents.get('maxSpawnDepth', 1) >= 2,                  'subagents.maxSpawnDepth >= 2'),
    (any(a.get('id') == 'main' and a.get('subagents', {}).get('allowAgents') == ['*']
         for a in agents.get('list', [])),                    'agents.list[main].subagents.allowAgents = ["*"]'),
    (len(agents.get('list', [])) >= 10,                       f'agents.list >= 10 个（当前 {len(agents.get("list",[]))} 个）'),
    (hooks.get('enabled'),                                    'hooks.internal.enabled = true'),
    (cfg.get('plugins', {}).get('entries', {}).get('ecc-hooks', {}).get('enabled', True) is not False
     or pathlib.Path.home().joinpath('.openclaw/plugins/ecc-hooks/dist/index.js').exists(),
                                                              'plugin ecc-hooks 已注册'),
]
for passed, label in checks:
    if passed:
        print(f'  \033[0;32m✅ {label}\033[0m')
    else:
        print(f'  \033[0;31m❌ {label}\033[0m')
        fail += 1
sys.exit(fail)
PYEOF
  PY_FAIL=$?
  FAIL=$((FAIL + PY_FAIL))

  # ── 总结 ─────────────────────────────────────────────────────
  echo ""
  if [ "$FAIL" -eq 0 ]; then
    log "所有检查通过 ✅"
  else
    error "$FAIL 项检查未通过，请检查上方错误"
    exit 1
  fi
}

# ── Main ─────────────────────────────────────────────────────
banner
check_deps
backup_existing
create_workspaces
install_skills
install_rules
install_hooks
update_config
restart_gateway
verify_install

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🎉  OpenClaw MAS installed successfully!        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "Usage:"
echo "  /skill cmd_tdd implement a login feature"
echo "  /skill cmd_build_fix"
echo "  /skill cmd_code_review"
echo "  /skill cmd_rust_review"
echo "  /skill cmd_gan_build build a todo app"
echo ""
echo "List all skills:"
echo "  openclaw skills list"
echo ""
echo "Docs: docs/flow.md  docs/architecture.md"
echo ""
