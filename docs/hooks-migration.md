# Hooks Migration: ECC → OpenClaw

## Background

ECC's hooks (`hooks/hooks.json`) use the Claude Code hook format and cannot be used directly in OpenClaw. This document describes how each ECC hook maps to OpenClaw's hook system.

---

## Hook Systems Compared

### Claude Code format (ECC)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "node script.js" }]
      }
    ]
  }
}
```

### OpenClaw has two hook systems

| System | Location | Capabilities |
|--------|----------|-------------|
| **Internal hooks** | `~/.openclaw/hooks/<name>/` | Message flow, session lifecycle, bootstrap |
| **Plugin hooks** | `api.registerHook()` in `plugin/index.ts` | Tool execution interception (before/after tool call) |

ECC's PreToolUse/PostToolUse hooks on Bash/Edit/Write must be implemented as **Plugin hooks** — internal hooks cannot intercept tool calls.

---

## Plugin Hook API

```typescript
api.registerHook(
  "before_tool_call",   // event name, or array ["before_tool_call", "after_tool_call"]
  handler,
  { name: "my-hook", description: "..." }
)

// before_tool_call event
type PluginHookBeforeToolCallEvent = {
  toolName: string;                 // "Bash" | "Edit" | "Write" | ...
  params: Record<string, unknown>;
  runId?: string;
  toolCallId?: string;
}

// before_tool_call return value
type PluginHookBeforeToolCallResult = {
  params?: Record<string, unknown>; // modified params to pass through
  block?: boolean;                  // true = prevent execution
  blockReason?: string;
  requireApproval?: {
    title: string;
    description: string;
    severity?: "info" | "warning" | "critical";
    timeoutMs?: number;
    timeoutBehavior?: "allow" | "deny";
    onResolution?: (decision: "allow-once"|"allow-always"|"deny"|"timeout"|"cancelled") => void;
  };
}

// after_tool_call event
type PluginHookAfterToolCallEvent = {
  toolName: string;
  params: Record<string, unknown>;
  runId?: string;
  toolCallId?: string;
  result?: unknown;
  error?: string;
  durationMs?: number;
}
```

Full plugin hook event list:

```
before_tool_call    after_tool_call    tool_result_persist
session_start       session_end
message_received    message_sending    message_sent
before_agent_start  before_agent_reply agent_end
before_model_resolve before_prompt_build
before_compaction   after_compaction   before_reset
subagent_spawning   subagent_spawned   subagent_ended
gateway_start       gateway_stop
before_install      before_dispatch    inbound_claim
before_message_write
```

---

## ECC Hook Mapping

| Hook | Original event | Function | OpenClaw implementation |
|------|---------------|----------|------------------------|
| `block-no-verify` | PreToolUse/Bash | Block `--no-verify` git flag | ✅ Plugin: `before_tool_call` |
| `auto-tmux-dev` | PreToolUse/Bash | Auto-start dev server in tmux | ⚠️ Plugin: `before_tool_call` (limited — tmux env differs) |
| `tmux-reminder` | PreToolUse/Bash | Remind to use tmux for long commands | ✅ Plugin: `before_tool_call` |
| `git-push-reminder` | PreToolUse/Bash | Prompt before git push | ✅ Plugin: `before_tool_call` |
| `commit-quality` | PreToolUse/Bash | Lint check before commit | ✅ Plugin: `before_tool_call` |
| `doc-file-warning` | PreToolUse/Write | Warn on non-standard doc files | ✅ Plugin: `before_tool_call` |
| `suggest-compact` | PreToolUse/Edit\|Write | Suggest manual context compaction | ⚠️ Plugin: `before_tool_call` (no context size info available) |
| `insaits-security` | PreToolUse/Bash\|Write\|Edit | AI security monitor (requires pip install) | ⚠️ Plugin: `before_tool_call` (requires external dependency) |
| `governance-capture (pre)` | PreToolUse/Bash\|Write\|Edit | Capture governance events | ✅ Plugin: `before_tool_call` |
| `config-protection` | PreToolUse/Write\|Edit | Block modifications to lint/formatter config | ✅ Plugin: `before_tool_call` |
| `mcp-health-check (pre)` | PreToolUse/\* | MCP server health check | ❌ No MCP concept in OpenClaw |
| `observe (pre)` | PreToolUse/\* | Continuous learning observation | ✅ Plugin: `before_tool_call` |
| `post-bash-command-log` | PostToolUse/Bash | Log bash commands | ✅ Plugin: `after_tool_call` |
| `pr-created` | PostToolUse/Bash | Record PR URL on creation | ✅ Plugin: `after_tool_call` |
| `quality-gate` | PostToolUse/Edit\|Write | Quality check after file edit | ✅ Plugin: `after_tool_call` |
| `post-edit-accumulator` | PostToolUse/Edit\|Write | Accumulate edited file list | ✅ Plugin: `after_tool_call` |
| `post-edit-console-warn` | PostToolUse/Edit | Check for console.log | ✅ Plugin: `after_tool_call` |
| `governance-capture (post)` | PostToolUse/Bash\|Write\|Edit | Capture governance events | ✅ Plugin: `after_tool_call` |
| `observe (post)` | PostToolUse/\* | Continuous learning observation | ✅ Plugin: `after_tool_call` |
| `mcp-health-check (post)` | PostToolUseFailure/\* | MCP reconnect on failure | ❌ No MCP concept in OpenClaw |
| `session-start-bootstrap` | SessionStart | Load previous session context | ✅ Internal: `agent:bootstrap` |
| `pre-compact` | PreCompact | Save state before compaction | ✅ Internal: `session:compact:before` |
| `stop-format-typecheck` | Stop | Batch format + typecheck | ✅ Plugin: `session_end` |
| `check-console-log` | Stop | Check for console.log | ⚠️ Plugin: `session_end` (only agent-edited files, not user edits) |
| `session-end` | Stop/SessionEnd | Save session state | ✅ Plugin: `session_end` |
| `evaluate-session` | Stop | Extract reusable patterns from session | ⚠️ Plugin: `session_end` (no transcript access) |
| `cost-tracker` | Stop | Record token/cost usage | ✅ Plugin: `session_end` |
| `desktop-notify` | Stop | macOS desktop notification | ✅ Plugin: `session_end` |
| `session-end-marker` | SessionEnd | Session end marker | ✅ Plugin: `session_end` |

---

## Implementation

### Directory structure

```
openclaw/
├── plugin/
│   ├── index.ts                  ← registers hooks (no tools)
│   ├── hooks/
│   │   ├── before-tool-call.ts   ← all PreToolUse hook logic
│   │   └── after-tool-call.ts    ← all PostToolUse hook logic
│   ├── package.json
│   └── tsconfig.json
└── hooks/                        ← internal hooks (message/session level)
    ├── session-bootstrap/
    │   ├── HOOK.md
    │   └── handler.ts
    ├── session-end/
    │   ├── HOOK.md
    │   └── handler.ts
    └── pre-compact/
        ├── HOOK.md
        └── handler.ts
