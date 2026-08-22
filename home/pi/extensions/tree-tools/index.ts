/**
 * tree-tools — extensions for working with the session tree.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerPruneCommands } from "./prune";

export default function (pi: ExtensionAPI) {
	registerPruneCommands(pi);
}
