/**
 * Pure session-tree helpers for tree-tools.
 *
 * Operates directly on session JSONL content. The active position is passed
 * in as a leaf id: the in-memory session tracks it, and /tree navigation can
 * move it without writing to the file. Children always appear after their
 * parents. Zero pi imports, so the logic stays trivially testable.
 */
import { copyFileSync, readFileSync, renameSync, writeFileSync } from "node:fs";

/** Structural view of a session JSONL line. Unknown fields are preserved verbatim. */
export type SessionLine = {
	type: string;
	id?: string;
	parentId?: string | null;
	targetId?: string;
	message?: { role?: string; content?: string | unknown[] };
};

/** A subtree hanging off the active path, deletable in isolation. */
export type SideBranch = {
	ids: string[];
	/** First user prompt in the subtree, for pickers. */
	preview: string;
	/** Number of message entries in the subtree. */
	messages: number;
};

export function readSessionEntries(file: string): SessionLine[] {
	return readFileSync(file, "utf8")
		.split("\n")
		.filter((line) => line.trim().length > 0)
		.map((line) => JSON.parse(line) as SessionLine)
		.filter((entry) => entry.type !== "session");
}

function indexById(entries: SessionLine[]): Map<string, SessionLine> {
	const byId = new Map<string, SessionLine>();
	for (const entry of entries) if (entry.id) byId.set(entry.id, entry);
	return byId;
}

/** Ordered root-to-leaf path of the current position. */
export function activePath(entries: SessionLine[], leafId: string | null): SessionLine[] {
	const byId = indexById(entries);
	const path: SessionLine[] = [];
	let current = leafId ? byId.get(leafId) : undefined;
	while (current && current.id) {
		path.push(current);
		current = current.parentId ? byId.get(current.parentId) : undefined;
	}
	return path.reverse();
}

export function activePathIds(entries: SessionLine[], leafId: string | null): Set<string> {
	return new Set(activePath(entries, leafId).map((entry) => entry.id!));
}

function childrenByParent(entries: SessionLine[]): Map<string | null, SessionLine[]> {
	const children = new Map<string | null, SessionLine[]>();
	for (const entry of entries) {
		if (!entry.id) continue;
		const key = entry.parentId ?? null;
		const list = children.get(key);
		if (list) list.push(entry);
		else children.set(key, [entry]);
	}
	return children;
}

function previewText(subtree: SessionLine[]): string {
	for (const entry of subtree) {
		const message = entry.message;
		if (message?.role !== "user") continue;
		const content = message.content;
		const text =
			typeof content === "string"
				? content
				: Array.isArray(content)
					? content.find(isTextBlock)?.text ?? ""
					: "";
		if (text) return oneLine(text, 60);
	}
	return `(no user message, starts with ${subtree[0]?.type ?? "unknown"} entry)`;
}

function isTextBlock(block: unknown): block is { type: "text"; text: string } {
	return typeof block === "object" && block !== null && (block as { type?: string }).type === "text";
}

function oneLine(text: string, max: number): string {
	const flat = text.replace(/\s+/g, " ").trim();
	return flat.length > max ? flat.slice(0, max - 1) + "…" : flat;
}

/**
 * Subtrees hanging off the active path: for every path entry (and the virtual
 * root before the first one), any child that is not the path continuation.
 */
export function sideBranches(entries: SessionLine[], leafId: string | null): SideBranch[] {
	const children = childrenByParent(entries);
	const path = activePath(entries, leafId);
	const nextOnPath = new Map<string, string | undefined>();
	for (let i = 0; i < path.length; i++) nextOnPath.set(path[i].id!, path[i + 1]?.id);

	const roots: SessionLine[] = [];
	for (const child of children.get(null) ?? []) {
		if (child.id !== path[0]?.id) roots.push(child);
	}
	for (const node of path) {
		const next = nextOnPath.get(node.id!);
		for (const child of children.get(node.id!) ?? []) {
			if (child.id !== next) roots.push(child);
		}
	}

	const branches: SideBranch[] = [];
	for (const root of roots) {
		if (!root.id) continue;
		const ids = new Set<string>([root.id]);
		const stack = [root.id];
		while (stack.length > 0) {
			for (const child of children.get(stack.pop()!) ?? []) {
				if (child.id && !ids.has(child.id)) {
					ids.add(child.id);
					stack.push(child.id);
				}
			}
		}
		const subtree = entries.filter((entry) => entry.id !== undefined && ids.has(entry.id));
		branches.push({
			ids: [...ids],
			preview: previewText(subtree),
			messages: subtree.filter((entry) => entry.type === "message").length,
		});
	}
	return branches;
}

