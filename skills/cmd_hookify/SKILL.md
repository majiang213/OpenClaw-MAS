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
- **Event**: which OpenClaw event to listen on (`command:new`, `message:received`, `message:sent`, `session:patch`, etc.)
- **Pattern**: what to match (regex against message content, command text, etc.)
- **Action**: `block` (prevent) or `warn` (notify)
- **Name**: a descriptive kebab-case name

### Step 3: Generate Hook Files

Create a hook directory at `<project-path>/.openclaw/hooks/<hook-name>/`:

**HOOK.md**:
```markdown
---
name: <hook-name>
description: "<what this hook prevents>"
events: ["<event-type>"]
enabled: true
emoji: "🛡️"
---

# <Hook Name>

Prevents: <description of unwanted behavior>

## Trigger

Event: `<event-type>`
Pattern: `<regex pattern>`
Action: <block|warn>
```

**handler.ts**:
```typescript
import type { HookContext } from '@openclaw/hooks';

export default async function handler(ctx: HookContext) {
  const content = ctx.messages?.at(-1)?.content ?? '';
  const pattern = /<regex pattern>/i;

  if (pattern.test(content)) {
    ctx.push({
      role: 'system',
      content: '⚠️ Hook triggered: <description of what was blocked/warned>',
    });
    // To block: throw new Error('Blocked by hookify rule: <name>');
    // To warn: just push the message above
  }
}
```

### Step 4: Register the Hook

Instruct the user to register the hook:
```bash
openclaw hooks enable <hook-name>
# or add to openclaw.json:
# "hooks.internal.entries.<hook-name>": { "enabled": true }
```

### Step 5: Confirm

Report created hook files and remind the user to run `openclaw hooks list` to verify.
