#!/bin/bash
# ══════════════════════════════════════════════════════════════
# OpenClaw MAS · 一键安装脚本
# ══════════════════════════════════════════════════════════════
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OC_HOME="$HOME/.openclaw"
OC_CFG="$OC_HOME/openclaw.json"
MANIFEST="$OC_HOME/.ecc-mas-manifest.json"

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
  AGENT_NAMES=()
  for agent_dir in "$AGENTS_DIR"/*/; do
    [ -d "$agent_dir" ] || continue
    agent_name=$(basename "$agent_dir")
    ws="$OC_HOME/workspace-$agent_name"
    mkdir -p "$ws"
    cp -f "$agent_dir"/* "$ws/" 2>/dev/null || true
    AGENT_NAMES+=("$agent_name")
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

# ── Step 2: 安装 Skills（manifest-aware，不清空用户 skills）──
install_skills() {
  info "安装 Skills（保留用户自定义 skills）..."

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

  mkdir -p "$SKILLS_DST"

  python3 << PYEOF
import json, pathlib, shutil, sys

oc_home   = pathlib.Path.home() / '.openclaw'
skills_dst = oc_home / 'skills'
manifest_path = oc_home / '.ecc-mas-manifest.json'

mas_src = pathlib.Path('$MAS_SKILLS_SRC')
cmd_src = pathlib.Path('$CMD_SKILLS_SRC')

# 读取旧 manifest（若存在）
old_skills = set()
if manifest_path.exists():
    try:
        old_manifest = json.loads(manifest_path.read_text())
        old_skills = set(old_manifest.get('entries', {}).get('skills', []))
    except Exception:
        pass

# 收集本次要安装的 skill 名称
new_skills = set()
conflicts = []

# 2a. MAS skills
if mas_src.exists():
    for d in sorted(mas_src.iterdir()):
        if d.is_dir():
            new_skills.add(d.name)

# 2b. command-skills（检查与 MAS skill 是否同名冲突）
if cmd_src.exists():
    for d in sorted(cmd_src.iterdir()):
        if d.is_dir():
            if d.name in new_skills:
                conflicts.append(d.name)
            else:
                new_skills.add(d.name)

if conflicts:
    for name in conflicts:
        print(f'  ❌ 命名冲突：command-skill "{name}" 与 MAS skill 同名，请重命名', flush=True)
    sys.exit(1)

# 3. 复制本次所有 skills（覆盖旧版本，不动用户 skills）
copied = 0
if mas_src.exists():
    for d in sorted(mas_src.iterdir()):
        if d.is_dir():
            dst = skills_dst / d.name
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(d, dst)
            copied += 1

if cmd_src.exists():
    for d in sorted(cmd_src.iterdir()):
        if d.is_dir():
            dst = skills_dst / d.name
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(d, dst)
            copied += 1

# 4. 删除旧 manifest 中有、但本次不再包含的 skills（即从 repo 移除的 skill）
removed = 0
for name in old_skills - new_skills:
    dst = skills_dst / name
    if dst.exists():
        shutil.rmtree(dst)
        removed += 1
        print(f'  - 已移除旧 skill（repo 中已删除）：{name}', flush=True)

# 5. 统计用户自定义 skills（不在 manifest 中的）
user_skills = [
    d.name for d in skills_dst.iterdir()
    if d.is_dir() and d.name not in new_skills and d.name not in old_skills
]

print(f'  已安装：{copied} 个 MAS/cmd skill', flush=True)
if removed:
    print(f'  已移除过期 skill：{removed} 个', flush=True)
if user_skills:
    print(f'  保留用户自定义 skill：{len(user_skills)} 个（{", ".join(sorted(user_skills)[:5])}{"..." if len(user_skills) > 5 else ""}）', flush=True)

# 6. 将 new_skills 写入临时文件供 shell 读取
tmp = oc_home / '.ecc-mas-new-skills.tmp'
tmp.write_text(json.dumps(sorted(new_skills)))
PYEOF

  SKILL_COUNT=$(ls -1 "$SKILLS_DST" | wc -l | tr -d ' ')
  log "Skills 安装完成：共 $SKILL_COUNT 个（含用户自定义）"
}

# ── Step 3: 安装 Rules（manifest-aware，不清空用户 rules）───
install_rules() {
  info "安装 Rules（保留用户自定义 rules）..."

  RULES_SRC="$REPO_DIR/rules"
  RULES_DST="$OC_HOME/rules"

  if [ ! -d "$RULES_SRC" ]; then
    warn "未找到 rules 目录：$RULES_SRC，跳过"
    return
  fi

  mkdir -p "$RULES_DST"

  python3 << PYEOF
import json, pathlib, shutil

oc_home    = pathlib.Path.home() / '.openclaw'
rules_dst  = oc_home / 'rules'
manifest_path = oc_home / '.ecc-mas-manifest.json'
rules_src  = pathlib.Path('$RULES_SRC')

# 读取旧 manifest
old_rules = set()
if manifest_path.exists():
    try:
        old_manifest = json.loads(manifest_path.read_text())
        old_rules = set(old_manifest.get('entries', {}).get('rules', []))
    except Exception:
        pass

# 本次要安装的 rule 目录名
new_rules = set()
for d in sorted(rules_src.iterdir()):
    if d.is_dir():
        new_rules.add(d.name)

# 复制（覆盖旧版本）
copied = 0
for d in sorted(rules_src.iterdir()):
    if d.is_dir():
        dst = rules_dst / d.name
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(d, dst)
        copied += 1

# 移除旧 manifest 中有、但本次 repo 已删除的 rule 目录
removed = 0
for name in old_rules - new_rules:
    dst = rules_dst / name
    if dst.exists():
        shutil.rmtree(dst)
        removed += 1
        print(f'  - 已移除旧 rule（repo 中已删除）：{name}', flush=True)

# 用户自定义 rules（不在 manifest 中）
user_rules = [
    d.name for d in rules_dst.iterdir()
    if d.is_dir() and d.name not in new_rules and d.name not in old_rules
]

print(f'  已安装：{copied} 个 rule 目录', flush=True)
if user_rules:
    print(f'  保留用户自定义 rule：{len(user_rules)} 个（{", ".join(sorted(user_rules))}）', flush=True)

# 写临时文件供 shell 读取
tmp = oc_home / '.ecc-mas-new-rules.tmp'
tmp.write_text(json.dumps(sorted(new_rules)))
PYEOF

  log "Rules 安装完成：$(ls -1 "$RULES_DST" | wc -l | tr -d ' ') 个目录"
}

# ── Step 4: 安装 Hooks（manifest-aware）─────────────────────
install_hooks() {
  info "安装 Hooks..."

  INT_HOOKS_SRC="$REPO_DIR/hooks"
  INT_HOOKS_DST="$OC_HOME/hooks"
  HOOK_NAMES=()

  if [ -d "$INT_HOOKS_SRC" ]; then
    mkdir -p "$INT_HOOKS_DST"
    for hook_dir in "$INT_HOOKS_SRC"/*/; do
      [ -d "$hook_dir" ] || continue
      hook_name=$(basename "$hook_dir")
      rm -rf "$INT_HOOKS_DST/$hook_name"
      cp -r "$hook_dir" "$INT_HOOKS_DST/$hook_name"
      HOOK_NAMES+=("$hook_name")
    done
    log "Internal hooks 已安装：${#HOOK_NAMES[@]} 个"
  fi

  # 写临时文件
  python3 -c "