/**
 * Ids to delete when pruning to the active path: everything off it, except
 * labels that still resolve (target and parent both survive). Targets of kept
 * labels are pulled back in too, so a path label pointing into a pruned
 * branch keeps rendering (as a lone entry; its subtree stays pruned).
 */
export function dropOutsideActivePath(entries: SessionLine[], leafId: string | null): Set<string> {
	const keep = activePathIds(entries, leafId);
	const byId = indexById(entries);
	for (const entry of entries) {
		if (entry.type !== "label" || !entry.id || !entry.targetId || !keep.has(entry.id)) continue;
		const target = byId.get(entry.targetId);
		if (target?.id) keep.add(target.id);
	}
	for (const entry of entries) {
		if (!entry.id || keep.has(entry.id)) continue;
		if (
			entry.type === "label" &&
			entry.targetId &&
			entry.parentId &&
			keep.has(entry.targetId) &&
			keep.has(entry.parentId)
		) {
			keep.add(entry.id);
		}
	}
	return new Set(entries.filter((entry) => entry.id && !keep.has(entry.id)).map((entry) => entry.id!));
}

/**
 * Ids to delete when removing specific subtrees: them plus anything that
 * would dangle afterwards (children of dropped entries, labels targeting
 * them). Active-path entries are exempt from the cascade, so a label on the
 * path whose target sits in a removed branch survives (its render goes with
 * the branch).
 */
export function dropSubtrees(entries: SessionLine[], ids: Iterable<string>, leafId: string | null): Set<string> {
	const drop = new Set(ids);
	const pathIds = activePathIds(entries, leafId);
	for (const entry of entries) {
		if (!entry.id || drop.has(entry.id) || pathIds.has(entry.id)) continue;
		if ((entry.parentId && drop.has(entry.parentId)) || (entry.type === "label" && entry.targetId && drop.has(entry.targetId))) {
			drop.add(entry.id);
		}
	}
	return drop;
}

export function backupPathFor(file: string): string {
	// Deliberately not ".jsonl": SessionManager.list() treats every *.jsonl in
	// the sessions dir as a session, and a .jsonl backup would resurface as a
	// stale duplicate in /resume.
	return file.replace(/\.jsonl$/, "") + ".prune-backup.bak";
}

/**
 * Rewrite the session file down to the header plus every entry except the
 * dropped ids, preserving original lines verbatim. Entries unknown to the
 * drop set (e.g. appended between computing it and this write) are kept.
 * Backs up the pre-rewrite file on every call, so the backup always covers
 * what this prune deletes. Tradeoff: the previous backup is replaced, so
 * only one generation of undo is kept (timestamped backups would grow
 * unboundedly in the sessions dir). Swaps atomically.
 */
export function rewriteSessionFile(file: string, dropIds: Set<string>): { removed: number } {
	const lines = readFileSync(file, "utf8")
		.split("\n")
		.filter((line) => line.trim().length > 0);
	const out: string[] = [];
	let removed = 0;
	for (const line of lines) {
		const entry = JSON.parse(line) as SessionLine;
		if (entry.type === "session" || (entry.id && !dropIds.has(entry.id))) {
			out.push(line);
		} else {
			removed++;
		}
	}
	copyFileSync(file, backupPathFor(file));
	const tmp = file + ".tree-tools-tmp";
	writeFileSync(tmp, out.join("\n") + "\n");
	renameSync(tmp, file);
	return { removed };
}
