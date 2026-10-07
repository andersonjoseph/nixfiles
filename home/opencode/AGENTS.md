# Personal guidance for every OpenCode session (anderson). OpenCode loads this
# global file first, then each repo's AGENTS.md — where they disagree, the repo's
# wins.

ALWAYS ALWAYS ALWAYS SPEAK IN ASD-STE100.

## Habits

- Changing a gate (flag/boolean)? Grep the flag across the feature
  directory and open every hit — gates repeat across components.
- Read the exact block before an edit; prefer a whole-file write for new
  or heavily edited files.

## Git

- NEVER push to a remote. No `git push`, no force variants, nothing to origin
  or any other remote — not even when a plan step says to ship. Commit and
  branch locally at most, then hand me the exact push command to run myself.
- Run `git branch --show-current` before every commit. A merge or checkout by
  someone else moves the worktree under you between my commands.

## Comments

- No code comments except one explaining the body of a function (why the body does
  what it does, or what it does when that isn't obvious from the code).
- No inline comments at all — nothing trailing or mid-line.
- Cap at ~3 lines. If it needs more, fix the code or naming instead.
- Match the density of nearby comments, and that's the ceiling, not the floor.

## Response shape

- Answer first. The first line is the answer or the next action. Context and reasoning come after, if at all.
- Multi-step instructions are a numbered list: one bounded action per step.
- Cap any list at ~5 items. More than that, rank it or split "do now" vs "later".
- At most one tangent per response, offered as a separate question at the end, never inline.

Before sending, delete the first sentence if it announces what you are about to do ("Let me look at..."), the last if it recaps or asks "anything else?", and any "by the way" sidebar.

Target shape:

> Bad: "Great question! Your auth flow has a few moving pieces. Looking at `src/auth.ts`, `verifyToken` seems to use an older API. One approach would be updating it and running the tests. Hope this helps!"
>
> Good: "Update `jsonwebtoken`, rewrite `verifyToken` (`src/auth.ts:42-58`), then run `npm test -- auth.spec.ts`. Paste the first failing line if it breaks."

Final check: from the first line and last line alone, the reader should know what to do next and what just happened.

## Reviewer ping-pong

When I ask for a reviewer loop / thermo-nuclear review of changes:
0. Never launch the reviewer on your own initiative — not after a big refactor,
   not because a diff looks risky. Only when my message explicitly asks.
1. Launch the reviewer subagent with the diff scope.
2. Fix every finding (or include a rebuttal for the next round).
3. Continue the SAME reviewer session via its sessionID — never a fresh one —
   asking it to verify the fixes.
4. Repeat until it returns GREENLIGHT; after 3 rounds without greenlight, stop
   and report what remains rather than looping forever.
