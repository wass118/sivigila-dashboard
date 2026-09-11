import { test } from "node:test";
import assert from "node:assert/strict";
import { selectOrder, resetState, recordUsage } from "../src/domain/comboRouter.js";
import type { Combo } from "../src/types.js";

function combo(strategy: Combo["strategy"], models: Combo["models"]): Combo {
  return { id: `c-${strategy}`, name: strategy, strategy, isActive: true, models };
}

test("priority keeps declared order", () => {
  resetState();
  const c = combo("priority", [{ model: "gpt-4o" }, { model: "claude-3-5-sonnet" }]);
  assert.deepEqual(
    selectOrder(c).map((m) => m.model),
    ["gpt-4o", "claude-3-5-sonnet"],
  );
});

test("cost-optimized orders cheapest first", () => {
  resetState();
  const c = combo("cost-optimized", [
    { model: "gpt-4o" }, // pricey
    { model: "gemini-1.5-flash" }, // cheapest
    { model: "gpt-4o-mini" },
  ]);
  assert.equal(selectOrder(c)[0]!.model, "gemini-1.5-flash");
});

test("round-robin advances the primary each call", () => {
  resetState();
  const c = combo("round-robin", [
    { model: "gpt-4o" },
    { model: "claude-3-5-sonnet" },
    { model: "gemini-1.5-pro" },
  ]);
  assert.equal(selectOrder(c)[0]!.model, "gpt-4o");
  assert.equal(selectOrder(c)[0]!.model, "claude-3-5-sonnet");
  assert.equal(selectOrder(c)[0]!.model, "gemini-1.5-pro");
  assert.equal(selectOrder(c)[0]!.model, "gpt-4o");
});

test("least-used prefers the model used fewer times", () => {
  resetState();
  const c = combo("least-used", [{ model: "gpt-4o" }, { model: "gemini-1.5-pro" }]);
  recordUsage(c, "gpt-4o");
  recordUsage(c, "gpt-4o");
  assert.equal(selectOrder(c)[0]!.model, "gemini-1.5-pro");
});

test("weighted returns a full ordering of all models", () => {
  resetState();
  const c = combo("weighted", [
    { model: "gpt-4o", weight: 5 },
    { model: "claude-3-5-sonnet", weight: 1 },
  ]);
  // Deterministic rng = 0 always draws the first slice boundary.
  const order = selectOrder(c, () => 0).map((m) => m.model);
  assert.equal(order.length, 2);
  assert.deepEqual([...order].sort(), ["claude-3-5-sonnet", "gpt-4o"]);
});

test("unknown models are filtered out", () => {
  resetState();
  const c = combo("priority", [{ model: "does-not-exist" }, { model: "gpt-4o" }]);
  assert.deepEqual(selectOrder(c).map((m) => m.model), ["gpt-4o"]);
});
