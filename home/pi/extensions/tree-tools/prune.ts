/**
 * Branch pruning commands.
 *
 * /prune         delete every branch except the active one
 * /prune-branch  pick one side branch and delete just that
 *
 * The session JSONL is rewritten directly (the SessionManager API is
 * append-only), then the session is reopened from disk so /tree and the
 * transcript reflect the prune immediately. A backup of the pre-rewrite file
 * is written next to the session file before each prune.
 */
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { existsSync } from "node:fs";
import {
	backupPathFor,
	dropOutsideActivePath,
	dropSubtrees,
	readSessionEntries,
	rewriteSessionFile,
	sideBranches,
} from "./lib/session-tree";

function sessionFileOrNotify(ctx: ExtensionCommandContext): string | undefined {
	const file = ctx.sessionManager.getSessionFile();
	// pi defers writing the file until the first assistant message, so a path
	// can exist before any content is on disk.
	if (!file || !existsSync(file)) {
		ctx.ui.notify("No persisted session to prune yet (nothing saved to disk)", "warning");
		return undefined;
	}
	return file;
}

async function pruneAndReload(
	ctx: ExtensionCommandContext,
	file: string,
	dropIds: Set<string>,
	leafId: string | null,
): Promise<void> {
	const result = rewriteSessionFile(file, dropIds);
	const switched = await ctx.switchSession(file, {
		withSession: async (ctx2) => {
			// Reload lands on the newest entry in file order; move back to where
			// the user was, unless the prune removed that position.
			if (leafId && !dropIds.has(leafId)) await ctx2.navigateTree(leafId);
			ctx2.ui.notify(`Pruned ${result.removed} entries (backup: ${backupPathFor(file)})`, "info");
		},
	});
	if (switched.cancelled) {
		ctx.ui.notify(
			`Pruned ${result.removed} entries on disk, but another extension cancelled the switch. Run /resume to reload the pruned session.`,
			"warning",
		);
	}
}

export function registerPruneCommands(pi: ExtensionAPI): void {
	pi.registerCommand("prune", {
		description: "Delete every branch except the active one",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) return; // destructive, needs the confirm dialog
			await ctx.waitForIdle();
			const file = sessionFileOrNotify(ctx);
			if (!file) return;
			const leafId = ctx.sessionManager.getLeafId();
			if (!leafId) {
				ctx.ui.notify(
					"Active position is at the very start of the session; /prune would delete every entry. Navigate to a branch first (/tree).",
					"warning",
				);
				return;
			}
			const entries = readSessionEntries(file);
			const dropIds = dropOutsideActivePath(entries, leafId);
			if (dropIds.size === 0) {
				ctx.ui.notify("Nothing to prune: no branches outside the active one", "info");
				return;
			}
			const ok = await ctx.ui.confirm(
				"Prune session",
				`Delete ${dropIds.size} entries outside the active branch? A backup is written next to the session file first.`,
			);
			if (!ok) return;

			await pruneAndReload(ctx, file, dropIds, leafId);
		},
	});

	pi.registerCommand("prune-branch", {
		description: "Pick a side branch and delete it",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) return; // picker-driven, headless modes can't select
			await ctx.waitForIdle();
			const file = sessionFileOrNotify(ctx);
			if (!file) return;
			const entries = readSessionEntries(file);
			const leafId = ctx.sessionManager.getLeafId();
			const branches = sideBranches(entries, leafId);
			if (branches.length === 0) {
				ctx.ui.notify("No other branches to delete", "info");
				return;
			}
			const labels = branches.map(
				(branch, i) =>
					`${i + 1}. ${branch.messages} msg · ${branch.preview} · ${branch.ids.length} entries`,
			);
			const choice = await ctx.ui.select("Delete branch:", labels);
			const branch = branches[labels.indexOf(choice ?? "")];
			if (!branch) return;
			const dropIds = dropSubtrees(entries, branch.ids, leafId);
			const ok = await ctx.ui.confirm("Delete branch", `Delete "${branch.preview}" (${dropIds.size} entries)?`);
			if (!ok) return;

			await pruneAndReload(ctx, file, dropIds, leafId);
		},
	});
}
