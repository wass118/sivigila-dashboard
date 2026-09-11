/**
 * Gateway — wires config, adapters, combos and default fallback chains into a
 * ready-to-use set of pipeline dependencies.
 */

import type { GatewayConfig } from "./config.js";
import { AdapterRegistry } from "./providers/registry.js";
import { getCombo, seedDefaultCombos } from "./domain/comboStore.js";
import { registerFallback } from "./domain/fallbackPolicy.js";
import { listModels } from "./domain/modelRegistry.js";
import type { PipelineDeps } from "./pipeline.js";

export interface Gateway {
  config: GatewayConfig;
  registry: AdapterRegistry;
  deps: PipelineDeps;
}

export function createGateway(config: GatewayConfig): Gateway {
  const registry = new AdapterRegistry(config.connections);
  seedDefaultCombos();
  seedDefaultFallbacks();

  const deps: PipelineDeps = {
    getAdapter: (provider) => registry.get(provider),
    getCombo: (idOrName) => getCombo(idOrName),
  };

  return { config, registry, deps };
}

/**
 * Default fallback chains: for each model, fall back to same-tier siblings on
 * other providers, then down through cheaper tiers. Illustrative defaults;
 * an operator can override with registerFallback().
 */
function seedDefaultFallbacks(): void {
  const models = listModels();
  const tierRank: Record<string, number> = {
    subscription: 0,
    api: 1,
    cheap: 2,
    free: 3,
  };
  for (const m of models) {
    const chain = models
      .filter((other) => other.provider !== m.provider)
      .sort((a, b) => (tierRank[a.tier] ?? 9) - (tierRank[b.tier] ?? 9))
      .map((other, i) => ({ provider: other.provider, priority: i, enabled: true }));
    // Collapse to one entry per provider (chains are per-provider, not per-model).
    const seen = new Set<string>();
    const collapsed = chain.filter((e) => {
      if (seen.has(e.provider)) return false;
      seen.add(e.provider);
      return true;
    });
    registerFallback(m.id, collapsed);
  }
}
