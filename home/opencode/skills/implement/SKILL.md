---
name: implement
description: Implement a plan end to end — relevant skills, minimal comments and tests, unit-of-work commits, reviewer ping-pong, commit walkthrough.
argument-hint: "The plan to implement (path or pasted)"
disable-model-invocation: true
---

Implement the plan. First restate it in your own words and confirm you have
everything needed. Stop and ask about anything missing or ambiguous. Wait for
the go-ahead before writing code.

1. Load the relevant skills for the work — whichever match the files you are
   going to modify.
2. Comments: near zero, self-documenting code, no inline comments. The only
   allowed comment sits at the top of a function body or package definition
   when the why is not obvious. No redundant, AI-slop, or LLM-verbatim
   comments. All prose in ASD-STE100.
3. Tests: only when they are worth it and necessary. No redundant tests, no
   tests for the sake of it, no AI-slop tests.
4. Build on what exists. Search for existing helpers before writing new ones.
   Three functions doing the same job across the codebase is a failure.
5. One commit = one unit of work to review.
6. When done, launch the reviewer subagent with the diff scope. Ping-pong:
   fix every finding or answer with a disagreement and reach agreement.
   Continue the same reviewer session (sessionID) until it confirms all
   findings are addressed, max 3 rounds without greenlight (Reviewer
   ping-pong rules in the personal AGENTS.md). Amend fixes into the relevant
   commits instead of creating new ones.
7. Then generate a commit walkthrough of the commits (the
   `commit-walkthrough` skill when available) and post the page for the
   user to review.

## Landing (jungle-rabbit)

Every branch comes off `master`. The user opens the PR against `master`,
and the same branch is then merged into `develop` to keep `develop` in
sync with `master`. Never commit straight to `develop`. Do not ask which
way to land — this is the answer.
