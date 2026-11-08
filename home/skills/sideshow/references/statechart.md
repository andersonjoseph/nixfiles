# Statechart drawing rules

Ported from pstack's `statechart` skill (MIT),
https://github.com/cursor/plugins/tree/main/pstack/skills/statechart —
minus its TLA+/TLC checking.

The chart shows how a system moves between states, in the words of the
person who reads it. That person decides whether the behavior is right.

## Labels

- A state label names what the reader can see or cares about, such as
  "Paying" or "Lease held, write pending". Keep variable names out.
- A step label names how the user sees it happen, such as "you press play"
  or "the connect fails". Do not name the code or the function.
- When a step occurs only in some conditions, end its label with the
  condition in brackets, in the reader's words: "you press play [while
  the file loads]".
- When a value no label shows decides where a step goes, name the result
  in the label: "the roster read fails".

## Forms

- Flat: one label per state.
- Phases: parent states that group their states.
- Parallel regions: one parent state per region, when parts of the system
  move at once.

## Budget

Aim for about 20 arrows or fewer; a busier chart is hard to read. Coarsen:

- Give one label to values that act the same, and leave out detail the
  reader does not need, such as a call in flight whose return changes
  nothing.
- A step that stays in one label is not drawn. Split the label when the
  reader must see that step.
- You may hide steps the reader does not need, such as a reset every
  state has. Obey: keep every chart state reachable from a start state;
  keep at least one arrow out of each state that has a step out; hide all
  steps of an arrow or none; say in the post which steps the chart hides.

## Findings and hand-off

- Mark impossible states, missing transitions, and dead ends. Treat every
  gap the chart reveals as a finding to fix, not just a drawing.
- Say what the model leaves out, and give one line per known bug: the
  rule it breaks and the path through states that reaches it.
