/**
 * Adapter for the Anthropic Messages API.
 *
 * Translates OpenAI chat requests to Anthropic's /v1/messages format and the
 * response back to the OpenAI chat completion shape.
 */

import {
  ProviderError,
  type ChatCompletionRequest,
  type ChatCompletionResponse,
  type ChatMessage,
} from "../types.js";
import { estimateTokens, type ChatOptions, type ProviderAdapter } from "./base.js";
import type { ProviderConnection } from "../types.js";
import { isRetryableStatus } from "./openaiCompatible.js";

interface AnthropicResponse {
  content?: Array<{ type: string; text?: string }>;
  stop_reason?: string;
  usage?: { input_tokens?: number; output_tokens?: number };
}

export class AnthropicAdapter implements ProviderAdapter {
  constructor(public readonly connection: ProviderConnection) {}

  async chat(
    req: ChatCompletionRequest,
    opts: ChatOptions,
  ): Promise<ChatCompletionResponse> {
    const url = `${this.connection.baseUrl.replace(/\/$/, "")}/messages`;

    // Anthropic takes `system` separately and only user/assistant turns.
    const system = req.messages
      .filter((m) => m.role === "system")
      .map((m) => m.content)
      .join("\n\n");
    const messages = req.messages
      .filter((m) => m.role === "user" || m.role === "assistant")
      .map((m) => ({ role: m.role, content: m.content }));

    const body = {
      model: opts.upstreamModel,
      system: system || undefined,
      messages,
      max_tokens: req.max_tokens ?? 1024,
      temperature: req.temperature,
      top_p: req.top_p,
      stop_sequences: normalizeStop(req.stop),
    };

    let res: Response;
    try {
      res = await fetch(url, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-api-key": this.connection.apiKey ?? "",
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify(body),
        signal: opts.signal,
      });
    } catch (err) {
      throw new ProviderError(
        `network error contacting anthropic: ${(err as Error).message}`,
        true,
      );
    }

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new ProviderError(
        `anthropic returned ${res.status}: ${text.slice(0, 300)}`,
        isRetryableStatus(res.status),
        res.status,
      );
    }

    const data = (await res.json()) as AnthropicResponse;
    const content = (data.content ?? [])
      .filter((c) => c.type === "text")
      .map((c) => c.text ?? "")
      .join("");

    const message: ChatMessage = { role: "assistant", content };
    const promptTokens =
      data.usage?.input_tokens ??
      estimateTokens(req.messages.map((m) => m.content).join(" "));
    const completionTokens =
      data.usage?.output_tokens ?? estimateTokens(content);

    return {
      id: `chatcmpl-${Date.now().toString(36)}`,
      object: "chat.completion",
      created: Math.floor(Date.now() / 1000),
      model: req.model,
      choices: [
        {
          index: 0,
          message,
          finish_reason: mapStopReason(data.stop_reason),
        },
      ],
      usage: {
        prompt_tokens: promptTokens,
        completion_tokens: completionTokens,
        total_tokens: promptTokens + completionTokens,
      },
    };
  }
}

function normalizeStop(stop?: string | string[]): string[] | undefined {
  if (!stop) return undefined;
  return Array.isArray(stop) ? stop : [stop];
}

function mapStopReason(reason?: string): string {
  switch (reason) {
    case "end_turn":
    case "stop_sequence":
      return "stop";
    case "max_tokens":
      return "length";
    default:
      return "stop";
  }
}
