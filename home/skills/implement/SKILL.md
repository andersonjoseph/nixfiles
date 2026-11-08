---
name: implement
description: Implement a plan in phases — a new implementer and a reviewer per phase, reviewer ping-pong, squash, sideshow overview.
argument-hint: "The plan to implement (path or pasted)"
disable-model-invocation: true
---

You are the orchestrator (Model roles in the personal instructions): you
own the plan, the dispatch, the review loop and the squash. The
implementer and the reviewer carry their own rules; do not repeat them
in briefs.

1. Restate the plan in your own words and confirm you have everything
   needed. A plan that is not step-complete in the `plan` skill's format —
   file-level steps, an acceptance check per step, every writer of a new
   write path listed — does not get implemented as-is: fix it first, or
   ask me. Wait for the go-ahead before dispatching.
2. Dispatch one phase at a time to an implementer (Model roles in the
   personal instructions). Every dispatch is a new implementer — the
   phase and each review-fix round alike; never resume an implementer
   session. A resumed session carries every earlier round in its
   context, and each call re-sends all of it. The brief carries the
   phase's steps, the plan path, the skills matching the touched files
   — always including `thermo-nuclear-code-quality-review` and every
   other skill the reviewer will load, so the implementer writes
   against the same House Rules the reviewer checks — and the
   absolute path and branch of this thread's checkout — the
   implementer works there and creates no worktree or branch. Before
   dispatch, check that the plan's branch is that branch. For a small
   job — a one-liner, a rename — skip the dispatch and do it yourself
   under the implementer's rules; do not turn small tasks into ceremony.
   - Handoff: the brief tells the implementer to end its dispatch with a
     short sideshow post (the `sideshow` skill) in this task's session:
     commits with SHAs, decisions taken, what is open. The next
     implementer's brief names that post; it reads the session's posts
     before starting. The code and git carry the state, the post carries
     the why.
3. When a phase returns, launch its reviewer at once with the phase's
   commits and the plan — one reviewer per phase, never one review at
   the end. The reviewer runs in a fresh thread, loads its review
   skills before starting — `thermo-nuclear-code-quality-review` plus
   any matching the touched files — checks the phase's diff against the
   plan, and confirms each finding against the code before reporting
   it. Its consumer trace also covers what earlier phases of the branch
   added and this phase reads, so a chain that spans phases gets checked
   where it closes.
4. Tier — reviewers from Model roles in the personal instructions:
   round 1 of a high-risk phase (core logic, money math, pipeline,
   security, concurrency) goes to the Opus reviewer; round 1 of a
   low-risk phase (UI only, refactors, release notes, docs) and every
   round 2 onward goes to the Sonnet reviewer. Both at effort high;
   effort max only when the user asks for it.
5. Ping-pong: send the reviewer's findings to a new implementer, with
   the previous handoff post; it fixes each one or disagrees. Send its fixup SHAs and answers to the
   next reviewer round. Round 2 onward checks only the fixes and what
   they touch; the reviewer checks HEAD and repeats no green run. Stop
   at GREENLIGHT, or after 3 rounds without it and report what remains.
   Every round is a new subagent launch whose prompt carries the
   ping-pong so far — brief, findings, answers, open objections. A
   finding whose fix only deletes code — a dead field, an unused return
   value, a wrapper — is fixed in the same round, even when the reviewer
   calls it a nit; never defer it.
6. After GREENLIGHT, run `git branch --show-current`, then squash with
   `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`. Squashes
   and history re-cuts are their own job: do them yourself or in a
   separate launch after GREENLIGHT, never inside a fix round. Then
   start the next phase.
7. After the last phase, check that no `fixup!` commit remains and give me
   the push command. The PR text, the push and the PR are mine.
8. Publish a sideshow overview board of the finished change (the
   `sideshow` skill): mermaid architecture and data flow, an end-to-end
   markdown narrative, and diff parts only for the critical code (the
   `sideshow` skill's diff rule). Do not wait for comments; I reply in chat.