import json, pathlib
names = '${HOOK_NAMES[*]}'.split()
(pathlib.Path.home() / '.openclaw' / '.ecc-mas-new-hooks.tmp').write_text(json.dumps(names))
"

  # Plugin（ecc-hooks）：编译并安装
  PLUGIN_SRC="$REPO_DIR/plugin"
  PLUGIN_DST="$OC_HOME/plugins/ecc-hooks"

  if [ ! -d "$PLUGIN_SRC" ]; then
    warn "未找到 plugin 目录：$PLUGIN_SRC，跳过"
    return
  fi

  if [ ! -d "$PLUGIN_SRC/dist" ]; then
    warn "Plugin dist 目录不存在（$PLUGIN_SRC/dist），请先在开发机上运行 npm install && npx tsc"
    return
  fi

  openclaw plugins install "$PLUGIN_SRC" --dangerously-force-unsafe-install 2>/dev/null || {
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

# ── Step 5: 更新配置 ─────────────────────────────────────────
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
commands['text'] = True
commands['nativeSkills'] = True
commands['native'] = 'auto'
print('  + commands: text=true, nativeSkills=true, native=auto')

# ── 4. 配置 agents.defaults.subagents ────────────────────────
agents_cfg = cfg.setdefault('agents', {})
defaults = agents_cfg.setdefault('defaults', {})
subagents = defaults.setdefault('subagents', {})
subagents['maxSpawnDepth'] = 2
subagents['maxChildrenPerAgent'] = 10
print('  + agents.defaults.subagents: maxSpawnDepth=2, maxChildrenPerAgent=10')

agents_list = agents_cfg.setdefault('list', [])
main_agent = next((a for a in agents_list if a.get('id') == 'main'), None)
if main_agent is None:
    main_agent = {'id': 'main'}
    agents_list.insert(0, main_agent)
main_agent.setdefault('subagents', {})['allowAgents'] = ['*']
print('  + agents.list[main].subagents.allowAgents = ["*"]')

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

print('  ~ ecc-hooks plugin 由 CLI 安装，跳过手动配置')

# ── 6. 写回配置 ──────────────────────────────────────────────
cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
print('配置已更新')
PYEOF

  log "配置更新完成"
}

# ── Step 6: 写入 Manifest ────────────────────────────────────
write_manifest() {
  info "写入安装 manifest..."

  python3 << PYEOF
import json, pathlib, datetime

oc_home = pathlib.Path.home() / '.openclaw'
manifest_path = oc_home / '.ecc-mas-manifest.json'

def read_tmp(name):
    p = oc_home / f'.ecc-mas-new-{name}.tmp'
    if p.exists():
        data = json.loads(p.read_text())
        p.unlink()
        return data
    return []

# 读取各步骤写入的临时文件
skills = read_tmp('skills')
rules  = read_tmp('rules')
hooks  = read_tmp('hooks')

# agents：从 agents/ 目录收集
agents_dir = pathlib.Path('$REPO_DIR') / 'agents'
agents = sorted(d.name for d in agents_dir.iterdir() if d.is_dir()) if agents_dir.exists() else []

manifest = {
    'version': '1.0',
    'installed_at': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    'installer_repo': '$REPO_DIR',
    'entries': {
        'skills': skills,
        'rules':  rules,
        'hooks':  hooks,
        'agents': agents,
    }
}

manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
print(f'  manifest 已写入：{manifest_path}')
print(f'  skills: {len(skills)}  rules: {len(rules)}  hooks: {len(hooks)}  agents: {len(agents)}')
PYEOF

  log "Manifest 写入完成：$MANIFEST"
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

  # ── 5. Manifest ──────────────────────────────────────────────
  if [ -f "$MANIFEST" ]; then
    log "Manifest: $MANIFEST"
  else
    error "Manifest 未找到：$MANIFEST"
    FAIL=$((FAIL + 1))
  fi

  # ── 6. openclaw.json 关键配置 ────────────────────────────────
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
create_workspaces
install_skills
install_rules
install_hooks
update_config
write_manifest
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
