---
name: retro
description: Review the current session and its subagent sessions for friction, errors, and gotchas, then propose improvements for future runs.
argument-hint: "Optional topic or session to focus on"
disable-model-invocation: true
---

Goal: find what slowed this work down and propose concrete fixes. Facts first,
no blame. Decisions stay with the user.

## 1. Gather sources

- Current session: already in context — do not re-read it.
- Session transcripts, read-only: `opencode session list` shows the
  sessions of the current project, newest first, including subagent child
  sessions; `opencode session export <id>` dumps one as JSON. Read a few
  messages to learn the schema before mining — the conversation and the
  tool executions (the richest friction signal: repeated reads, failed
  commands, retries) are all in there.
- Delegated subagent threads are child sessions of the one under review —
  export them too when the work was delegated.
- Use token-heavy stretches, repeated file reads, and long back-and-forth
  as friction signals; dig where they are out of line.
- Never write to anything in those transcript directories.

## 2. Mine for friction

Walk the transcripts in order; flag errors and retries (failed commands, wrong
flags or paths, the same call twice), wrong turns (dead-end exploration, work
undone by a correction), slow loops (token-heavy back-and-forth, re-read files,
a skill that should have loaded and did not), permission friction, and
environment gaps.

## 3. Map findings to fixes

Each finding: one line on what happened, the friction cost, the candidate fix,
and effort (one-liner / small / project). Fixes land in guidance (AGENTS.md
rules, skill descriptions), skills, checks (verify what already exists before
proposing), or tooling. Only findings observed in the transcripts; mark
inferences as inferred.

## 4. Present and decide

Present findings in chat, ordered by friction cost. Write no files. Ask which
to act on; act only on the chosen ones.
