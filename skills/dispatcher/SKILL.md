---
name: dispatcher
description: "理解用户意图并调用正确的 ECC 工具。Use when: 用户输入模糊的自然语言请求，需要分析意图并选择合适的工具（如 gan_build, code_review, e2e 等）。NOT for: 已有明确工具名的直接调用。"
metadata:
  {
    "openclaw":
      {
        "emoji": "🎯",
        "requires": { "agents": ["dispatcher"] },
      },
  }
---

# Dispatcher Skill

理解用户意图并调用正确的 ECC 工具。

## When to Use

✅ **USE this skill when:**

- 用户输入模糊的自然语言请求（如"帮我做一个待办应用"）
- 需要分析用户真正想要什么
- 不确定该用哪个 ECC 工具
- 用户请求涉及多个步骤，需要规划

❌ **DON'T use this skill when:**

- 用户已经明确指定工具（如"运行 gan_build"）
- 简单的问答任务
- 不需要调用 ECC 工具的场景

## How to Use

### 1. 调用 Dispatcher Agent

```bash
# 使用 sessions_spawn 调用 dispatcher agent
sessions_spawn --task="dispatcher，请处理：[用户原始请求]"
```

### 2. Dispatcher Agent 的工作流程

```
用户请求 → Dispatcher Agent 分析意图 → 选择最合适的 ECC tool → 调用 tool → 返回结果
```

### 3. 示例

**用户**: "帮我做一个待办应用"

**你**: 调用 dispatcher skill
```
dispatcher，请处理：帮我做一个待办应用
```

**Dispatcher Agent**: 分析后调用 `gan_build` tool
```
gan_build({ brief: "待办应用，支持添加/删除/标记完成" })
```

**结果**: 返回 GAN 构建流程的输出

## 可用的 ECC Tools

Dispatcher 可以调用的工具包括（但不限于）：

### 高优先级
- `gan_build` - GAN 式开发循环
- `gan_design` - GAN 设计循环
- `code_review` - 代码审查
- `e2e` - 端到端测试
- `tdd` - TDD 开发
- `refactor_clean` - 代码重构
- `security_scan` - 安全扫描
- `performance_audit` - 性能审计

### 语言特定
- `cpp_build`, `go_build`, `kotlin_build`, `rust_build`
- `cpp_review`, `go_review`, `kotlin_review`, `rust_review`
- `python_test`, `java_test`, `kotlin_test`

### 其他工具
- `docs_lookup` - 文档查询
- `console_check` - console.log 检查
- `typecheck` - TypeScript 类型检查
- `database_review` - 数据库设计审查

## 注意事项

1. **Dispatcher Agent 是独立的** - 它有自己的 SOUL.md 和 workspace
2. **自动选择工具** - 不需要你手动映射，让 LLM 决定
3. **等待执行完成** - Dispatcher 会等待 tool 执行完并返回结果
4. **错误处理** - 如果 Dispatcher 失败，告知用户并重试或手动处理

## 直接调用 vs Dispatcher

| 场景 | 推荐方式 |
|------|---------|
| "帮我做个 XX" | ✅ Dispatcher |
| "运行 gan_build" | ✅ 直接调用 tool |
| 模糊需求 | ✅ Dispatcher |
| 明确工具名 | ✅ 直接调用 |
