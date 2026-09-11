/**
 * Configuration — builds provider connections from environment variables.
 *
 * A connection is created only when its API key is present, so an operator
 * enables providers simply by setting keys. Default base URLs point at each
 * provider's public API and can be overridden per provider.
 */

import type { ProviderConnection, ProviderId, ProviderKind, Tier } from "./types.js";

interface ProviderTemplate {
  provider: ProviderId;
  kind: ProviderKind;
  name: string;
  keyEnv: string;
  baseUrlEnv: string;
  defaultBaseUrl: string;
  tier: Tier;
}

const TEMPLATES: ProviderTemplate[] = [
  {
    provider: "openai",
    kind: "openai-compatible",
    name: "OpenAI",
    keyEnv: "OPENAI_API_KEY",
    baseUrlEnv: "OPENAI_BASE_URL",
    defaultBaseUrl: "https://api.openai.com/v1",
    tier: "api",
  },
  {
    provider: "anthropic",
    kind: "anthropic",
    name: "Anthropic",
    keyEnv: "ANTHROPIC_API_KEY",
    baseUrlEnv: "ANTHROPIC_BASE_URL",
    defaultBaseUrl: "https://api.anthropic.com/v1",
    tier: "api",
  },
  {
    provider: "gemini",
    kind: "gemini",
    name: "Google Gemini",
    keyEnv: "GEMINI_API_KEY",
    baseUrlEnv: "GEMINI_BASE_URL",
    defaultBaseUrl: "https://generativelanguage.googleapis.com/v1beta",
    tier: "api",
  },
  {
    provider: "groq",
    kind: "openai-compatible",
    name: "Groq",
    keyEnv: "GROQ_API_KEY",
    baseUrlEnv: "GROQ_BASE_URL",
    defaultBaseUrl: "https://api.groq.com/openai/v1",
    tier: "free",
  },
  {
    provider: "deepseek",
    kind: "openai-compatible",
    name: "DeepSeek",
    keyEnv: "DEEPSEEK_API_KEY",
    baseUrlEnv: "DEEPSEEK_BASE_URL",
    defaultBaseUrl: "https://api.deepseek.com/v1",
    tier: "cheap",
  },
  {
    provider: "mistral",
    kind: "openai-compatible",
    name: "Mistral",
    keyEnv: "MISTRAL_API_KEY",
    baseUrlEnv: "MISTRAL_BASE_URL",
    defaultBaseUrl: "https://api.mistral.ai/v1",
    tier: "cheap",
  },
  {
    provider: "openrouter",
    kind: "openai-compatible",
    name: "OpenRouter",
    keyEnv: "OPENROUTER_API_KEY",
    baseUrlEnv: "OPENROUTER_BASE_URL",
    defaultBaseUrl: "https://openrouter.ai/api/v1",
    tier: "api",
  },
];

export interface GatewayConfig {
  port: number;
  /** Optional bearer token clients must present to use the gateway. */
  gatewayApiKey?: string;
  connections: ProviderConnection[];
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): GatewayConfig {
  const connections: ProviderConnection[] = [];
  for (const t of TEMPLATES) {
    const apiKey = env[t.keyEnv];
    if (!apiKey) continue;
    connections.push({
      id: t.provider,
      provider: t.provider,
      kind: t.kind,
      name: t.name,
      isActive: true,
      apiKey,
      baseUrl: env[t.baseUrlEnv] ?? t.defaultBaseUrl,
      tier: t.tier,
    });
  }

  return {
    port: Number(env.OMNIROUTE_PORT ?? env.PORT ?? 8787),
    gatewayApiKey: env.OMNIROUTE_API_KEY,
    connections,
  };
}

/** List provider ids that could be configured, for docs/CLI output. */
export function knownProviders(): ProviderId[] {
  return TEMPLATES.map((t) => t.provider);
}
