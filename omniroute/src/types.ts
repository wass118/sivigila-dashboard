/**
 * Core domain types for the OmniRoute MVP.
 *
 * Modeled after the upstream OmniRoute domain layer
 * (ProviderConnection, Combo, FallbackChain), reduced to the subset
 * needed for a working OpenAI-compatible routing gateway.
 */

/** Provider families supported by the MVP adapters. */
export type ProviderId =
  | "openai"
  | "anthropic"
  | "gemini"
  | "openrouter"
  | "groq"
  | "deepseek"
  | "mistral";

/** How a provider adapter talks to its upstream API. */
export type ProviderKind = "openai-compatible" | "anthropic" | "gemini";

/** Pricing tier, used by tiered fallback (Subscription -> API -> Cheap -> Free). */
export type Tier = "subscription" | "api" | "cheap" | "free";

/** Selection strategies for a combo (mirrors upstream Combo.strategy). */
export type ComboStrategy =
  | "priority"
  | "weighted"
  | "round-robin"
  | "random"
  | "least-used"
  | "cost-optimized";

/** A configured connection to a provider. */
export interface ProviderConnection {
  id: string;
  provider: ProviderId;
  kind: ProviderKind;
  name: string;
  isActive: boolean;
  apiKey?: string;
  baseUrl: string;
  tier: Tier;
}

/** A model entry inside a combo. */
export interface ComboModel {
  model: string;
  weight?: number;
}

/** A named routing group over several models. */
export interface Combo {
  id: string;
  name: string;
  strategy: ComboStrategy;
  models: ComboModel[];
  isActive: boolean;
}

/** One step in a resolved fallback chain. */
export interface FallbackEntry {
  provider: ProviderId;
  priority: number;
  enabled: boolean;
}

/** Metadata about a known model. */
export interface ModelInfo {
  /** Canonical model id as exposed to clients, e.g. "gpt-4o-mini". */
  id: string;
  provider: ProviderId;
  /** Upstream model id if it differs from the canonical id. */
  upstreamId?: string;
  tier: Tier;
  /** USD per 1M input / output tokens, used by cost-optimized routing. */
  inputCostPer1M: number;
  outputCostPer1M: number;
}

/** OpenAI-compatible chat message. */
export interface ChatMessage {
  role: "system" | "user" | "assistant" | "tool";
  content: string;
  name?: string;
}

/** Subset of the OpenAI chat completion request the gateway understands. */
export interface ChatCompletionRequest {
  model: string;
  messages: ChatMessage[];
  temperature?: number;
  max_tokens?: number;
  top_p?: number;
  stop?: string | string[];
  /** OmniRoute extension: force a specific combo by id/name. */
  combo?: string;
  [key: string]: unknown;
}

/** OpenAI-compatible (non-streaming) chat completion response. */
export interface ChatCompletionResponse {
  id: string;
  object: "chat.completion";
  created: number;
  model: string;
  choices: Array<{
    index: number;
    message: ChatMessage;
    finish_reason: string;
  }>;
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
  /** OmniRoute extension: which route actually served the request. */
  omniroute?: {
    provider: ProviderId;
    model: string;
    tier: Tier;
    attempts: RouteAttempt[];
  };
}

/** Record of a single attempt in the routing pipeline. */
export interface RouteAttempt {
  provider: ProviderId;
  model: string;
  ok: boolean;
  error?: string;
  latencyMs: number;
}

/** Error raised by adapters so the pipeline can decide on fallback. */
export class ProviderError extends Error {
  constructor(
    message: string,
    /** true when trying another provider might succeed (5xx, 429, network). */
    public readonly retryable: boolean,
    public readonly status?: number,
  ) {
    super(message);
    this.name = "ProviderError";
  }
}
