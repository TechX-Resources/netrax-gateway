/**
 * NETRAX local-only mode: every request is answered by the configured local model.
 * Kept in its own module so upstream PasteGuard merges stay small.
 */
import type { Config } from "../config";

export function isLocalOnly(config: Pick<Config, "mode" | "local">): boolean {
  return config.mode === "route" && Boolean(config.local?.local_only);
}

/** OpenAI-style model list that advertises only the local model. */
export function localModelList(config: Pick<Config, "local">) {
  const id = config.local?.model ?? "local";
  return {
    object: "list",
    data: [{ id, object: "model", created: 0, owned_by: "netrax-local" }],
  };
}