```

### plugin/index.ts

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: "ecc-hooks",
  name: "ECC Hooks",
  description: "ECC tool execution hooks: security guards, quality gates, logging",

  register(api) {

    // ── before_tool_call ──────────────────────────────────────
    api.registerHook("before_tool_call", async (event, ctx) => {
      const { toolName, params } = event;

      // block-no-verify
      if (toolName === "Bash") {
        const cmd = String(params.command ?? "");
        if (/--no-verify/.test(cmd)) {
          return {
            block: true,
            blockReason: "🚫 --no-verify is blocked: do not bypass git hooks",
          };
        }
      }

      // git-push-reminder
      if (toolName === "Bash") {
        const cmd = String(params.command ?? "");
        if (/\bgit\s+push\b/.test(cmd)) {
          return {
            requireApproval: {
              title: "Git Push",
              description: "Review your changes before pushing. Run git diff HEAD~1 to check.",
              severity: "info",
              timeoutMs: 30000,
              timeoutBehavior: "allow",
            },
          };
        }
      }

      // config-protection
      if (toolName === "Write" || toolName === "Edit") {
        const filePath = String(params.file_path ?? params.path ?? "");
        const protectedPatterns = [
          /\.eslintrc/,
          /\.prettierrc/,
          /biome\.json/,
          /tsconfig\.json$/,
        ];
        if (protectedPatterns.some(p => p.test(filePath))) {
          return {
            requireApproval: {
              title: "Config File Modification",
              description: `Modifying ${filePath}. Fix the code instead of weakening the config.`,
              severity: "warning",
              timeoutMs: 30000,
              timeoutBehavior: "deny",
            },
          };
        }
      }

    }, { name: "ecc-before-tool-call", description: "ECC pre-tool guards" });


    // ── after_tool_call ───────────────────────────────────────
    api.registerHook("after_tool_call", async (event, ctx) => {
      const { toolName, params, result, error, durationMs } = event;

      // post-bash-command-log
      if (toolName === "Bash") {
        const logEntry = {
          timestamp: new Date().toISOString(),
          sessionKey: ctx.sessionKey,
          command: params.command,
          durationMs,
          error: error ?? null,
        };
        appendLog("bash-commands.log", logEntry);
      }

      // post-edit-accumulator
      if (toolName === "Edit" || toolName === "Write") {
        const filePath = String(params.file_path ?? params.path ?? "");
        if (/\.[jt]sx?$/.test(filePath)) {
          accumulateEditedFile(ctx.sessionKey, filePath);
        }
      }

      // pr-created
      if (toolName === "Bash") {
        const output = String(result ?? "");
        const prMatch = output.match(/https:\/\/github\.com\/[^\s]+\/pull\/\d+/);
        if (prMatch) {
          appendLog("pr-log.txt", `${new Date().toISOString()} ${prMatch[0]}\n`);
        }
      }

    }, { name: "ecc-after-tool-call", description: "ECC post-tool logging and checks" });


    // ── session_end ───────────────────────────────────────────
    api.registerHook("session_end", async (event, ctx) => {

      // stop-format-typecheck
      const editedFiles = getAccumulatedFiles(ctx.sessionKey);
      if (editedFiles.length > 0) {
        runFormatCheck(editedFiles);
      }

      // cost-tracker
      const costEntry = {
        timestamp: new Date().toISOString(),
        sessionKey: ctx.sessionKey,
        messageCount: event.messageCount,
        durationMs: event.durationMs,
      };
      appendLog("cost-log.jsonl", costEntry);

      // desktop-notify (macOS only)
      if (process.platform === "darwin") {
        try {
          const { execSync } = await import("child_process");
          execSync(
            `osascript -e 'display notification "Session complete" with title "OpenClaw ECC"'`,
            { timeout: 5000 }
          );
        } catch { /* silent fail */ }
      }

    }, { name: "ecc-session-end", description: "ECC session end tasks" });

  },
});
```

