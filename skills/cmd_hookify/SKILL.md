---
name: cmd_hookify
description: "Create OpenClaw hook rules to prevent unwanted agent behaviors"
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Hookify

Create OpenClaw hooks to prevent unwanted agent behaviors by analyzing conversation patterns or explicit user instructions.

## Usage

`/skill cmd_hookify <project-path> [description of behavior to prevent]`

If no description is provided, use the `conversation-analyzer` agent to find behaviors worth preventing from the current conversation.

## Workflow

### Step 1: Gather Behavior Info

- With description: parse the user's description of the unwanted behavior
- Without description: delegate to `conversation-analyzer` agent to identify:
  - Explicit corrections the user made
  - Frustrated reactions to repeated mistakes
  - Reverted changes
  - Repeated similar issues

### Step 2: Design the Hook

For each behavior to prevent, determine:
- **Event**: which OpenClaw event to listen on (see event types below)
- **Pattern**: what to match (regex against message content, command source, etc.)
- **Name**: a descriptive kebab-case name

> Note: Internal hooks can only **warn** (push messages to the user). They cannot block actions. Errors in handlers are caught and logged but don't prevent other handlers from running.

### Step 3: Generate Hook Files

Create a hook directory at `<project-path>/.openclaw/hooks/<hook-name>/`:

**HOOK.md**:
```markdown
---
name: <hook-name>
description: "<what this hook warns about>"
events: ["<event:action>"]
enabled: true
emoji: "🛡️"
---
```

**handler.ts**:
```typescript
import type { InternalHookEvent } from "openclaw/plugin-sdk/hook-runtime";

const handler = async (event: InternalHookEvent) => {
  if (event.type !== "<type>" || event.action !== "<action>") {
    return;
  }
  const ctx = event.context as Record<string, unknown>;
  const content = (ctx.content ?? ctx.commandSource ?? '') as string;
  const pattern = /<regex pattern>/i;

  if (pattern.test(content)) {
    event.messages.push('⚠️ Warning: <description of unwanted behavior detected>');
  }
};
export default handler;
```

### Event Types & Context Fields

| Event | type | action | Useful context fields |
|-------|------|--------|-----------------------|
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

### Step 4: Register the Hook

```bash
openclaw hooks enable <hook-name>
```

Or add to `openclaw.json`:
```json
"hooks.internal.entries.<hook-name>": { "enabled": true }
```

### Step 5: Confirm

Report created hook files and remind the user to run `openclaw hooks list` to verify.
