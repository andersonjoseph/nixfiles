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
2. Dispatch one phase at a time, each phase to a new implementer (Model
   roles in the personal instructions). The brief carries the phase's
   steps, the plan path, and the skills matching the touched files. For a
   small job — a one-liner, a rename — skip the dispatch and do it
   yourself under the implementer's rules; do not turn small tasks into
   ceremony.
3. When a phase returns, launch its reviewer at once with the phase's
   commits, the plan, the skills matching the touched files, at the tier
   its risk gets (Reviews in the personal instructions). Its consumer
   trace also covers what earlier phases of the branch added and this
   phase reads, so a chain that spans phases gets checked where it
   closes.
4. Ping-pong: send the reviewer's findings to the phase's implementer; it
   fixes each one or disagrees. Send its fixup SHAs and answers to the
   same reviewer. Stop at GREENLIGHT, or after 3 rounds without it and
   report what remains. Rounds reach the agents per harness: omp
   continues the same agents with `write agent://<name>`; under T3 (pi,
   claude) every round is a new `delegate_task` whose prompt carries the
   ping-pong so far — brief, findings, answers, open objections. A
   finding whose fix only deletes code — a dead field, an unused return
   value, a wrapper — is fixed in the same round, even when the reviewer
   calls it a nit; never defer it.
5. After GREENLIGHT, run `git branch --show-current`, then squash with
   `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`. Then start
   the next phase.
6. After the last phase, check that no `fixup!` commit remains and give me
   the push command. The PR text, the push and the PR are mine.
7. Publish a sideshow overview board of the finished change (the
   `sideshow` skill): mermaid architecture and data flow, an end-to-end
   markdown narrative, one diff part per commit. Wait for my comments and
   reply or revise.
