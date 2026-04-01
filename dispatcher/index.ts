import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
import type { PluginCommandContext } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: "dispatcher",
  name: "Dispatcher",
  description: "命令分拣中心 - 理解用户意图并调用正确的工具",
  async register(api) {
    // 注册 /dispatch 命令
    api.registerCommand({
      name: "dispatch",
      description: "理解用户意图并调用正确的工具",
      acceptsArgs: true,
      handler: async (ctx: PluginCommandContext) => {
        const input = ctx.args || ctx.commandBody;
        
        // dispatcher agent 自己理解用户意图，选择工具
        // 这里不需要硬编码映射，让 LLM 来决定
        const runResult = await api.runtime.subagent.run({
          sessionKey: "dispatcher",
          message: `请理解用户意图并调用正确的工具：${input}`,
          deliver: false
        });
        
        // 等待子代理完成并获取结果
        const waitResult = await api.runtime.subagent.waitForRun({
          runId: runResult.runId,
          timeoutMs: 300000
        });
        
        if (waitResult.status === "error") {
          return { text: `处理失败：${waitResult.error}` };
        }
        if (waitResult.status === "timeout") {
          return { text: "处理超时，请稍后重试" };
        }
        
        // 获取子代理的消息
        const messages = await api.runtime.subagent.getSessionMessages({
          sessionKey: "dispatcher",
          limit: 10
        });
        
        const lastMessage: any = messages.messages[messages.messages.length - 1];
        const responseText = (lastMessage?.content as string) || `已处理：${input}`;
        
        return { text: responseText };
      }
    });
  }
});
