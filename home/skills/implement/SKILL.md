---
name: implement
description: Implement a plan one step at a time — relevant skills, minimal comments and tests, unit-of-work commits, reviewer ping-pong, sideshow overview.
argument-hint: "The plan to implement (path or pasted)"
disable-model-invocation: true
---

Implement the plan through the Model roles flow (personal AGENTS.md).
You are the orchestrator: the main session that owns the plan, the
dispatch, and the review loop.

First restate the plan in your own words and confirm you have everything
needed. Stop and ask about anything missing or ambiguous. A plan that is
not step-complete — file-level steps, acceptance checks per step — does
not get implemented as-is: fix it first, or ask me. Wait for the go-ahead
before dispatching.

Dispatch the whole plan to the `implementer` agent in one task (`task`,
agent `implementer`); name the rules below and the skills matching the
touched files in the brief. It executes and commits per step without
waiting for you. For a small job — a one-liner, a rename — skip the
dispatch and execute it yourself under the same rules; do not turn small
tasks into ceremony. The implementer child has no `task` tool: when this
skill loads there, steps 8-9 belong to the orchestrator it reports
back to.

1. Load the relevant skills for the work — whichever match the files you are
   going to modify.
2. Tests: only when they are worth it and necessary. No redundant tests, no
   tests for the sake of it, no AI-slop tests.
3. Build on what exists. Search for existing helpers before writing new ones.
   Three functions doing the same job across the codebase is a failure.
4. One commit = one unit of work to review.
5. Work through every plan step without waiting between steps: one
   step = one commit, and the tests plus the step's acceptance checks run
   before that step's commit. Stop only when a step is red or ambiguous —
   otherwise keep going to the end of the plan. Tests cover only the
   packages the step touches, never the whole suite; run them once per
   commit, and run full builds (e.g. Vite bundles) once, on the last commit.
6. A step that turns out underspecified or ambiguous is a plan bug — stop
   and get it fixed by the orchestrator (or me) instead of guessing.
7. Tricky concurrency, security-sensitive code, core architecture changes:
   flag them for the orchestrator, never improvise.
8. When the implementer returns (or your own execution is done), launch
   the reviewer as a fresh task spawn (`task`, agent `reviewer`) with the
   diff scope and the plan it was implemented against. Name its skills in
   the brief — `thermo-nuclear-code-quality-review` plus any matching the
   touched files. Ping-pong: re-dispatch the implementer with each
   round's findings — it fixes them or answers with a disagreement —
   until GREENLIGHT, max 3 rounds without it. Review fixes land as
   `git commit --fixup=<sha>` commits; you squash them.
   - Each round is a new task spawn. Its prompt carries the ping-pong so
     far: brief, findings, answers, open objections.
   - Round 2 onward checks only the fixes and what they touch, at effort
     high.
   - The reviewer checks HEAD only; the per-commit checks already ran and
     are not repeated by the reviewer or the orchestrator.
9. Publish a sideshow overview board of the finished change (the `sideshow`
    skill): mermaid architecture and data flow, an end-to-end markdown
    narrative, one diff part per commit. Wait for my comments and reply or
    revise.

## UI components

- Build new components decomposed from the first commit: a shell (state,
  data, layout) plus a parts module for the visual regions. Landing a
  200-line single component and splitting it after review costs two review
  cycles that the first shape avoids.
- Conditional JSX belongs in small named components or helpers with early
  returns, not in nested ternaries inside markup.
- When a new component copies a neighbour's chrome (tab groups, stat cells,
  card shells), put the share-or-duplicate decision in the plan.
- A refactor review brief asks about shape too: flag remaining nested
  ternaries and duplicated chrome, not only behavior equivalence.

## Landing (jungle-rabbit)

Every branch comes off `master`. The user opens the PR against `master`,
and the same branch is then merged into `develop` to keep `develop` in
sync with `master`. Never commit straight to `develop`. Do not ask which
way to land — this is the answer.
