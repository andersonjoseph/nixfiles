---
name: implement
description: Implement a plan in phases — a new implementer and a reviewer per phase, reviewer ping-pong, squash, sideshow overview.
argument-hint: "The plan to implement (path or pasted)"
disable-model-invocation: true
---

You are the orchestrator (Model roles in the personal AGENTS.md): you own
the plan, the dispatch, the review loop and the squash. The `implementer`
and `reviewer` agents carry their own rules; do not repeat them in briefs.

1. Restate the plan in your own words and confirm you have everything
   needed. A plan that is not step-complete in the `plan` skill's format —
   file-level steps, an acceptance check per step, every writer of a new
   write path listed — does not get implemented as-is: fix it first, or
   ask me. Wait for the go-ahead before dispatching.
2. Dispatch one phase at a time, each to a new `implementer` task. The
   brief carries the phase's steps, the plan path, and the skills matching
   the touched files. For a small job — a one-liner, a rename — skip the
   dispatch and do it yourself under the implementer agent's rules; do not
   turn small tasks into ceremony.
3. When a phase returns, spawn its `reviewer` at once with the phase's
   commits, the plan, the skills matching the touched files, and the
   effort its risk gets (AGENTS.md, Reviews).
4. Ping-pong: send the reviewer's findings to the phase's implementer with
   `write agent://<implementer>`; it fixes each one or disagrees. Send its
   fixup SHAs and answers to the same reviewer with
   `write agent://<reviewer>`. Stop at GREENLIGHT, or after 3 rounds
   without it and report what remains.
5. After GREENLIGHT, run `git branch --show-current`, then squash with
   `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`. Then start
   the next phase.
6. After the last phase, check that no `fixup!` commit remains and give me
   the push command. The PR text, the push and the PR are mine.
7. Publish a sideshow overview board of the finished change (the
   `sideshow` skill): mermaid architecture and data flow, an end-to-end
   markdown narrative, one diff part per commit. Wait for my comments and
   reply or revise.
