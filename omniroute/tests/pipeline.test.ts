import { test } from "node:test";
import assert from "node:assert/strict";
import {
  runPipeline,
  resolveCandidates,
  AllRoutesFailedError,
  NoRouteError,
  type PipelineDeps,
} from "../src/pipeline.js";
import { registerFallback, clearFallbacks } from "../src/domain/fallbackPolicy.js";
import { ProviderError } from "../src/types.js";
import type { ProviderAdapter, ChatOptions } from "../src/providers/base.js";
import type {
  ChatCompletionRequest,
  ChatCompletionResponse,
  ProviderConnection,
  ProviderId,
} from "../src/types.js";

function fakeConn(provider: ProviderId): ProviderConnection {
  return {
    id: provider,
    provider,
    kind: "openai-compatible",
    name: provider,
    isActive: true,
    apiKey: "x",
    baseUrl: "http://localhost",
    tier: "api",
  };
}

/** Adapter that either returns a canned reply or throws a chosen error. */
function fakeAdapter(
  provider: ProviderId,
  behavior: "ok" | "retryable" | "fatal",
): ProviderAdapter {
  return {
    connection: fakeConn(provider),
    async chat(req: ChatCompletionRequest, opts: ChatOptions): Promise<ChatCompletionResponse> {
      if (behavior === "retryable") throw new ProviderError("503", true, 503);
      if (behavior === "fatal") throw new ProviderError("400 bad", false, 400);
      return {
        id: "x",
        object: "chat.completion",
        created: 0,
        model: opts.upstreamModel,
        choices: [{ index: 0, message: { role: "assistant", content: `hi from ${provider}` }, finish_reason: "stop" }],
        usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 },
      };
    },
  };
}

const req: ChatCompletionRequest = {
  model: "gpt-4o",
  messages: [{ role: "user", content: "hello" }],
};

test("explicit model resolves primary provider first", () => {
  clearFallbacks();
  const cands = resolveCandidates(req, { getAdapter: () => undefined });
  assert.equal(cands[0]!.provider, "openai");
  assert.equal(cands[0]!.model, "gpt-4o");
});

test("falls back to next provider on retryable error", async () => {
  clearFallbacks();
  registerFallback("gpt-4o", [{ provider: "anthropic", priority: 0, enabled: true }]);
  const deps: PipelineDeps = {
    getAdapter: (p) =>
      p === "openai" ? fakeAdapter("openai", "retryable") : fakeAdapter(p, "ok"),
  };
  const res = await runPipeline(req, deps);
  assert.equal(res.omniroute?.provider, "anthropic");
  assert.equal(res.omniroute?.attempts.length, 2);
  assert.equal(res.omniroute?.attempts[0]!.ok, false);
  assert.equal(res.omniroute?.attempts[1]!.ok, true);
});

test("stops immediately on non-retryable error", async () => {
  clearFallbacks();
  registerFallback("gpt-4o", [{ provider: "anthropic", priority: 0, enabled: true }]);
  let anthropicCalled = false;
  const deps: PipelineDeps = {
    getAdapter: (p) => {
      if (p === "openai") return fakeAdapter("openai", "fatal");
      anthropicCalled = true;
      return fakeAdapter(p, "ok");
    },
  };
  await assert.rejects(runPipeline(req, deps), ProviderError);
  assert.equal(anthropicCalled, false, "must not try fallback after a fatal error");
});

test("throws AllRoutesFailedError when every provider is retryable-failing", async () => {
  clearFallbacks();
  registerFallback("gpt-4o", [{ provider: "anthropic", priority: 0, enabled: true }]);
  const deps: PipelineDeps = { getAdapter: (p) => fakeAdapter(p, "retryable") };
  await assert.rejects(runPipeline(req, deps), AllRoutesFailedError);
});

test("skips unconfigured providers without failing", async () => {
  clearFallbacks();
  registerFallback("gpt-4o", [{ provider: "anthropic", priority: 0, enabled: true }]);
  const deps: PipelineDeps = {
    getAdapter: (p) => (p === "anthropic" ? fakeAdapter("anthropic", "ok") : undefined),
  };
  const res = await runPipeline(req, deps);
  assert.equal(res.omniroute?.provider, "anthropic");
});

test("unknown model raises NoRouteError", () => {
  clearFallbacks();
  assert.throws(
    () => resolveCandidates({ model: "nope", messages: [] }, { getAdapter: () => undefined }),
    NoRouteError,
  );
});

test("auto mode spans tiers cheapest-first within tier", () => {
  clearFallbacks();
  const cands = resolveCandidates(
    { model: "auto", messages: [] },
    { getAdapter: () => undefined },
  );
  // First candidate should be an "api"-tier model (no subscription models seeded).
  assert.equal(cands[0]!.tier, "api");
  // Free-tier model must appear after cheap-tier ones.
  const tiers = cands.map((c) => c.tier);
  assert.ok(tiers.indexOf("free") > tiers.indexOf("cheap"));
});
