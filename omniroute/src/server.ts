/**
 * HTTP server — exposes an OpenAI-compatible surface backed by the pipeline.
 *
 * Endpoints:
 *   GET  /health                 -> liveness + configured providers
 *   GET  /v1/models              -> OpenAI-style model list
 *   POST /v1/chat/completions    -> routed chat completion (non-streaming)
 */

import http from "node:http";
import type { AddressInfo } from "node:net";
import type { Gateway } from "./gateway.js";
import { listModels } from "./domain/modelRegistry.js";
import { listCombos } from "./domain/comboStore.js";
import {
  AllRoutesFailedError,
  NoRouteError,
  runPipeline,
} from "./pipeline.js";
import { ProviderError, type ChatCompletionRequest } from "./types.js";

export function createServer(gateway: Gateway): http.Server {
  return http.createServer((req, res) => {
    handle(req, res, gateway).catch((err) => {
      sendJson(res, 500, { error: { message: (err as Error).message, type: "internal_error" } });
    });
  });
}

export function startServer(gateway: Gateway): Promise<http.Server> {
  const server = createServer(gateway);
  return new Promise((resolve) => {
    server.listen(gateway.config.port, () => {
      const addr = server.address() as AddressInfo;
      // eslint-disable-next-line no-console
      console.log(
        `OmniRoute MVP listening on http://localhost:${addr.port} ` +
          `(providers: ${gateway.registry.providers().join(", ") || "none configured"})`,
      );
      resolve(server);
    });
  });
}

async function handle(
  req: http.IncomingMessage,
  res: http.ServerResponse,
  gateway: Gateway,
): Promise<void> {
  const url = new URL(req.url ?? "/", "http://localhost");

  if (req.method === "GET" && url.pathname === "/health") {
    sendJson(res, 200, {
      status: "ok",
      providers: gateway.registry.providers(),
      combos: listCombos().map((c) => c.name),
    });
    return;
  }

  if (req.method === "GET" && url.pathname === "/v1/models") {
    sendJson(res, 200, {
      object: "list",
      data: listModels().map((m) => ({
        id: m.id,
        object: "model",
        owned_by: m.provider,
        tier: m.tier,
      })),
    });
    return;
  }

  if (req.method === "POST" && url.pathname === "/v1/chat/completions") {
    if (!authorized(req, gateway)) {
      sendJson(res, 401, { error: { message: "missing or invalid gateway API key", type: "auth_error" } });
      return;
    }
    let body: ChatCompletionRequest;
    try {
      body = await readJson(req);
    } catch (err) {
      sendJson(res, 400, { error: { message: (err as Error).message, type: "invalid_request" } });
      return;
    }
    if (!body?.model || !Array.isArray(body.messages)) {
      sendJson(res, 400, { error: { message: "`model` and `messages` are required", type: "invalid_request" } });
      return;
    }
    if (body.stream) {
      sendJson(res, 400, {
        error: {
          message: "streaming is not supported in this MVP; set stream=false",
          type: "invalid_request",
        },
      });
      return;
    }

    try {
      const result = await runPipeline(body, gateway.deps);
      sendJson(res, 200, result);
    } catch (err) {
      if (err instanceof NoRouteError) {
        sendJson(res, 404, { error: { message: err.message, type: "no_route" } });
      } else if (err instanceof ProviderError && !err.retryable) {
        sendJson(res, err.status ?? 400, { error: { message: err.message, type: "provider_error" } });
      } else if (err instanceof AllRoutesFailedError) {
        sendJson(res, 502, {
          error: { message: err.message, type: "all_routes_failed" },
          attempts: err.attempts,
        });
      } else {
        sendJson(res, 500, { error: { message: (err as Error).message, type: "internal_error" } });
      }
    }
    return;
  }

  sendJson(res, 404, { error: { message: "not found", type: "not_found" } });
}

function authorized(req: http.IncomingMessage, gateway: Gateway): boolean {
  const required = gateway.config.gatewayApiKey;
  if (!required) return true;
  const header = req.headers.authorization ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";
  return token === required;
}

function readJson(req: http.IncomingMessage): Promise<ChatCompletionRequest> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    let size = 0;
    const MAX = 5 * 1024 * 1024; // 5 MB guard
    req.on("data", (c: Buffer) => {
      size += c.length;
      if (size > MAX) {
        reject(new Error("request body too large"));
        req.destroy();
        return;
      }
      chunks.push(c);
    });
    req.on("end", () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString("utf8")));
      } catch {
        reject(new Error("invalid JSON body"));
      }
    });
    req.on("error", reject);
  });
}

function sendJson(res: http.ServerResponse, status: number, payload: unknown): void {
  const data = JSON.stringify(payload);
  res.writeHead(status, {
    "content-type": "application/json",
    "content-length": Buffer.byteLength(data),
  });
  res.end(data);
}
