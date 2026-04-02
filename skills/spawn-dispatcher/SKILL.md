---
name: spawn-dispatcher
description: "收到模糊任务请求时，spawn dispatcher agent 来分析意图并分发。Use when: 用户请求模糊（如「做个应用」「检查代码」），需要专业分发。NOT for: 明确具体的请求。"
metadata:
  { "openclaw": { "emoji": "🎯" } }
---

# Spawn Dispatcher Skill

主 Agent 收到模糊任务请求时，spawn dispatcher agent 处理。

## ⚠️ 强制执行规则

**一旦触发此 skill，必须执行 spawn dispatcher agent。**

不允许：跳过、返回 NO_REPLY、或说「不需要执行」。

触发条件：
- skill 被 read（即此 skill 被加载）
- 用户请求匹配 When to Use 的场景

执行动作：
```
sessions_spawn(agentId: "dispatcher", task: "用户请求：[原始请求内容]")
```

---

## When to Use

此 skill 只有手动触发时才执行。

触发方式：用户说「spawn dispatcher」或类似指令。

**没有其他判断条件。触发即执行。**

## How to Use

收到模糊请求时，spawn dispatcher agent：

```
sessions_spawn(
  agentId: "dispatcher",
  task: "用户请求：[原始请求内容]"
)
```

Dispatcher agent 会：
1. 分析意图
2. 选择合适的执行路径
3. 返回结果给你

你只需要等待 dispatcher 返回结果，然后转给用户。

## Example

**用户**: 「帮我做个待办应用」

**你**: spawn dispatcher
```
sessions_spawn(agentId: "dispatcher", task: "用户请求：帮我做个待办应用")
```

**Dispatcher**: 分析 → 执行 → 返回结果

**你**: 把结果发给用户