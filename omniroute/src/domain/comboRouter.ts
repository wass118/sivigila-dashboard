/**
 * Combo router — selects an ordered list of candidate models from a combo,
 * according to the combo's strategy.
 *
 * Mirrors upstream OmniRoute Combo strategies:
 *   priority | weighted | round-robin | random | least-used | cost-optimized
 *
 * The router returns the FULL ordered candidate list (best first) rather than
 * a single pick, so the pipeline can fall through the list on failure.
 */

import type { Combo, ComboModel } from "../types.js";
import { getModel } from "./modelRegistry.js";

/** Per-combo mutable state (round-robin cursor, usage counters). */
interface ComboState {
  rrCursor: number;
  usage: Map<string, number>;
}

const state = new Map<string, ComboState>();

function stateFor(combo: Combo): ComboState {
  let s = state.get(combo.id);
  if (!s) {
    s = { rrCursor: 0, usage: new Map() };
    state.set(combo.id, s);
  }
  return s;
}

/** Deterministic RNG hook so tests can be stable; defaults to Math.random. */
export type Rng = () => number;

export function selectOrder(
  combo: Combo,
  rng: Rng = Math.random,
): ComboModel[] {
  const models = combo.models.filter((m) => getModel(m.model));
  if (models.length === 0) return [];

  switch (combo.strategy) {
    case "priority":
      // Declared order is the priority order.
      return [...models];

    case "round-robin": {
      const s = stateFor(combo);
      const start = s.rrCursor % models.length;
      s.rrCursor = (s.rrCursor + 1) % models.length;
      return rotate(models, start);
    }

    case "random":
      return shuffle(models, rng);

    case "weighted":
      return weightedOrder(models, rng);

    case "least-used": {
      const s = stateFor(combo);
      return [...models].sort(
        (a, b) => (s.usage.get(a.model) ?? 0) - (s.usage.get(b.model) ?? 0),
      );
    }

    case "cost-optimized":
      return [...models].sort((a, b) => costOf(a) - costOf(b));

    default:
      return [...models];
  }
}

/** Record that a model was actually used (feeds least-used strategy). */
export function recordUsage(combo: Combo, model: string): void {
  const s = stateFor(combo);
  s.usage.set(model, (s.usage.get(model) ?? 0) + 1);
}

/** Reset in-memory routing state (mainly for tests). */
export function resetState(): void {
  state.clear();
}

// --- helpers ---------------------------------------------------------------

function costOf(m: ComboModel): number {
  const info = getModel(m.model);
  if (!info) return Number.POSITIVE_INFINITY;
  // Blended cost assuming a typical 3:1 input:output ratio.
  return (info.inputCostPer1M * 3 + info.outputCostPer1M) / 4;
}

function rotate<T>(arr: T[], start: number): T[] {
  return [...arr.slice(start), ...arr.slice(0, start)];
}

function shuffle<T>(arr: T[], rng: Rng): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j]!, a[i]!];
  }
  return a;
}

/**
 * Weighted order: repeatedly draw from the remaining pool with probability
 * proportional to weight, producing a full ordering (not just one pick).
 */
function weightedOrder(models: ComboModel[], rng: Rng): ComboModel[] {
  const pool = models.map((m) => ({ m, w: Math.max(0, m.weight ?? 1) }));
  const out: ComboModel[] = [];
  while (pool.length > 0) {
    const total = pool.reduce((sum, p) => sum + p.w, 0);
    if (total <= 0) {
      // All remaining weights zero: append in declared order.
      out.push(...pool.map((p) => p.m));
      break;
    }
    let r = rng() * total;
    let idx = 0;
    for (let i = 0; i < pool.length; i++) {
      r -= pool[i]!.w;
      if (r <= 0) {
        idx = i;
        break;
      }
    }
    out.push(pool[idx]!.m);
    pool.splice(idx, 1);
  }
  return out;
}
