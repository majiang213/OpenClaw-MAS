# OpenClaw Integration

Run Everything Claude Code in OpenClaw - a multi-channel gateway (WhatsApp, Telegram, Discord, etc.)

## Quick Start

### 1. Install Plugin

```bash
openclaw plugins install ./openclaw/plugin
```

### 2. Create Agents

```bash
./openclaw/agents/create-agents.sh
```

### 3. Restart Gateway

```bash
openclaw gateway restart
```

### 4. Use Commands

```bash
# From chat
/gan_build "Build a todo app"
/code_review
/e2e
/context_budget
```

## What's Included

- **37 Agents**: Each ECC agent becomes an independent OpenClaw agent
- **86 Commands**: All ECC commands available as OpenClaw plugin commands
- **Direct Mapping**: ECC `commands/*.md` → OpenClaw `api.registerCommand()`

## Available Commands

### High Priority (8)

| Command | Agent | Description |
|---------|-------|-------------|
| `/gan_build` | planner | GAN development loop |
| `/gan_design` | architect | GAN design loop |
| `/code_review` | reviewer | Code review |
| `/e2e` | e2e-runner | E2E testing |
| `/checkpoint` | main | Session checkpoint |
| `/eval` | gan-evaluator | Evaluation |
| `/tdd` | tdd-guide | TDD workflow |
| `/refactor_clean` | refactor-cleaner | Refactoring |

### Language-Specific (24)

- **C++**: `/cpp_build`, `/cpp_review`, `/cpp_test`
- **Go**: `/go_build`, `/go_review`, `/go_test`
- **Kotlin**: `/kotlin_build`, `/kotlin_review`, `/kotlin_test`
- **Rust**: `/rust_build`, `/rust_review`, `/rust_test`
- **TypeScript**: `/ts_build`, `/ts_review`
- **Python**: `/python_build`, `/python_review`, `/python_test`
- **Java**: `/java_build`, `/gradle_build`, `/java_review`
- **Flutter**: `/flutter_build`, `/flutter_review`
- **Other**: `/pytorch_build`, `/healthcare_review`

### Tools (30+)

- `/security_scan`, `/performance_audit`
- `/build_error`, `/db_review`, `/harness_optimize`
- `/update_docs`, `/loop_start`, `/loop_status`
- `/opensource_fork`, `/opensource_package`, `/opensource_clean`
- `/prp_*` (5 PRP workflow commands)
- `/quality_gate`, `/test_coverage`, `/verify`
- `/skill_create`, `/skill_health`, `/prompt_optimize`
- `/save_session`, `/resume_session`
- `/multi_*` (5 multi-agent commands)
- And more...

**Full list**: See [`plugin/index.ts`](./plugin/index.ts)

## Architecture

```
ECC Project              OpenClaw
┌─────────────────┐      ┌──────────────────┐
│ agents/         │      │ ~/.openclaw/     │
│  ├─ planner.md  │  →   │  ├─ workspace-   │
│  ├─ architect.md │      │  │  planner/    │
│  └─ ...         │      │  │  └─ AGENTS.md│
└─────────────────┘      │  └─ workspace-   │
                         │     architect/   │
┌─────────────────┐      │     └─ AGENTS.md │
│ commands/       │      └──────────────────┘
│  ├─ gan-build.md │     
│  ├─ code-review. │      ┌──────────────────┐
│  └─ ...         │  →   │ plugin/          │
└─────────────────┘      │  ├─ index.ts     │
                         │  │ (86 commands) │
                         │  └─ ...          │
                         └──────────────────┘
```

## Conversion Rules

### Agents

```bash
# ECC: agents/planner.md
# OpenClaw: ~/.openclaw/workspace-planner/AGENTS.md

cp agents/planner.md ~/.openclaw/workspace-planner/AGENTS.md
```

**Rule**: Direct copy, no modification needed!

### Commands

```typescript
// ECC: commands/gan-build.md
// OpenClaw: plugin/index.ts

api.registerCommand({
  name: "gan_build",  // kebab-case → snake_case
  description: "GAN 式开发循环",
  parameters: Type.Object({
    brief: Type.String({ description: "项目描述" }),
    max_iterations: Type.Optional(Type.Number({ default: 15 })),
  }),
  async execute(_id, params) {
    const command = readCommand("gan-build");
    const result = await api.runtime.sessions_spawn({
      agentId: "planner",  // Maps to ECC agent
      task: `${command}\n\nBrief: ${params.brief}`,
      label: "gan-build",
      runTimeoutSeconds: params.max_iterations * 60,
    });
    return {
      content: [{
        type: "text",
        text: `🚀 GAN Build started\nSession: ${result.childSessionKey}`,
      }],
    };
  },
});
```

## Testing

```bash
# List agents
openclaw agents list

# List plugins
openclaw plugins list

# Test command
openclaw agent --agent main --message "/gan_build test"
```

## Troubleshooting

### Agent not found
```bash
openclaw agents add <name> --workspace "~/.openclaw/workspace-<name>"
```

### Command not recognized
```bash
openclaw plugins list | grep ecc
openclaw gateway restart
```

## Documentation

- [Integration Guide](./docs/integration-guide.md) - Full integration documentation
- [Plugin Source](./plugin/index.ts) - 86 commands implementation
- [Agent Script](./agents/create-agents.sh) - Automated agent creation

## Contributing

To add new commands:

1. Create `commands/my-command.md`
2. Add to `plugin/index.ts`:
   ```typescript
   api.registerCommand({ name: "my_command", ... })
   ```
3. Test: `/my_command`

## Related

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [ECC Main Documentation](../README.md)
