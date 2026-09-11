/**
 * Fallback policy — declarative fallback chains for model routing.
 *
 * Clean-room reimplementation of the upstream OmniRoute fallback policy
 * (src/domain/fallbackPolicy.ts), kept in-memory only (no SQLite here).
 *
 * When a primary provider is unavailable, the pipeline resolves alternative
 * providers in priority order (lower priority number = tried first).
 */

import type { FallbackEntry, ProviderId, Tier } from "../types.js";

/** Default tier order used when auto-building a chain (best -> free). */
export const TIER_ORDER: Tier[] = ["subscription", "api", "cheap", "free"];

const chains = new Map<string, FallbackEntry[]>();

/** Register (or replace) a fallback chain for a model. */
export function registerFallback(model: string, chain: FallbackEntry[]): void {
  const sorted = chain
    .map((e) => ({
      provider: e.provider,
      priority: e.priority ?? 0,
      enabled: e.enabled ?? true,
    }))
    .sort((a, b) => a.priority - b.priority);
  chains.set(model, sorted);
}

/**
 * Resolve the fallback chain for a model, excluding providers already tried.
 * Returns only enabled entries, in priority order.
 */
export function resolveFallback(
  model: string,
  excludeProviders: ProviderId[] = [],
): FallbackEntry[] {
  const chain = chains.get(model) ?? [];
  const excluded = new Set(excludeProviders);
  return chain.filter((e) => e.enabled && !excluded.has(e.provider));
}

export function deleteFallback(model: string): void {
  chains.delete(model);
}

export function clearFallbacks(): void {
  chains.clear();
}

export function allFallbacks(): Record<string, FallbackEntry[]> {
  return Object.fromEntries(chains);
}
