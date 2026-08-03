/**
 * Stash Prompts — a scratch stack for your input drafts.
 *
 *   push  (ctrl+shift+s) stash the current editor text onto the stack and clear it
 *   pop   (ctrl+shift+r) restore the most recent stash; if the editor isn't empty,
 *                        the current text cycles to the back so you can rotate
 *                        through drafts without losing anything
 *   drop  (ctrl+shift+d) discard the most recent stash without restoring it
 *   /stash               pick any stashed prompt to restore, or clear the stack
 *
 * A live badge is rendered in the top-right of the editor border as a filled
 * monochrome pill (a tab emerging from the input box), e.g.:
 *   ┌────────────────────▐ 🗂 2  refactor the auth flow… ▐──┐
 *
 * Keys avoid Alt entirely (Alt is a common window-manager modifier, e.g. i3).
 *
 * Everything below the CONFIG block is editable to taste. Rebind keys by
 * changing the `*Key` strings (format: "ctrl+s", "alt+s", "ctrl+shift+p", ...).
 */

import {
	CustomEditor,
	DynamicBorder,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import {
	Container,
	type EditorTheme,
	type SelectItem,
	SelectList,
	Text,
	type TUI,
	truncateToWidth,
	visibleWidth,
} from "@earendil-works/pi-tui";

const CONFIG = {
	/** Stash current editor text. */
	pushKey: "ctrl+shift+s",
	/** Restore most recent (or rotate, see popBehavior). */
	popKey: "ctrl+shift+r",
	/** Discard most recent stash. */
	dropKey: "ctrl+shift+d",
	/**
	 * What happens when you pop with a non-empty editor:
	 *   "rotate" — current text goes to the back, top comes to the editor (cycle through drafts)
	 *   "strict" — refuse and ask you to clear/stash first (never overwrites)
	 */
	popBehavior: "rotate" as "rotate" | "strict",
	/** Max chars of the top prompt shown in the badge preview. */
	previewLength: 28,
	/** Render the stash badge in the editor top border. Disable if you use another editor-replacing extension. */
	showBadge: true,
	/** Background theme color for the monochrome badge pill. */
	badgeBg: "toolPendingBg",
};

/** Build a short single-line preview of a prompt. */
function makePreview(text: string, max: number): string {
	const firstLine = text.split("\n")[0]?.trim() ?? "";
	const collapsed = firstLine.length === 0 ? "(empty)" : firstLine.replace(/\s+/g, " ");
	return collapsed.length > max ? collapsed.slice(0, Math.max(1, max - 1)) + "…" : collapsed;
}

/**
 * Rebuild a top border line that places `right` against the right edge,
 * filling the rest with themed dashes. Mirrors the proven helper from pi's
 * border-status-editor example.
 */
function topBorderWithRight(
	right: string,
	width: number,
	border: (text: string) => string,
): string {
	const fixedWidth = 2; // two corner dashes
	const minimumGap = 3;

	let rightText = right;
	while (fixedWidth + visibleWidth(rightText) + minimumGap > width && visibleWidth(rightText) > 0) {
		rightText = truncateToWidth(rightText, Math.max(0, visibleWidth(rightText) - 1), "");
	}
	const gapWidth = Math.max(0, width - fixedWidth - visibleWidth(rightText));
	return `${border("─")}${border("─".repeat(gapWidth))}${rightText}${border("─")}`;
}

export default function (pi: ExtensionAPI) {
	// Stack of stashed prompts. Top of stack = last element. Reset per session.
	let stack: string[] = [];
	let activeTui: TUI | undefined;

	const refresh = () => activeTui?.requestRender();
	const badgeText = (theme: {
		fg: (c: string, t: string) => string;
		bg: (c: string, t: string) => string;
	}): string => {
		const count = stack.length;
		const preview = makePreview(stack[stack.length - 1] ?? "", CONFIG.previewLength);
		// Monochrome pill: one subtle dark background, grayscale text with a hint of
		// brightness hierarchy (count bright, preview dim). The fill breaks the border
		// line so it reads like a tab emerging from the input box below.
		return theme.bg(
			CONFIG.badgeBg,
			` ${theme.fg("text", `🗂 ${count}`)}  ${theme.fg("dim", preview)} `,
		);
	};

	// --- actions -------------------------------------------------------------

	const push = (ctx: ExtensionContext) => {
		if (!ctx.hasUI) return;
		const text = ctx.ui.getEditorText();
		if (text.trim().length === 0) {
			ctx.ui.notify("Nothing to stash — editor is empty", "warning");
			return;
		}
		stack.push(text);
		ctx.ui.setEditorText("");
		ctx.ui.notify(`Stashed (${stack.length})`, "info");
		refresh();
	};

	const pop = (ctx: ExtensionContext) => {
		if (!ctx.hasUI) return;
		if (stack.length === 0) {
			ctx.ui.notify("Stash is empty", "warning");
			return;
		}
		const current = ctx.ui.getEditorText();
		if (current.trim().length > 0) {
			if (CONFIG.popBehavior === "strict") {
				ctx.ui.notify("Editor not empty — clear it or stash first (popBehavior: strict)", "warning");
				return;
			}
			// rotate: current text -> back, top -> editor
			stack.unshift(current);
			const next = stack.pop()!;
			ctx.ui.setEditorText(next);
			ctx.ui.notify(`Rotated (${stack.length} left)`, "info");
		} else {
			const next = stack.pop()!;
			ctx.ui.setEditorText(next);
			ctx.ui.notify(`Restored (${stack.length} left)`, "info");
		}
		refresh();
	};

	const drop = (ctx: ExtensionContext) => {
		if (!ctx.hasUI) return;
		if (stack.length === 0) {
			ctx.ui.notify("Stash is empty", "warning");
			return;
		}
		const dropped = stack.pop()!;
		ctx.ui.notify(`Dropped "${makePreview(dropped, 24)}" (${stack.length} left)`, "info");
		refresh();
	};

	// --- shortcuts -----------------------------------------------------------

	pi.registerShortcut(CONFIG.pushKey, {
		description: "Stash the current prompt onto the stack",
		handler: async (ctx) => push(ctx),
	});
	pi.registerShortcut(CONFIG.popKey, {
		description: "Restore the most recent stashed prompt",
		handler: async (ctx) => pop(ctx),
	});
	pi.registerShortcut(CONFIG.dropKey, {
		description: "Discard the most recent stashed prompt",
		handler: async (ctx) => drop(ctx),
	});

	// --- /stash manager ------------------------------------------------------

	pi.registerCommand("stash", {
		description: "View and manage stashed prompts",
		handler: async (_args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("/stash requires interactive mode", "error");
				return;
			}
			if (stack.length === 0) {
				ctx.ui.notify("No stashed prompts", "info");
				return;
			}

			// Most recent first.
			const items: SelectItem[] = stack
				.map((text, i) => {
					const fromTop = stack.length - 1 - i; // 0 == most recent
					return {
						value: String(i),
						label: `#${fromTop + 1}  ${makePreview(text, 56)}`,
						description: text.split("\n").slice(0, 2).join(" ⏎ "),
					} satisfies SelectItem;
				})
				.reverse();
			items.push({
				value: "__clear",
				label: "Clear all stashed prompts",
				description: "Empty the stash",
			});

			const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
				const container = new Container();
				container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));
				container.addChild(
					new Text(theme.fg("accent", theme.bold(` Stashed prompts (${stack.length}) `))),
				);

				const selectList = new SelectList(items, Math.min(items.length, 12), {
					selectedPrefix: (t) => theme.fg("accent", t),
					selectedText: (t) => theme.fg("accent", t),
					description: (t) => theme.fg("muted", t),
					scrollInfo: (t) => theme.fg("dim", t),
					noMatch: (t) => theme.fg("warning", t),
				});
				selectList.onSelect = (item) => done(item.value);
				selectList.onCancel = () => done(null);
				container.addChild(selectList);

				container.addChild(
					new Text(theme.fg("dim", "↑↓ navigate • enter restore • esc cancel")),
				);
				container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

				return {
					render: (w: number) => container.render(w),
					invalidate: () => container.invalidate(),
					handleInput: (data: string) => {
						selectList.handleInput(data);
						tui.requestRender();
					},
				};
			});

			if (result == null) return;

			if (result === "__clear") {
				const n = stack.length;
				stack = [];
				ctx.ui.notify(`Cleared ${n} stashed prompt(s)`, "info");
				refresh();
				return;
			}

			const i = Number(result);
			if (!Number.isFinite(i) || i < 0 || i >= stack.length) return;
			const picked = stack[i];
			const current = ctx.ui.getEditorText();
			if (current.trim().length > 0) stack.push(current); // preserve current draft
			stack.splice(i, 1);
			ctx.ui.setEditorText(picked);
			ctx.ui.notify(`Restored (${stack.length} left)`, "info");
			refresh();
		},
	});

	// --- editor badge --------------------------------------------------------

	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI || !CONFIG.showBadge) return;
		stack = []; // fresh stack for this session

		class StashEditor extends CustomEditor {
			constructor(tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) {
				super(tui, theme, keybindings);
				activeTui = tui;
			}

			render(width: number): string[] {
				const lines = super.render(width);
				if (lines.length < 2 || stack.length === 0) return lines;
				const badge = badgeText(ctx.ui.theme);
				lines[0] = topBorderWithRight(badge, width, (s) => this.borderColor(s));
				return lines;
			}
		}

		ctx.ui.setEditorComponent((tui, theme, keybindings) => new StashEditor(tui, theme, keybindings));
	});

	pi.on("session_shutdown", () => {
		activeTui = undefined;
	});
}
