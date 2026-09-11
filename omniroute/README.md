# OmniRoute MVP

A clean-room, minimal reimplementation of the **core** of
[OmniRoute](https://github.com/diegosouzapw/OmniRoute): a single
OpenAI-compatible endpoint that routes requests across multiple AI providers
with automatic fallback.

> **Scope honesty.** Upstream OmniRoute is a mature product (v3.8.51, ~9k
> TypeScript files) with 356 providers, RTK+Caveman token compression, MCP/A2A,
> Electron/PWA/Android packaging, SQLite persistence and OAuth. This MVP is
> **not** a full reproduction. It rebuilds the routing heart in a small,
> self-contained, tested TypeScript package so the concept is runnable and
> extendable. See [Not included / roadmap](#not-included--roadmap).

It lives in a subdirectory of the `sivigila-dashboard` repo and is fully
independent of the SIVIGILA PWA (its own `package.json`, no shared deps).

## What it does

- **One OpenAI-compatible endpoint** — `POST /v1/chat/completions`, `GET /v1/models`.
- **Multiple providers behind it** — OpenAI, Anthropic, Google Gemini, and any
  OpenAI-compatible API (OpenRouter, Groq, DeepSeek, Mistral). Each is enabled
  simply by setting its API key.
- **Automatic fallback** — on a retryable failure (429, 5xx, network, auth) the
  pipeline falls through to the next provider; a bad request (400/404/422) stops
  immediately instead of wasting other providers.
- **Routing strategies (combos)** — `priority`, `weighted`, `round-robin`,
  `random`, `least-used`, `cost-optimized`.
- **Tiered auto-routing** — `model: "auto"` spans tiers (subscription → api →
  cheap → free), cheapest-first within a tier.
- **Transparent decisions** — every response includes an `omniroute` block with
  the provider/model that served it and the full attempt log.

## Install & run

```bash
cd omniroute
npm install
cp .env.example .env        # add the provider keys you have
npm run serve               # starts on http://localhost:8787
```

Call it with any OpenAI client:

```bash
curl -s http://localhost:8787/v1/chat/completions \
  -H 'content-type: application/json' \
  -d '{"model":"gpt-4o","messages":[{"role":"user","content":"Hello"}]}'
```

Point an existing tool at it by setting its base URL to
`http://localhost:8787/v1`.

## CLI

```bash
npm run cli providers            # which providers are configured
npm run cli models               # known models, tiers, cost
npm run cli combos               # seeded routing combos
npm run cli route auto "Hola"    # one-off completion (model can be "auto")
npm run cli route gpt-4o "Hi" --combo cheapest
```

## How routing works

1. **Resolve candidates** (`src/pipeline.ts`):
   - `combo` set → order the combo's models by its strategy (`src/domain/comboRouter.ts`).
   - `model: "auto"` → all models ranked by tier then blended cost.
   - explicit model → primary provider + its fallback chain (`src/domain/fallbackPolicy.ts`).
2. **Execute in order** — try each candidate's adapter; on a retryable error,
   move to the next; on a fatal error, stop.
3. **Return** the first success with an `omniroute` metadata block.

## Layout

```
src/
  types.ts                 domain types (ProviderConnection, Combo, ...)
  config.ts                build connections from env vars
  gateway.ts               wire config + adapters + combos + fallbacks
  server.ts                OpenAI-compatible HTTP server
  cli.ts                   command-line interface
  domain/
    modelRegistry.ts       model -> provider/tier/cost
    comboRouter.ts         6 selection strategies
    comboStore.ts          combo registry + defaults
    fallbackPolicy.ts      per-model fallback chains
  providers/
    base.ts                adapter contract
    registry.ts            build adapters from connections
    openaiCompatible.ts    OpenAI / OpenRouter / Groq / DeepSeek / Mistral
    anthropic.ts           Anthropic Messages API translation
    gemini.ts              Gemini generateContent translation
tests/                     node:test suites (routing, fallback, pipeline)
```

## Testing

```bash
npm run typecheck    # tsc over src + tests
npm test             # node:test suites (no network; fake adapters)
```

## Not included / roadmap

Deliberately out of scope for this MVP, in rough priority order:

- **Streaming** (`stream: true`) — currently rejected; SSE pass-through is the
  natural next step.
- Full provider catalog (356 providers) and live model discovery.
- RTK + Caveman token compression engines.
- Persistence (SQLite), usage/cost accounting and quota caches.
- OAuth connections, rate-limit protection, MCP/A2A servers.
- Desktop/PWA/Android packaging.

## Attribution

Concept and domain model derived from OmniRoute by diegosouzapw
(MIT License). This is an independent, from-scratch implementation of a subset —
no upstream source was copied.
