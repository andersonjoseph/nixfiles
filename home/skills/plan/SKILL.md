---
name: plan
description: Explore read-only and design a plan for the implementer — file-level steps, one bounded action each, an acceptance check per step. Use when the user asks to plan, design, or scope a change before implementation.
argument-hint: "What to plan"
disable-model-invocation: true
---

Explore the codebase and design the change — do not make it.

## Operating rules

- Explore freely: read files, search, run read-only commands, and
  delegate exploration to the explorer (Model roles in the personal
  instructions) when that is faster.
- Do not create or modify any file. Never edit project files from
  planning, and never direct a subagent to edit them.
- Stay in planning. If the user asks to implement, point at the
  `implement` skill — do not start implementing.
- Scale the plan to the job: a one-line fix needs none; a new feature
  needs enough that shape and scope are agreed before code is written.
  Don't turn small tasks into ceremony.

## Plan format

The implementer (Model roles in the personal instructions) executes
clearly scoped steps well and reasons worse in the open. Write for that
reader.

- **One diagram that carries the logic** — publish it to the user's
  sideshow board as a mermaid surface (the `sideshow` skill, piped from
  stdin: `sideshow mermaid - --title "<plan>"`) only when the plan's shape
  earns it: the user asked for a visual, or the logic has real flow,
  branching, or state that prose carries poorly — pipelines, decision
  trees, statecharts. Otherwise skip the card; the plan lives in chat.
  When you do publish, the graph *is* the key logic; don't add a
  separate pseudocode block. If the user comments on the card, read them
  with `sideshow wait` and treat them as plan feedback.
- **Statechart first for stateful work** — UI modes, loading/error/drill
  states, request lifecycles: draw the states and transitions
  (`stateDiagram-v2`) before writing steps, and make every state and
  transition land in a step or an acceptance check. Missing states are
  what review rounds find late.
- **Types & interfaces** to add or change, when they clarify.
- **Ordered steps**, one bounded action each, file-level: which files, what
  change. One step = one commit. Every step carries its acceptance check —
  the test to run, the command to pass, or the criterion to verify. Never
  leave a step open-ended.
- **Hard-part flags**: steps touching tricky concurrency, security-sensitive
  code, or core architecture are marked for the orchestrator — the
  implementer escalates them instead of improvising.
- **Write paths**: a plan that adds or changes a write path (pipeline,
  store, queue) lists every writer of each new table or key — its trigger,
  its time source, its order against the other writers, and which inputs
  it covers.
- **No prescribed indirection**: give each data shape as its consumers
  use it. Do not prescribe a key-to-value lookup table, a second type for
  the same data, or a purity rule ("no X in this file") unless a named
  consumer or test needs it. Reuse an existing helper only when its
  output fits as-is; if a step would search or filter that output to get
  one value, put the value in directly. Every field, export and return
  value the plan adds names its reader.
- **Shared chrome**: when a new component copies a neighbour's chrome (tab
  groups, stat cells, card shells), the plan decides share or duplicate.
- **Files to touch**, one line each, marked `NEW`/`EDIT` with the intent.
- **Open questions**, if any — resolve them before implementation starts,
  not during: after the draft, load the `grilling` skill and settle them
  with me one at a time, then give the final plan.
