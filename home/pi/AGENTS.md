# Personal guidance for every pi session (anderson). pi loads this global
# file together with each repo's AGENTS.md — where they disagree, the repo's
# wins.

ALWAYS ALWAYS ALWAYS SPEAK IN ASD-STE100.

## Who I am — Anderson

Systems and tooling (Nix, Go, agents).
I value clean code, simple solutions, performance, and solid engineering.
I hate complications and overengineered solutions. Work accordingly:

- Prefer the simplest design that solves the real problem; when two options
  tie, take the smaller one.
- No speculative abstraction — add structure when the third case shows up,
  not in anticipation of it.
- Deleting code is a win. A good refactor usually ends with fewer lines.
- Performance matters; measure before optimizing, never guess.
- When the straightforward solution to my request is complicated, that is a
  signal to push back and reframe — not to comply silently.

## Questions are discussions

When I ask a question, I want a discussion — answer it in chat. A question
is not a request for changes: do not edit files, run mutating commands, or
start fixing things because of one. Changes happen only when I ask for
them.

## Habits

- Visuals go through the sideshow skill (mermaid or html surfaces) — but only
  when I ask to explain or visualize something, or when a visual clearly
  beats prose. Standalone HTML files only when the user explicitly asks for
  one.
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
