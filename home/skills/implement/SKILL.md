---
name: implement
description: Implement a plan one step at a time — relevant skills, minimal comments and tests, unit-of-work commits, Opus review ping-pong, sideshow overview.
argument-hint: "The plan to implement (path or pasted)"
disable-model-invocation: true
---

Implement the plan as the implementer of the Model roles flow (personal
AGENTS.md). First restate it in your own words and confirm you have
everything needed. Stop and ask about anything missing or ambiguous. A
plan that is not Opus-quality — file-level steps, acceptance checks per
step — does not get implemented as-is: have Opus 5.5 write or fix it first
(`delegate_task`, provider `claudeAgent_free_claude`, model
`claude-opus-5-5`, options `{effort: max}`), or ask me. Wait for the
go-ahead before writing code.

1. Load the relevant skills for the work — whichever match the files you are
   going to modify.
2. Zero Comments: comments are banned in this session.
3. Tests: only when they are worth it and necessary. No redundant tests, no
   tests for the sake of it, no AI-slop tests.
4. Build on what exists. Search for existing helpers before writing new ones.
   Three functions doing the same job across the codebase is a failure.
5. One commit = one unit of work to review.
6. Work through every plan step without waiting for me between steps: one
   step = one commit, and the tests plus the step's acceptance checks run
   before that step's commit. Stop only when a step is red or ambiguous —
   otherwise keep going to the end of the plan. Tests cover only the
   packages the step touches, never the whole suite; run them once per
   commit, and run full builds (e.g. Vite bundles) once, on the last commit.
7. A step that turns out underspecified or ambiguous is a plan bug — stop
   and get it fixed by Opus (or me) instead of guessing.
8. Tricky concurrency, security-sensitive code, core architecture changes:
   flag them for Opus, never improvise.
9. When the whole plan is done, launch the reviewer — fresh thread
   (`delegate_task`, provider `claudeAgent_free_claude`, options
   `{effort: high}`) — with the diff scope and the plan it was implemented
   against. Round 1 of high-risk code (core logic, money math, pipeline,
   security, concurrency) uses model `claude-opus-5-5`; round 1 of low-risk
   code and every round 2 onward use `claude-sonnet-5-5`. The reviewer loads its review skills
   before starting — `thermo-nuclear-code-quality-review` plus any matching
   the touched files. Ping-pong: fix every finding or answer
   with a disagreement until GREENLIGHT, max 3 rounds without it. Amend
   fixes into the relevant commits instead of creating new ones.
   - Each round is a new `delegate_task` (T3 rule). Its prompt carries the
     ping-pong so far: brief, findings, answers, open objections.
   - Round 2 onward checks only the fixes and what they touch, at effort
     high.
   - The reviewer checks HEAD only; the per-commit checks already ran and
     are not repeated by the reviewer or the orchestrator.
10. Publish a sideshow overview board of the finished change (the `sideshow`
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
