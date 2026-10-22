# Personal guidance for every omp session (anderson). omp loads this global
# file together with each project's context — where they disagree, the
# project's wins. Hard rules that must never weaken live in RULES.md; this
# file is the standing background.

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

## Model roles

Subagents go through the task tool. Roles, split by strength:

- **Main session (GLM 5.3)** — planner, orchestrator; keeps the hardest
  parts: tricky concurrency, security-sensitive code, core architecture
  changes.
- **implementer agent (GLM 5.3, high effort)** — executes a well-scoped
  plan.
- **reviewer agent (GLM 5.3, high effort, fresh session)** — reviews the
  finished diff against its plan.
- **scout agent (GLM-5.3-Flash)** — read-only exploration, summaries,
  lookups.

Roles map to models in `modelRoles` (config.yml); swapping a model never
touches an agent file.

Rules:

- Plans are written for the implementer as the reader: file-level steps,
  one bounded action each, an acceptance check per step. It executes scoped
  work well and reasons worse in the open — never leave a step open-ended.
- Delegate implementation as one task (`agent: implementer`) — the whole
  plan; it commits per step and runs the tests between them without
  waiting.
- Delegate exploration and light subagent work to `scout`.
- Skills load in the agent doing the work — never in the parent
  orchestrating it. Name the skills in the task brief; the child reads
  them. Keep skill bodies out of the orchestrator's context.
- When the implementer escalates a hard part back, take it over in the
  main session.

## Reviews

- Run the review as a fresh `reviewer` task spawn with the diff scope and
  the plan it was implemented against. Name its skills in the brief —
  `thermo-nuclear-code-quality-review` plus any matching the touched files.
- Ping-pong with the implementer until GREENLIGHT; after 3 rounds without
  greenlight, stop and report what remains.
- Each round is a new task spawn. Its prompt carries the ping-pong so far:
  the brief, each earlier finding, the answer to it, and what is still
  open.
- Round 2 onward is scoped to the fixes and what they touch; it does not
  re-review code an earlier round marked correct.
- The reviewer checks HEAD only. The implementer already ran the checks on
  each commit — neither the reviewer nor the orchestrator repeats them.
- Review fixes go in as `git commit --fixup=<sha>` commits; the
  orchestrator squashes them.
- Tests: only the packages the change touches, never the whole suite.

## Habits

- Visuals go through the sideshow skill (mermaid or html surfaces) — but only
  when I ask to explain or visualize something, or when a visual clearly
  beats prose. Standalone HTML files only when the user explicitly asks for
  one.
- Changing a gate (flag/boolean)? Grep the flag across the feature
  directory and open every hit — gates repeat across components.
- Read the exact block before an edit; prefer a whole-file write for new
  or heavily edited files.
