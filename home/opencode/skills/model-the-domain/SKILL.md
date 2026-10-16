---
name: model-the-domain
description: Apply when writing stateful logic, or when code branches a lot or repeats a shape assumption across files. Encodes the domain in a structure, a state machine first, instead of scattered conditionals.
---

Ported from pstack's `principle-model-the-domain` (MIT), Lauren Tan (@poteto),
https://github.com/cursor/plugins/tree/main/pstack/skills/principle-model-the-domain

Name the data shape before writing any logic. Encode the real domain in a
data structure; do not scatter it across conditionals. A structure that
matches the domain makes illegal states unrepresentable and deletes
branches. Choosing it at write time is cheap. Recovering it later reads as
a refactor and gets deferred.

Reach for:

- A state machine instead of scattered booleans, phases, or lifecycle checks.
- A typed model or discriminated union instead of loose parameters or
  repeated shape assumptions.
- A map, registry, or lookup table instead of branching spread across files.
- A reducer or command/event model instead of ad hoc state mutations.
- A module organized around one body of domain knowledge instead of a
  sequence such as load, validate, transform, save. Execution order is not
  ownership.

Do not force an abstraction. If the current shape is clear, local, and
unlikely to grow, boring code wins. Be skeptical of indirection that removes
no branches, no duplicated rules, and no invalid states.

The sign you skipped this: a new feature grows an existing if/else chain by
one more branch, a second boolean must stay in sync with the first, or
phase-named modules repeat the same domain rules across steps.

When the right shape is unclear, read `references/example.md` for a
before/after of five booleans collapsed into one five-state union.

In the reply, name the structure chosen and the specific choice it changed.
