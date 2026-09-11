/**
 * Adapter for Google's Gemini generateContent API.
 *
 * Translates OpenAI chat requests to Gemini's contents/parts format and back
 * to the OpenAI chat completion shape.
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

interface GeminiResponse {
  candidates?: Array<{
    content?: { parts?: Array<{ text?: string }> };
    finishReason?: string;
  }>;
  usageMetadata?: {
    promptTokenCount?: number;
    candidatesTokenCount?: number;
  };
}

export class GeminiAdapter implements ProviderAdapter {
  constructor(public readonly connection: ProviderConnection) {}

  async chat(
    req: ChatCompletionRequest,
    opts: ChatOptions,
  ): Promise<ChatCompletionResponse> {
    const base = this.connection.baseUrl.replace(/\/$/, "");
    const url = `${base}/models/${opts.upstreamModel}:generateContent?key=${encodeURIComponent(this.connection.apiKey ?? "")}`;

    const systemText = req.messages
      .filter((m) => m.role === "system")
      .map((m) => m.content)
      .join("\n\n");
    const contents = req.messages
      .filter((m) => m.role === "user" || m.role === "assistant")
      .map((m) => ({
        role: m.role === "assistant" ? "model" : "user",
        parts: [{ text: m.content }],
      }));

    const body = {
      systemInstruction: systemText
        ? { parts: [{ text: systemText }] }
        : undefined,
      contents,
      generationConfig: {
        temperature: req.temperature,
        maxOutputTokens: req.max_tokens,
        topP: req.top_p,
        stopSequences: req.stop
          ? Array.isArray(req.stop)
            ? req.stop
            : [req.stop]
          : undefined,
      },
    };

    let res: Response;
    try {
      res = await fetch(url, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(body),
        signal: opts.signal,
      });
    } catch (err) {
      throw new ProviderError(
        `network error contacting gemini: ${(err as Error).message}`,
        true,
      );
    }

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new ProviderError(
        `gemini returned ${res.status}: ${text.slice(0, 300)}`,
        isRetryableStatus(res.status),
        res.status,
      );
    }

    const data = (await res.json()) as GeminiResponse;
    const candidate = data.candidates?.[0];
    const content = (candidate?.content?.parts ?? [])
      .map((p) => p.text ?? "")
      .join("");

    const message: ChatMessage = { role: "assistant", content };
    const promptTokens =
      data.usageMetadata?.promptTokenCount ??
      estimateTokens(req.messages.map((m) => m.content).join(" "));
    const completionTokens =
      data.usageMetadata?.candidatesTokenCount ?? estimateTokens(content);

    return {
      id: `chatcmpl-${Date.now().toString(36)}`,
      object: "chat.completion",
      created: Math.floor(Date.now() / 1000),
      model: req.model,
      choices: [
        {
          index: 0,
          message,
          finish_reason: candidate?.finishReason === "MAX_TOKENS" ? "length" : "stop",
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
