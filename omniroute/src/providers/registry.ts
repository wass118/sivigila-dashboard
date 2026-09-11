/**
 * Adapter registry — instantiates the right adapter for each connection and
 * exposes lookup by provider id.
 */

import type { ProviderAdapter } from "./base.js";
import type { ProviderConnection, ProviderId } from "../types.js";
import { OpenAICompatibleAdapter } from "./openaiCompatible.js";
import { AnthropicAdapter } from "./anthropic.js";
import { GeminiAdapter } from "./gemini.js";

export function buildAdapter(conn: ProviderConnection): ProviderAdapter {
  switch (conn.kind) {
    case "openai-compatible":
      return new OpenAICompatibleAdapter(conn);
    case "anthropic":
      return new AnthropicAdapter(conn);
    case "gemini":
      return new GeminiAdapter(conn);
    default: {
      const _exhaustive: never = conn.kind;
      throw new Error(`unknown provider kind: ${String(_exhaustive)}`);
    }
  }
}

export class AdapterRegistry {
  private readonly byProvider = new Map<ProviderId, ProviderAdapter>();

  constructor(connections: ProviderConnection[]) {
    for (const conn of connections) {
      if (conn.isActive) this.byProvider.set(conn.provider, buildAdapter(conn));
    }
  }

  get(provider: ProviderId): ProviderAdapter | undefined {
    return this.byProvider.get(provider);
  }

  has(provider: ProviderId): boolean {
    return this.byProvider.has(provider);
  }

  providers(): ProviderId[] {
    return [...this.byProvider.keys()];
  }
}