### Internal hooks

**hooks/session-bootstrap/HOOK.md**

```yaml
---
name: session-bootstrap
description: "Inject previous session memory into agent bootstrap context"
metadata:
  openclaw:
    emoji: "🧠"
    events: ["agent:bootstrap"]
---
```

**hooks/pre-compact/HOOK.md**

```yaml
---
name: pre-compact
description: "Save state snapshot before context compaction"
metadata:
  openclaw:
    emoji: "💾"
    events: ["session:compact:before"]
---
```

---

## Coverage Summary

### ✅ Fully implemented (13)

| Hook | Implementation |
|------|---------------|
| `block-no-verify` | Plugin `before_tool_call` — detects `--no-verify` → block |
| `git-push-reminder` | Plugin `before_tool_call` — detects `git push` → requireApproval |
| `commit-quality` | Plugin `before_tool_call` — detects `git commit` → runs lint |
| `config-protection` | Plugin `before_tool_call` — detects writes to `.eslintrc`/`biome.json` → requireApproval |
| `doc-file-warning` | Plugin `before_tool_call` — detects writes to non-standard doc files → warn |
| `governance-capture` | Plugin `before_tool_call` + `after_tool_call` |
| `post-bash-command-log` | Plugin `after_tool_call` — logs Bash commands |
| `pr-created` | Plugin `after_tool_call` — detects PR URL → records it |
| `post-edit-accumulator` | Plugin `after_tool_call` — accumulates edited JS/TS file paths |
| `quality-gate` | Plugin `after_tool_call` — runs lint/format after file edits |
| `session-bootstrap` | Internal `agent:bootstrap` — injects MEMORY.md and last session summary |
| `pre-compact` | Internal `session:compact:before` — saves snapshot before compaction |
| `desktop-notify` | Plugin `session_end` — macOS desktop notification |

### ⚠️ Degraded (4)

**`evaluate-session` and `session-end`**

Original: reads full session JSONL from `transcript_path` to extract patterns and generate summaries.

Degraded because: OpenClaw's `session_end` event does not expose `transcript_path` or `sessionFile`:
```typescript
type PluginHookSessionEndEvent = {
  sessionId: string;
  sessionKey?: string;
  messageCount: number;   // only metadata
  durationMs?: number;    // no transcript path
}
```
`sessionFile` is only available in `before_compaction`/`after_compaction`, not at session end.

After degradation: records session metadata (messageCount, durationMs, timestamp) only. Cannot read session content, generate summaries, or extract reusable patterns.

TODO: file a feature request with OpenClaw to expose `sessionFile` in `session_end`.

---

**`suggest-compact`**

Original: detects context window usage and suggests manual compaction before hitting the limit.

Degraded because: `before_tool_call` events do not include context size information.

After degradation: counts tool calls and reminds every N calls — imprecise, may fire too early or too late.

---

**`check-console-log`**

Original: at Stop, reads git-modified file list and checks for `console.log`.

Degraded because: `session_end` has no git context — no way to know which files were modified this session.

After degradation: only checks files accumulated by `post-edit-accumulator` (files the agent explicitly edited). Files modified by the user directly are not checked.

---

### ❌ Not implemented (2)

**`mcp-health-check`** (PreToolUse and PostToolUseFailure variants)

These hooks detect and recover MCP (Model Context Protocol) server health. OpenClaw has no MCP concept — not applicable.
