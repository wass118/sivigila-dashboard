/**
 * Provider adapter contract.
 *
 * Every adapter takes an OpenAI-shaped request and returns an OpenAI-shaped
 * response, translating to/from the upstream wire format internally. This is
 * what lets OmniRoute expose "one endpoint" across heterogeneous providers.
 */

import type {
  ChatCompletionRequest,
  ChatCompletionResponse,
  ProviderConnection,
} from "../types.js";

export interface ChatOptions {
  signal?: AbortSignal;
  /** Upstream model id to send (may differ from the client-facing id). */
  upstreamModel: string;
}

export interface ProviderAdapter {
  readonly connection: ProviderConnection;
  chat(
    req: ChatCompletionRequest,
    opts: ChatOptions,
  ): Promise<ChatCompletionResponse>;
}

/** Rough token estimate used when a provider omits usage. ~4 chars/token. */
export function estimateTokens(text: string): number {
  return Math.max(1, Math.ceil(text.length / 4));
}
