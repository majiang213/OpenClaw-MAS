---
name: cmd_hookify_help
description: "Display comprehensive OpenClaw hookify documentation"
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Hookify Help

Display comprehensive documentation for the OpenClaw hookify system.

## OpenClaw Hook System Overview

Hooks are automation scripts that execute when specific events occur in the OpenClaw gateway.

### Hook Structure

Each hook lives in a directory with two files:

```
.openclaw/hooks/<hook-name>/
├── HOOK.md       # Metadata: events, description, enabled state
└── handler.ts    # TypeScript implementation
```

### Available Events

| Event | type | action | When it fires |
|-------|------|--------|--------------|
| `command:new` | `command` | `new` | A new command is received |
| `command:reset` | `command` | `reset` | A command is reset |
| `command:stop` | `command` | `stop` | A command is stopped |
| `message:received` | `message` | `received` | A message is received from the user |
| `message:sent` | `message` | `sent` | A message is sent by the agent |
| `message:transcribed` | `message` | `transcribed` | A voice message is transcribed |
| `message:preprocessed` | `message` | `preprocessed` | A message is preprocessed |
| `session:compact:before` | `session` | `compact:before` | Before session compaction |
| `session:compact:after` | `session` | `compact:after` | After session compaction |
| `session:patch` | `session` | `patch` | Session state is patched |
| `agent:bootstrap` | `agent` | `bootstrap` | Agent bootstrap |
| `gateway:startup` | `gateway` | `startup` | Gateway startup |

### HOOK.md Format

```markdown
---
name: hook-name
description: "What this hook does"
events: ["command:new"]
enabled: true
emoji: "🛡️"
---
```

### handler.ts Format

```typescript
const handler = async (event) => {
  if (event.type !== "command" || event.action !== "new") {
    return;
  }
  // warn the user:
  event.messages.push('⚠️ Warning: reason');
  // Note: do not throw — it prevents other handlers from running
};
export default handler;
```

Available on `event`: `type`, `action`, `sessionKey`, `timestamp`, `messages` (push strings to notify user), `context` (event-specific data)

### CLI Commands

```bash
openclaw hooks list              # list all hooks
openclaw hooks enable <name>     # enable a hook
openclaw hooks disable <name>    # disable a hook
openclaw hooks info <name>       # view hook details
openclaw hooks check             # verify hook eligibility
```

### Hookify Skills

- `/skill cmd_hookify <path> [description]` — create new hook rules
- `/skill cmd_hookify_list <path>` — list all hooks
- `/skill cmd_hookify_configure <path>` — toggle hooks on/off
- `/skill cmd_hookify_help <path>` — this help page
