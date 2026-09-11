#!/usr/bin/env node
/**
 * OmniRoute MVP CLI.
 *
 * Commands:
 *   serve                         Start the OpenAI-compatible gateway.
 *   providers                     List configured providers (by API keys set).
 *   models                        List known models with tier and cost.
 *   combos                        List seeded routing combos.
 *   route <model> <prompt...>     Send a one-off prompt through the pipeline.
 *
 * `route` and `serve` require the relevant provider API keys in the env.
 */

import { loadConfig, knownProviders } from "./config.js";
import { createGateway } from "./gateway.js";
import { startServer } from "./server.js";
import { runPipeline } from "./pipeline.js";
import { listModels } from "./domain/modelRegistry.js";
import { listCombos } from "./domain/comboStore.js";

async function main(argv: string[]): Promise<void> {
  const [command, ...rest] = argv;
  const config = loadConfig();

  switch (command) {
    case "serve": {
      const gateway = createGateway(config);
      await startServer(gateway);
      return;
    }

    case "providers": {
      const active = new Set(config.connections.map((c) => c.provider));
      for (const p of knownProviders()) {
        console.log(`${active.has(p) ? "[on] " : "[off]"} ${p}`);
      }
      return;
    }

    case "models": {
      for (const m of listModels()) {
        console.log(
          `${m.id.padEnd(22)} ${m.provider.padEnd(11)} ${m.tier.padEnd(13)} ` +
            `$${m.inputCostPer1M}/$${m.outputCostPer1M} per 1M`,
        );
      }
      return;
    }

    case "combos": {
      createGateway(config); // seeds defaults
      for (const c of listCombos()) {
        console.log(`${c.name.padEnd(12)} ${c.strategy.padEnd(15)} [${c.models.map((m) => m.model).join(", ")}]`);
      }
      return;
    }

    case "route": {
      const [model, ...promptParts] = rest;
      if (!model || promptParts.length === 0) {
        console.error('usage: omniroute route <model|auto> "<prompt>"  [--combo <name>]');
        process.exitCode = 1;
        return;
      }
      const gateway = createGateway(config);
      const comboIdx = promptParts.indexOf("--combo");
      let combo: string | undefined;
      if (comboIdx !== -1) {
        combo = promptParts[comboIdx + 1];
        promptParts.splice(comboIdx, 2);
      }
      const result = await runPipeline(
        {
          model,
          combo,
          messages: [{ role: "user", content: promptParts.join(" ") }],
        },
        gateway.deps,
      );
      console.log(result.choices[0]?.message.content ?? "");
      console.error(
        `\n[served by ${result.omniroute?.provider}/${result.omniroute?.model} ` +
          `after ${result.omniroute?.attempts.length} attempt(s)]`,
      );
      return;
    }

    case undefined:
    case "help":
    case "--help":
    case "-h":
      printHelp();
      return;

    default:
      console.error(`unknown command: ${command}`);
      printHelp();
      process.exitCode = 1;
  }
}

function printHelp(): void {
  console.log(
    [
      "OmniRoute MVP — one OpenAI-compatible endpoint, many providers, auto fallback.",
      "",
      "Usage: omniroute <command>",
      "",
      "Commands:",
      "  serve                      Start the gateway (OMNIROUTE_PORT, default 8787)",
      "  providers                  Show which providers are configured",
      "  models                     List known models, tiers and cost",
      "  combos                     List routing combos",
      '  route <model> "<prompt>"   One-off completion (model can be "auto")',
      "                             optional: --combo <name>",
    ].join("\n"),
  );
}

main(process.argv.slice(2)).catch((err) => {
  console.error(err instanceof Error ? err.message : String(err));
  process.exitCode = 1;
});
