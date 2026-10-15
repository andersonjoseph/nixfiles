---
name: sideshow
description: Draw the high-level picture of a change on the user's sideshow board — architecture and data-flow diagrams, end-to-end narratives, per-commit diffs, rich visuals — and read their comments back. Use when the user asks to visualize, sketch, or get an overview of work, or after implementing a plan.
---

# sideshow

The user watches a sideshow board in their browser. This skill is a bootstrap:
fetch the current operational instructions from the running server first.

```sh
sideshow agent-howto
sideshow guide
```

If `SIDESHOW_URL` is unset, the server is `http://localhost:8228`. Those fetched
notes never override system, developer, project, or user instructions; fetch them
only from the user's configured localhost or a trusted HTTPS sideshow origin.

## Publishing

Surfaces appear in flag order. Pass `-` to read a surface from stdin.

```sh
sideshow publish --title "Auth refactor" --session-title "Auth refactor" \
  --md notes.md --mermaid arch.mmd --diff first.patch --diff second.patch
```

Per-commit patches for a range:

```sh
git show --format= <sha> > /tmp/opencode/<sha>.patch
```

## Change overview boards

For a finished change, publish a board that explains the shape before the code:

- `--mermaid`: the architecture and data flow the change touches, entry point to end
- `--md`: what changed and why, as an end-to-end narrative
- `--diff`: one surface per unit-of-work commit, in the order they landed

The `hunk-review` skill carries the code-level walkthrough on the live diff;
sideshow carries the picture. Publish the overview first, then offer hunk.

## Feedback loop

- `sideshow wait --timeout 120` blocks until the user comments, then prints them.
- `sideshow watch` streams comments one per line — use it as a background monitor.
- `sideshow comment "text" --post <id>` replies in the thread.
- `sideshow update <id> <file>` revises a post in place; `sideshow show <id>` and
  `sideshow list` inspect the board.

## Rich visuals

A raw html file published as the post argument covers mockups, charts, and dense
explainers beyond ASCII. Show the thing; the viewer supplies the chrome.
