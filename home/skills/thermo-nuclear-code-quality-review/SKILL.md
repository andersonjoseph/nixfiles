---
name: thermo-nuclear-code-quality-review
description: Run an extremely strict maintainability review for abstraction quality, giant files, and spaghetti-condition growth. Use for a thermo-nuclear code quality review, thermonuclear review, deep code quality audit, or especially harsh maintainability review.
metadata:
  source: https://github.com/cursor/plugins/tree/main/cursor-team-kit/skills/thermo-nuclear-code-quality-review
---

# Thermo-Nuclear Code Quality Review

Two roles share this file. An implementer whose code this review will cover
applies `Rules when writing code` and skips the rest. A reviewer runs the
whole file.

Above all, be ambitious about structure. Do not collect local cleanup nits;
search for the code-judo move — the reframing that keeps behavior while
deleting whole branches, helpers, modes or layers. The solution should feel
inevitable in hindsight.

## Rules when writing code

Non-negotiable while writing, before any review sees the code:

- Every new field, export, parameter, return value (each key of a returned
  object) and file has a reader outside tests. No reader — do not write it.
- The consumer holds the value directly when it can. No map, `find`, registry
  or string-keyed lookup that one consumer resolves once. A lookup by a
  display string (a label, a title, a user-visible name) is always wrong.
- Do not push a file from under 1k lines to over 1k lines. When the diff
  crosses the line, ask whether to decompose it first: extract helpers,
  subcomponents or modules.
- No ad-hoc conditional, special case or one-off branch inside an unrelated
  flow. Give the logic its own helper, module or abstraction.
- No thin wrapper, identity abstraction, pass-through helper,
  cast / `any` / `unknown` that hides the real contract, or silent fallback
  that papers over an unclear invariant. Boring, direct, maintainable code
  beats hacky or magical code.
- Reuse the canonical helper; never write a near-duplicate. Feature logic
  stays out of shared paths; logic lives in the layer that owns the concept.
- Prefer the reframing that deletes branches — a state machine, a typed
  model, a dispatcher, a registry — over rearranging the same complexity.
- Serialize only what depends on the result; keep related updates atomic.
- The plan is not a defense. When the plan prescribes a wrapper, a lookup
  layer, or a second type for the same data, report the plan problem before
  implementing it.

## Review procedures

Run both on every review, before anything else.

### The plan is not a defense

If the plan prescribes structure these rules would flag — a lookup layer, a
wrapper, a second type for the same data — report it as a **plan finding**:
what to change in the code and in the plan. Do not pass it because the
implementer followed the plan.

### Consumer trace

- For every new type field, export, parameter, return value (including each
  key of a returned object) and file in the diff, name one reader outside
  tests. No reader is a finding: delete it.
- For every value reached through a lookup — a map from a key to something
  defined in the same codebase, a `find` on a list by a literal, a string key
  resolved to a component or function — ask whether the consumer can hold the
  value directly. If it can, the lookup is a finding.
- A lookup by a display string is always a finding: a rename breaks it
  silently and no type check sees it.

## Flag list

Every violated rule above is a finding. Escalate these review-side shapes:

- A complicated implementation where a reframing could delete whole
  categories of complexity.
- Refactoring that moves code around without reducing the concepts a reader
  must hold.
- Copy-pasted logic instead of an extracted or existing helper.
- Narrow edge-case handling inserted into the middle of a busy function.
- One-off booleans, nullable modes, or flags that complicate existing
  control flow.
- "Temporary" branching likely to become permanent debt.
- A previously cohesive module made more coupled, more stateful, or harder
  to scan.
- Casts, optionality or ad-hoc object shapes that obscure the real
  invariant.
- Sequential async flow where independent work could run in parallel;
  partial updates that leave state less atomic than necessary.

## Tone, output, approval

Be direct, serious, demanding. Do not soften structural issues into nits.
Report a small number of high-conviction findings, ordered: structural
regressions, missed simplifications, branching growth, boundary and
type-contract problems, file size and decomposition, legibility. Prefer
remedies that delete a layer, a branch, or an exception path over remedies
that polish. Approve
only with no structural regression, no visible simplification left on the
table, no unjustified file-size explosion, and no violated rule. A violated
rule is a presumptive blocker unless the author justifies it clearly.
