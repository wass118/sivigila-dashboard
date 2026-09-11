/**
 * Adapter for OpenAI-compatible chat APIs.
 *
 * Covers OpenAI itself plus aggregators/clones that speak the same
 * /v1/chat/completions contract: OpenRouter, Groq, DeepSeek, Mistral.
 */

import {
  ProviderError,
  type ChatCompletionRequest,
  type ChatCompletionResponse,
} from "../types.js";
import type { ChatOptions, ProviderAdapter } from "./base.js";
import type { ProviderConnection } from "../types.js";

export class OpenAICompatibleAdapter implements ProviderAdapter {
  constructor(public readonly connection: ProviderConnection) {}

  async chat(
    req: ChatCompletionRequest,
    opts: ChatOptions,
  ): Promise<ChatCompletionResponse> {
    const url = `${this.connection.baseUrl.replace(/\/$/, "")}/chat/completions`;
    const body = {
      model: opts.upstreamModel,
      messages: req.messages,
      temperature: req.temperature,
      max_tokens: req.max_tokens,
      top_p: req.top_p,
      stop: req.stop,
      stream: false,
    };

    let res: Response;
    try {
      res = await fetch(url, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${this.connection.apiKey ?? ""}`,
        },
        body: JSON.stringify(body),
        signal: opts.signal,
      });
    } catch (err) {
      // Network-level failure: always retryable.
      throw new ProviderError(
        `network error contacting ${this.connection.provider}: ${(err as Error).message}`,
        true,
      );
    }

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new ProviderError(
        `${this.connection.provider} returned ${res.status}: ${text.slice(0, 300)}`,
        isRetryableStatus(res.status),
        res.status,
      );
    }

    const data = (await res.json()) as ChatCompletionResponse;
    return data;
  }
}

/**
 * Whether a failed status is worth trying another provider for.
 * 401/403 (this provider's key/config) and 408/409/429 + any 5xx
 * (transient/overload) are retryable; 400/404/422 mean the request itself
 * is bad, so falling back would only waste other providers.
 */
export function isRetryableStatus(status: number): boolean {
  return (
    status === 401 ||
    status === 403 ||
    status === 408 ||
    status === 409 ||
    status === 429 ||
    status >= 500
  );
}
