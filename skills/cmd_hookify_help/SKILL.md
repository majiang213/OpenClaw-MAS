---
name: cmd_hookify_help
description: "Display comprehensive OpenClaw hookify documentation"
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path>"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Hookify Help

Display comprehensive documentation for the OpenClaw hookify system.

## OpenClaw Hook System Overview

Hooks are automation scripts that execute when specific events occur in the OpenClaw gateway. Internal hooks can push warning messages to the user but cannot block actions — errors in handlers are caught and logged without stopping other handlers.

### Hook Structure

```
.openclaw/hooks/<hook-name>/
├── HOOK.md       # Metadata: events, description, enabled state
└── handler.ts    # TypeScript implementation
```

### Available Events & Context Fields

| Event | type | action | Key context fields |
|-------|------|--------|--------------------|
| `command:new` | `command` | `new` | `commandSource`, `workspaceDir`, `sessionEntry`, `cfg` |
| `command:reset` | `command` | `reset` | `sessionEntry` |
| `command:stop` | `command` | `stop` | `sessionEntry` |
| `message:received` | `message` | `received` | `from`, `content`, `channelId`, `conversationId`, `metadata` |
| `message:sent` | `message` | `sent` | `to`, `content`, `success`, `channelId`, `groupId` |
| `message:transcribed` | `message` | `transcribed` | `content`, `transcript`, `from`, `channelId` |
| `message:preprocessed` | `message` | `preprocessed` | `body`, `bodyForAgent`, `transcript`, `isGroup`, `groupId` |
| `session:patch` | `session` | `patch` | `sessionEntry`, `patch`, `cfg` |
| `agent:bootstrap` | `agent` | `bootstrap` | `workspaceDir`, `bootstrapFiles`, `agentId`, `sessionKey` |
| `gateway:startup` | `gateway` | `startup` | `cfg`, `workspaceDir` |

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
import type { InternalHookEvent } from "openclaw/plugin-sdk/hook-runtime";

const handler = async (event: InternalHookEvent) => {
  if (event.type !== "command" || event.action !== "new") {
    return;
  }
  const ctx = event.context as Record<string, unknown>;
  const content = (ctx.content ?? ctx.commandSource ?? '') as string;

  if (/pattern/i.test(content)) {
    event.messages.push('⚠️ Warning: reason');
  }
  // Note: do not throw — errors are caught but prevent other handlers from running
};
export default handler;
```

### InternalHookEvent interface

```typescript
interface InternalHookEvent {
  type: "command" | "session" | "agent" | "gateway" | "message";
  action: string;
  sessionKey: string;
  context: Record<string, unknown>;
  timestamp: Date;
  messages: string[];  // push strings here to notify the user
}
```

### Type guards (from "openclaw/plugin-sdk/hook-runtime")

```typescript
isMessageReceivedEvent(event)    // narrows to MessageReceivedHookEvent
isMessageSentEvent(event)        // narrows to MessageSentHookEvent
isMessageTranscribedEvent(event) // narrows to MessageTranscribedHookEvent
isMessagePreprocessedEvent(event)
isSessionPatchEvent(event)
isAgentBootstrapEvent(event)
isGatewayStartupEvent(event)
```

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
