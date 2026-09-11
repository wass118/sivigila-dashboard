/**
 * Model registry — maps canonical model ids to a provider, tier and cost.
 *
 * In upstream OmniRoute this is backed by a live catalog of 356 providers.
 * Here it is a small static table covering the MVP adapters, enough to
 * exercise routing, tiering and cost-optimized selection.
 */

import type { ModelInfo, ProviderId, Tier } from "../types.js";

const MODELS: ModelInfo[] = [
  // OpenAI
  { id: "gpt-4o", provider: "openai", tier: "api", inputCostPer1M: 2.5, outputCostPer1M: 10 },
  { id: "gpt-4o-mini", provider: "openai", tier: "cheap", inputCostPer1M: 0.15, outputCostPer1M: 0.6 },
  // Anthropic
  { id: "claude-3-5-sonnet", provider: "anthropic", upstreamId: "claude-3-5-sonnet-latest", tier: "api", inputCostPer1M: 3, outputCostPer1M: 15 },
  { id: "claude-3-5-haiku", provider: "anthropic", upstreamId: "claude-3-5-haiku-latest", tier: "cheap", inputCostPer1M: 0.8, outputCostPer1M: 4 },
  // Google Gemini
  { id: "gemini-1.5-pro", provider: "gemini", tier: "api", inputCostPer1M: 1.25, outputCostPer1M: 5 },
  { id: "gemini-1.5-flash", provider: "gemini", tier: "cheap", inputCostPer1M: 0.075, outputCostPer1M: 0.3 },
  // Groq (free/fast tier for open models)
  { id: "llama-3.3-70b", provider: "groq", upstreamId: "llama-3.3-70b-versatile", tier: "free", inputCostPer1M: 0, outputCostPer1M: 0 },
  // DeepSeek
  { id: "deepseek-chat", provider: "deepseek", tier: "cheap", inputCostPer1M: 0.27, outputCostPer1M: 1.1 },
  // Mistral
  { id: "mistral-small", provider: "mistral", upstreamId: "mistral-small-latest", tier: "cheap", inputCostPer1M: 0.2, outputCostPer1M: 0.6 },
  // OpenRouter (aggregator, treated as a single provider here)
  { id: "openrouter/auto", provider: "openrouter", tier: "api", inputCostPer1M: 0, outputCostPer1M: 0 },
];

const byId = new Map<string, ModelInfo>(MODELS.map((m) => [m.id, m]));

export function listModels(): ModelInfo[] {
  return [...MODELS];
}

export function getModel(id: string): ModelInfo | undefined {
  return byId.get(id);
}

export function modelsByProvider(provider: ProviderId): ModelInfo[] {
  return MODELS.filter((m) => m.provider === provider);
}

export function modelsByTier(tier: Tier): ModelInfo[] {
  return MODELS.filter((m) => m.tier === tier);
}

/** Upstream id to send to the provider API (falls back to the canonical id). */
export function upstreamModelId(info: ModelInfo): string {
  return info.upstreamId ?? info.id;
}
