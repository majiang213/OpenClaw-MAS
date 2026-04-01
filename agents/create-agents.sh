#!/bin/bash
# Create all OpenClaw agents from ECC agent definitions
# Usage: ./openclaw/agents/create-agents.sh

set -e

OPENCLAW_ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ECC_AGENTS_DIR="$(cd "$SCRIPT_DIR/../../agents" && pwd)"

echo "🦞 Creating OpenClaw Agents from ECC definitions..."
echo ""

AGENTS=(
  # Core agents
  "planner" "architect" "reviewer"
  
  # GAN loop
  "gan-generator" "gan-evaluator" "gan-planner"
  
  # Reviewers
  "security-reviewer" "database-reviewer" "flutter-reviewer"
  "go-reviewer" "kotlin-reviewer" "rust-reviewer"
  "typescript-reviewer" "cpp-reviewer" "healthcare-reviewer"
  "python-reviewer"
  
  # Build resolvers
  "build-error-resolver" "cpp-build-resolver" "go-build-resolver"
  "kotlin-build-resolver" "rust-build-resolver" "pytorch-build-resolver"
  "gradle-build-resolver" "java-build-resolver"
  
  # Special tasks
  "tdd-guide" "performance-optimizer" "chief-of-staff"
  "e2e-runner" "docs-lookup" "doc-updater"
  "refactor-cleaner" "loop-operator" "harness-optimizer"
  
  # Opensource
  "opensource-forker" "opensource-packager" "opensource-sanitizer"
)

CREATED=0
SKIPPED=0

for agent_id in "${AGENTS[@]}"; do
  workspace="$OPENCLAW_ROOT/workspace-${agent_id}"
  src="$ECC_AGENTS_DIR/${agent_id}.md"
  
  if [ ! -f "$src" ]; then
    echo "⚠️  Skipping $agent_id (no definition: $src)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  
  echo "Creating $agent_id Agent..."
  
  # Create agent (suppress output, check for errors)
  if openclaw agents add "$agent_id" --workspace "$workspace" 2>&1 | grep -q "Workspace OK"; then
    # Copy agent definition as AGENTS.md
    cp "$src" "$workspace/AGENTS.md"
    echo "  ✅ $agent_id"
    CREATED=$((CREATED + 1))
  else
    # Agent might already exist, just copy AGENTS.md
    if [ -d "$workspace" ]; then
      cp "$src" "$workspace/AGENTS.md"
      echo "  ✅ $agent_id (updated AGENTS.md)"
      CREATED=$((CREATED + 1))
    else
      echo "  ❌ $agent_id (failed to create)"
      SKIPPED=$((SKIPPED + 1))
    fi
  fi
done

echo ""
echo "═══════════════════════════════════════"
echo "🎉 Created $CREATED agents"
if [ $SKIPPED -gt 0 ]; then
  echo "⚠️  Skipped $SKIPPED agents"
fi
echo "═══════════════════════════════════════"
echo ""
echo "Next steps:"
echo "1. openclaw gateway restart"
echo "2. openclaw agents list"
echo ""
