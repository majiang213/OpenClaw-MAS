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
- **Action**: `warn` only — OpenClaw hooks cannot block actions, they can only push warning messages to the user
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
// event names use colon-separated format: "command:new" → type="command", action="new"
// "session:compact:before" → type="session", action="compact:before"
const handler = async (event) => {
  if (event.type !== "command" || event.action !== "new") {
    return;
  }
  // for message:received use event.context.content
  // for command:new use event.context.commandSource or event.context.workspaceDir
  const content = event.context?.content ?? event.context?.commandSource ?? '';
  const pattern = /<regex pattern>/i;

  if (pattern.test(content)) {
    event.messages.push('⚠️ Warning: <description of unwanted behavior detected>');
  }
};
export default handler;
```

> Note: Do not throw errors in handlers — it will prevent other handlers from running.

### Step 4: Register the Hook

Instruct the user to register the hook:
```bash
openclaw hooks enable <hook-name>
# or add to openclaw.json:
# "hooks.internal.entries.<hook-name>": { "enabled": true }
```

### Step 5: Confirm

Report created hook files and remind the user to run `openclaw hooks list` to verify.
