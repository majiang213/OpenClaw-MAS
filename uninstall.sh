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
  echo -e "${RED}║    Restore backup + remove workspaces    ║${NC}"
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
  echo -e "${YELLOW}openclaw.json、skills、rules、hooks 将从安装前备份还原。${NC}"
  echo -e "${YELLOW}Agent workspace 目录和 plugin 将被删除。${NC}"
  echo ""
  read -r -p "确认卸载？[y/N] " ans
  case "$ans" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "已取消。"; exit 0 ;;
  esac
}

# ── Step 1: 从备份还原配置 ────────────────────────────────────
restore_from_backup() {
  info "从安装前备份还原 OpenClaw 配置..."

  BACKUP_BASE="$OC_HOME/backups"
  LATEST_BACKUP=$(ls -1dt "$BACKUP_BASE"/pre-ecc-install-* 2>/dev/null | head -1)

  if [ -z "$LATEST_BACKUP" ]; then
    warn "未找到安装前备份（$BACKUP_BASE/pre-ecc-install-*），跳过配置还原"
    return
  fi

  info "使用备份：$LATEST_BACKUP"

  # 还原 openclaw.json
  if [ -f "$LATEST_BACKUP/openclaw.json" ]; then
    cp "$LATEST_BACKUP/openclaw.json" "$OC_CFG"
    log "openclaw.json 已从备份还原"
  else
    warn "备份中未找到 openclaw.json，跳过"
  fi

  # 还原 skills
  if [ -d "$LATEST_BACKUP/skills" ]; then
    rm -rf "$OC_HOME/skills"
    cp -R "$LATEST_BACKUP/skills" "$OC_HOME/skills"
    log "skills 已从备份还原"
  else
    rm -rf "$OC_HOME/skills"
    log "备份中无 skills，已清空"
  fi

  # 还原 rules
  if [ -d "$LATEST_BACKUP/rules" ]; then
    rm -rf "$OC_HOME/rules"
    cp -R "$LATEST_BACKUP/rules" "$OC_HOME/rules"
    log "rules 已从备份还原"
  else
    rm -rf "$OC_HOME/rules"
    log "备份中无 rules，已清空"
  fi

  # 还原 hooks
  if [ -d "$LATEST_BACKUP/hooks" ]; then
    rm -rf "$OC_HOME/hooks"
    cp -R "$LATEST_BACKUP/hooks" "$OC_HOME/hooks"
    log "hooks 已从备份还原"
  else
    rm -rf "$OC_HOME/hooks"
    log "备份中无 hooks，已清空"
  fi

  log "配置还原完成（来源：$LATEST_BACKUP）"
}

# ── Step 2: 移除 Agent Workspace ─────────────────────────────
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

  log "Agent Workspace 已移除：$COUNT 个目录"
}

# ── Step 3: 移除 Plugin ───────────────────────────────────────
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

# ── Step 4: 重启 Gateway ─────────────────────────────────────
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
restore_from_backup
remove_workspaces
remove_plugin
restart_gateway

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅  OpenClaw MAS 已完全卸载。                   ║${NC}"
echo -e "${GREEN}║  备份保留在 ~/.openclaw/backups/                 ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
