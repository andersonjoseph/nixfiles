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

Subagents go through the task tool. Each role maps to a model in
`modelRoles` (config.yml), the only place that names a model; change models
with `/model` → Roles, never in a skill or an agent file.

- **Main session** (`default` role) — planner, orchestrator; keeps the
  hardest parts: tricky concurrency, security-sensitive code, core
  architecture changes.
- **`implementer` agent** (`@implementer`) — executes one phase of a plan; a
  new one per phase. Its rules live in its agent file.
- **`reviewer` agent** (`@review`) — reviews one phase and stays for every
  round of it; a new one per phase. Its rules live in its agent file.
- **`scout`** (bundled, `@explorer`) — read-only exploration, summaries,
  lookups.

Rules:

- Plans are written for the implementer as the reader: file-level steps,
  one bounded action each, an acceptance check per step. It executes scoped
  work well and reasons worse in the open — never leave a step open-ended.
- Delegate implementation one phase at a time, each phase to a new
  `implementer` task; it commits per step and runs the tests between them
  without waiting. It also takes the review fixes of its phase. The next
  phase never reuses it.
- Delegate exploration and light subagent work to `scout`.
- Noisy work (capture, debugging, tool setup) goes to a subagent from the
  start — never burn the orchestrator thread on it. One unit of work per
  session.
- Skills load in the agent doing the work — never in the parent
  orchestrating it. Name the skills matching the touched files in the task
  brief; skills an agent always needs are autoloaded by its agent file.
  Keep skill bodies out of the orchestrator's context.
- When the implementer escalates a hard part back, take it over in the
  main session.

## Reviews

- Spawn one `reviewer` per phase as soon as that phase's implementer
  returns — not one review at the end — with the phase's diff scope, the
  plan, and the skills matching the touched files.
- Effort by risk per phase, on the same model: high-risk phases (core
  logic, money math, pipeline, security, concurrency) spawn the reviewer
  with `effort: hi`; low-risk phases (UI only, refactors, release notes,
  docs) with `effort: med`. The reviewer keeps it for all rounds.
- Effort high is the default; effort max only when I ask for it
  (`task.maxEffort: high` caps `effort: hi`).
- Ping-pong with the implementer until GREENLIGHT; after 3 rounds without
  greenlight, stop and report what remains.
- Round 2 onward goes to the same reviewer with `write agent://<name>`:
  the fixup SHAs, the answer to each finding, and what is still open.
- Review fixes go in as `git commit --fixup=<sha>` commits; the
  orchestrator squashes them.

## Habits

- Visuals go through the sideshow skill (mermaid or html surfaces) — but only
  when I ask to explain or visualize something, or when a visual clearly
  beats prose. Standalone HTML files only when the user explicitly asks for
  one.
- Changing a gate (flag/boolean)? Grep the flag across the feature
  directory and open every hit — gates repeat across components.
- Read the exact block before an edit; prefer a whole-file write for new
  or heavily edited files.
