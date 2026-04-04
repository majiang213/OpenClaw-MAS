declare const _default: {
    id: string;
    name: string;
    description: string;
    configSchema: import("openclaw/plugin-sdk/plugin-entry", { with: { "resolution-mode": "import" } }).OpenClawPluginConfigSchema;
    register: NonNullable<import("openclaw/plugin-sdk/plugin-entry", { with: { "resolution-mode": "import" } }).OpenClawPluginDefinition["register"]>;
} & Pick<import("openclaw/plugin-sdk/plugin-entry", { with: { "resolution-mode": "import" } }).OpenClawPluginDefinition, "kind">;
export default _default;
