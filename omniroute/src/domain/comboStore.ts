/**
 * Combo store — in-memory registry of routing combos, keyed by id and name.
 *
 * Upstream OmniRoute persists these in SQLite; here they live in memory and
 * can be seeded from a JSON file via OMNIROUTE_COMBOS.
 */

import type { Combo } from "../types.js";

const combos = new Map<string, Combo>();

export function registerCombo(combo: Combo): void {
  combos.set(combo.id, combo);
}

export function getCombo(idOrName: string): Combo | undefined {
  const byId = combos.get(idOrName);
  if (byId) return byId;
  for (const c of combos.values()) {
    if (c.name === idOrName) return c;
  }
  return undefined;
}

export function listCombos(): Combo[] {
  return [...combos.values()];
}

export function clearCombos(): void {
  combos.clear();
}

/** Seed a couple of illustrative combos so the gateway is useful out of the box. */
export function seedDefaultCombos(): void {
  registerCombo({
    id: "cheapest",
    name: "cheapest",
    strategy: "cost-optimized",
    isActive: true,
    models: [
      { model: "gpt-4o-mini" },
      { model: "gemini-1.5-flash" },
      { model: "claude-3-5-haiku" },
      { model: "deepseek-chat" },
    ],
  });
  registerCombo({
    id: "balanced",
    name: "balanced",
    strategy: "priority",
    isActive: true,
    models: [
      { model: "claude-3-5-sonnet" },
      { model: "gpt-4o" },
      { model: "gemini-1.5-pro" },
    ],
  });
  registerCombo({
    id: "spread",
    name: "spread",
    strategy: "weighted",
    isActive: true,
    models: [
      { model: "gpt-4o", weight: 3 },
      { model: "claude-3-5-sonnet", weight: 2 },
      { model: "gemini-1.5-pro", weight: 1 },
    ],
  });
}
