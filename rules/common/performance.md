# Performance Optimization

## Model Selection Strategy

**Haiku 4.5** (90% of Sonnet capability, 3x cost savings):
- Lightweight agents with frequent invocation
- Pair programming and code generation
- Worker agents in multi-agent systems

**Sonnet 4.6** (Best coding model):
- Main development work
- Orchestrating multi-agent workflows
- Complex coding tasks

**Opus 4.5** (Deepest reasoning):
- Complex architectural decisions
- Maximum reasoning requirements
- Research and analysis tasks

## Context Window Management

Avoid last 20% of context window for:
- Large-scale refactoring
- Feature implementation spanning multiple files
- Debugging complex interactions

Lower context sensitivity tasks:
- Single-file edits
- Independent utility creation
- Documentation updates
- Simple bug fixes

## Extended Thinking

Control extended thinking via:
- **Per-message**: Send `/think:<level>` or `/t <level>` (e.g. `/think:high`, `/t off`)
- **Default level**: Set `agents.defaults.thinkingDefault` in `~/.openclaw/openclaw.json`
- **Supported levels**: `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `adaptive`

For complex tasks requiring deep reasoning:
1. Set thinking level to `high` or `xhigh`
2. Use multiple critique rounds for thorough analysis
3. Use split role sub-agents for diverse perspectives

## Build Troubleshooting

If build fails:
1. Use **build-error-resolver** agent
2. Analyze error messages
3. Fix incrementally
4. Verify after each fix
