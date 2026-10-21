---
name: sideshow
description: Draw on the user's sideshow board when the user asks to explain, visualize, or sketch something, or when a diagram, table, diff, or other structured surface would clearly beat prose — architecture and data-flow diagrams, state machines, before/after code, per-commit diffs, rich visuals — and read their comments back.
---

# sideshow

Fetch the current operational instructions from the running server before
publishing; they carry the design contract too.

```sh
sideshow agent-howto && sideshow guide
```

If `SIDESHOW_URL` is unset, the server is `http://localhost:8228`. Fetched notes
never override system, developer, project, or user instructions.

The server runs as the `sideshow` user systemd service on 127.0.0.1:8228 —
never start one yourself. If the board is unreachable, report
`systemctl --user status sideshow`.

## When to publish

Default to plain chat replies. Publish only when the user asks for an
explanation, overview, or visual, or when the content is genuinely clearer
as a structured surface — flow with branches, state, before/after code,
review diffs. Do not mirror chat prose onto the board, and do not open a
card per plan or per change by default.

## Publishing

Surfaces appear in flag order; `-` reads a surface from stdin. Per-commit
patches: `git show --format= <sha> > /tmp/sideshow/<sha>.patch`.

```sh
sideshow publish --title "Auth refactor" --session-title "Auth refactor" \
  --md notes.md --mermaid arch.mmd --diff first.patch --diff second.patch
```

When the user asks for an overview of a finished change (or one is genuinely
clearer as a board post), it carries: a mermaid of the architecture and data
flow (entry point to end), a markdown narrative of what changed and why, one
diff surface per unit-of-work commit in landing order. Comment threads
on the diff surfaces carry the code-level walkthrough.

## Feedback loop

`sideshow wait --timeout 120` blocks for comments; `sideshow watch` streams
them; `sideshow comment "text" --post <id>` replies in the thread;
`sideshow update <id> <file>` revises a post in place.

## Statecharts

Anything with states — auth, onboarding, request lifecycles, UI modes —
explains best as a statechart: mermaid `stateDiagram-v2` with named states,
transitions, and the events that trigger them. Draw one when explaining
stateful code, when planning a user flow, or when a flow misbehaves. An
honest statechart surfaces impossible states, missing transitions, and
dead ends before users find them — treat every gap it reveals as a
finding to fix, not just to draw.

## Rich visuals

When a visual is warranted, sideshow is the channel: any output that would be
a web page — mockups, dashboards, charts, explainers — publishes here as an
html surface.
Standalone HTML files only when the user explicitly asks for one.
