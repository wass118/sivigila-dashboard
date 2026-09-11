/**
 * Routing pipeline — the core of the gateway.
 *
 * Resolves an ordered list of candidate routes for a request, then executes
 * them in order, falling through to the next candidate whenever a provider
 * fails in a retryable way. This is OmniRoute's "one endpoint, auto fallback"
 * behavior in miniature.
 *
 * Route resolution supports three modes:
 *   1. combo   — req.combo names a registered combo; comboRouter orders it.
 *   2. auto    — model === "auto"; candidates span tiers (best -> free).
 *   3. explicit — a concrete model; primary + its fallback chain.
 */

import {
  ProviderError,
  type ChatCompletionRequest,
  type ChatCompletionResponse,
  type Combo,
  type ProviderId,
  type RouteAttempt,
  type Tier,
} from "./types.js";
import type { ProviderAdapter } from "./providers/base.js";
import {
  getModel,
  modelsByProvider,
  upstreamModelId,
  listModels,
} from "./domain/modelRegistry.js";
import { resolveFallback, TIER_ORDER } from "./domain/fallbackPolicy.js";
import { recordUsage, selectOrder, type Rng } from "./domain/comboRouter.js";

export interface Candidate {
  provider: ProviderId;
  /** Canonical model id. */
  model: string;
  tier: Tier;
}

export interface PipelineDeps {
  getAdapter(provider: ProviderId): ProviderAdapter | undefined;
  getCombo?(idOrName: string): Combo | undefined;
  rng?: Rng;
  now?: () => number;
}

export class NoRouteError extends Error {}
export class AllRoutesFailedError extends Error {
  constructor(
    message: string,
    public readonly attempts: RouteAttempt[],
  ) {
    super(message);
    this.name = "AllRoutesFailedError";
  }
}

/** Build the ordered candidate list for a request (no execution). */
export function resolveCandidates(
  req: ChatCompletionRequest,
  deps: PipelineDeps,
): Candidate[] {
  // Mode 1: explicit combo.
  if (req.combo && deps.getCombo) {
    const combo = deps.getCombo(req.combo);
    if (!combo || !combo.isActive) {
      throw new NoRouteError(`combo not found or inactive: ${req.combo}`);
    }
    const ordered = selectOrder(combo, deps.rng);
    return dedupe(
      ordered.flatMap((m) => {
        const info = getModel(m.model);
        return info ? [{ provider: info.provider, model: info.id, tier: info.tier }] : [];
      }),
    );
  }

  // Mode 2: auto — span tiers best -> free, cheapest first within a tier.
  if (req.model === "auto") {
    const ranked = [...listModels()].sort((a, b) => {
      const t = TIER_ORDER.indexOf(a.tier) - TIER_ORDER.indexOf(b.tier);
      if (t !== 0) return t;
      return blendedCost(a.inputCostPer1M, a.outputCostPer1M) -
        blendedCost(b.inputCostPer1M, b.outputCostPer1M);
    });
    return dedupe(
      ranked.map((m) => ({ provider: m.provider, model: m.id, tier: m.tier })),
    );
  }

  // Mode 3: explicit model + its fallback chain.
  const primary = getModel(req.model);
  if (!primary) {
    throw new NoRouteError(`unknown model: ${req.model}`);
  }
  const candidates: Candidate[] = [
    { provider: primary.provider, model: primary.id, tier: primary.tier },
  ];
  for (const entry of resolveFallback(req.model, [primary.provider])) {
    const model = pickModelForProvider(entry.provider, primary.tier);
    if (model) {
      candidates.push({ provider: entry.provider, model: model.id, tier: model.tier });
    }
  }
  return dedupe(candidates);
}

/** Resolve candidates, execute in order, and return the first success. */
export async function runPipeline(
  req: ChatCompletionRequest,
  deps: PipelineDeps,
): Promise<ChatCompletionResponse> {
  const now = deps.now ?? Date.now;
  const candidates = resolveCandidates(req, deps);
  if (candidates.length === 0) {
    throw new NoRouteError("no candidate routes for request");
  }

  const attempts: RouteAttempt[] = [];
  let lastError: unknown;

  for (const cand of candidates) {
    const adapter = deps.getAdapter(cand.provider);
    if (!adapter) {
      // Provider not configured; skip without counting as a hard failure.
      attempts.push({
        provider: cand.provider,
        model: cand.model,
        ok: false,
        error: "provider not configured",
        latencyMs: 0,
      });
      continue;
    }

    const info = getModel(cand.model);
    const upstreamModel = info ? upstreamModelId(info) : cand.model;
    const start = now();
    try {
      const res = await adapter.chat(req, { upstreamModel });
      attempts.push({
        provider: cand.provider,
        model: cand.model,
        ok: true,
        latencyMs: now() - start,
      });
      if (req.combo && deps.getCombo) {
        const combo = deps.getCombo(req.combo);
        if (combo) recordUsage(combo, cand.model);
      }
      return {
        ...res,
        model: cand.model,
        omniroute: {
          provider: cand.provider,
          model: cand.model,
          tier: cand.tier,
          attempts,
        },
      };
    } catch (err) {
      lastError = err;
      attempts.push({
        provider: cand.provider,
        model: cand.model,
        ok: false,
        error: err instanceof Error ? err.message : String(err),
        latencyMs: now() - start,
      });
      // Non-retryable errors (bad request) stop the chain immediately.
      if (err instanceof ProviderError && !err.retryable) {
        throw err;
      }
      // Otherwise fall through to the next candidate.
    }
  }

  throw new AllRoutesFailedError(
    `all ${attempts.length} route(s) failed: ${
      lastError instanceof Error ? lastError.message : String(lastError)
    }`,
    attempts,
  );
}

// --- helpers ---------------------------------------------------------------

function blendedCost(input: number, output: number): number {
  return (input * 3 + output) / 4;
}

function pickModelForProvider(provider: ProviderId, preferredTier: Tier) {
  const models = modelsByProvider(provider);
  if (models.length === 0) return undefined;
  return models.find((m) => m.tier === preferredTier) ?? models[0];
}

function dedupe(candidates: Candidate[]): Candidate[] {
  const seen = new Set<string>();
  const out: Candidate[] = [];
  for (const c of candidates) {
    const key = `${c.provider}:${c.model}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(c);
  }
  return out;
}
