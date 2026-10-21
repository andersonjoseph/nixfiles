---
name: implement
description: Implement a plan one step at a time — relevant skills, minimal comments and tests, unit-of-work commits, Opus review ping-pong, sideshow overview, hunk review.
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
6. Work one plan step at a time: implement the step, run the tests, check
   the step's acceptance checks, commit, stop at the step boundary. Do not
   start the next step until the current one is green — or until I say to
   continue.
7. A step that turns out underspecified or ambiguous is a plan bug — stop
   and get it fixed by Opus (or me) instead of guessing.
8. Tricky concurrency, security-sensitive code, core architecture changes:
   flag them for Opus, never improvise.
9. When the whole plan is done, launch the reviewer — Opus 5.5, effort max,
   fresh thread (`delegate_task`, provider `claudeAgent_free_claude`, model
   `claude-opus-5-5`, options `{effort: max}`) — with the diff scope and the
   plan it was implemented against. Ping-pong: fix every finding or answer
   with a disagreement; keep every round in the same reviewer thread until
   GREENLIGHT, max 3 rounds without it. Amend fixes into the relevant
   commits instead of creating new ones.
10. Publish a sideshow overview board of the finished change (the `sideshow`
    skill): mermaid architecture and data flow, an end-to-end markdown
    narrative, one diff part per commit. Wait for my comments and reply or
    revise.
11. Then walk me through the code: ask me to open `hunk show` (or `hunk
    diff`) in a terminal and use the `hunk-review` skill to navigate,
    comment, and highlight.

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
