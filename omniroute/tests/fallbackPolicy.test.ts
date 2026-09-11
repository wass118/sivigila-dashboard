import { test } from "node:test";
import assert from "node:assert/strict";
import {
  registerFallback,
  resolveFallback,
  clearFallbacks,
} from "../src/domain/fallbackPolicy.js";

test("resolves chain sorted by priority", () => {
  clearFallbacks();
  registerFallback("gpt-4o", [
    { provider: "gemini", priority: 2, enabled: true },
    { provider: "anthropic", priority: 1, enabled: true },
  ]);
  assert.deepEqual(
    resolveFallback("gpt-4o").map((e) => e.provider),
    ["anthropic", "gemini"],
  );
});

test("excludes disabled entries and excluded providers", () => {
  clearFallbacks();
  registerFallback("gpt-4o", [
    { provider: "anthropic", priority: 0, enabled: false },
    { provider: "gemini", priority: 1, enabled: true },
    { provider: "groq", priority: 2, enabled: true },
  ]);
  assert.deepEqual(
    resolveFallback("gpt-4o", ["groq"]).map((e) => e.provider),
    ["gemini"],
  );
});

test("unknown model yields an empty chain", () => {
  clearFallbacks();
  assert.deepEqual(resolveFallback("nope"), []);
});
