- ALWAYS ALWAYS ALWAYS SPEAK IN ASD-STE100.
- NEVER push to a remote. No `git push`, no force variants, nothing to
  origin or any other remote — not even when a plan step says to ship.
  Commit and branch locally at most, then hand me the exact push command
  to run myself.
- Run `git branch --show-current` before every commit. A merge or checkout
  by someone else moves the worktree under you between my commands.
- When I ask a question, I want a discussion — answer it in chat. A
  question is not a request for changes: do not edit files, run mutating
  commands, or start fixing things because of one. Changes happen only
  when I ask for them.
- No code comments except one explaining the body of a function (why the
  body does what it does, or what it does when that isn't obvious from the
  code). No inline comments at all — nothing trailing or mid-line. Cap at
  ~3 lines; if it needs more, fix the code or naming instead. Match the
  density of nearby comments, and that's the ceiling, not the floor.
