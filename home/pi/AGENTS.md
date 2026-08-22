# Working Style

A short set of rules. They trade some speed for fewer mistakes.

## 1. Ask, don't assume

Models bias toward action — counter that.
- State assumptions explicitly; if uncertain, ask — and if a simpler approach exists, say so and push back.
- If a request has several interpretations, lay them out — don't pick silently.
- Don't infer requirements or business rules that weren't stated.
- Questions are read-only. If the user asks a question, answer it — don't edit files, run mutating commands, or fix anything. Changes only happen when asked for.

## 2. Do the least that solves it

Nothing speculative.
- No features, flags, or "flexibility" beyond what was asked.
- No abstraction for single-use code; no error handling for impossible cases.
- If 50 lines do what 200 would, rewrite.

## 3. Integrate, don't accrete

Code you touch should read as if designed with the change in mind — not bolted on after the fact.
- If a signature change makes the feature cleaner, change it and update callers.
- If your change makes a method, variable, or branch obsolete, remove it — that's part of the change, not optional cleanup.
- If two things can merge into one now, merge them.
- Clean only where you're already working. Unrelated code you happen to notice? Leave it.

Final check: if you were writing the touched code from scratch, would it look like this? If not, fix it before moving on.

## 4. Plan before coding — proportionally

For non-trivial work, propose a plan and wait for approval before touching files. Scale it to the job: a one-line fix needs none; a new feature needs enough that you and the user agree on shape and scope before code is written. Don't turn small tasks into ceremony.

**Plan format** — whenever you present a plan (proposing one, or as the output of a grilling session):
- **One ASCII call graph / data-flow diagram that carries the logic** — entry point, calls and branches, decision points and exit conditions. The graph *is* the key logic; don't add a separate pseudocode block. One graph, not before/after. ASCII so it renders anywhere.
- **Types & interfaces** to add or change, when they clarify.
- **Files to touch**, one line each, marked `NEW`/`EDIT` with the intent.
- **Open questions**, if any (see rule 1).

## Design Rules

Elaborates rules 2 and 3 into code shape. Happy-path-first, use-case-oriented design, distilled from [Code like Luke](https://gist.github.com/Hona/53142c07c9decb735392f132ace34003). When in doubt about applying any of these, fetch that gist (ketch scrape or curl) for the DON'T/DO examples, the vocabulary table, and the source essays.

1. **Happy path first.** If the happy path is 95% of runtime behavior, it should be roughly 95% of the code readers see. Top-level methods read like the use case and orchestrate well-named services; parsing, protocol details, process plumbing, and state surgery sink below them.

   DON'T make the orchestrator own every detail:
   ```go
   func update(input string) error {
       if input == "" {
           return errors.New("missing version")
       }
       out, err := exec.Command("wsl", "bash", "-lc", buildScript(input)).CombinedOutput()
       if err != nil {
           return fmt.Errorf("%w: %s", err, out)
       }
       installed := parseVersion(mustRun("version"))
       if installed != input {
           return errors.New("wrong version installed")
       }
       return restart()
   }
   ```
   DO expose the use case and push mechanics behind deep boundaries:
   ```go
   func update(v Version) error {
       if err := server.Stop(); err != nil {
           return err
       }
       if err := cli.InstallExact(v); err != nil {
           return err
       }
       return server.Start()
   }
   ```

2. **Guard clauses, flat flow.** Invalid conditions leave early. The valid path stays flat and linear, never nested inside defensive branches.

   DON'T bury the valid path in nested conditionals:
   ```ts
   if (config) {
     if (config.enabled) {
       if (server.ready) {
         return run(config)
       }
     }
   }
   ```
   DO reject invalid conditions first and leave the valid path flat:
   ```ts
   if (!config) return
   if (!config.enabled) return
   assert(server.ready)
   return run(config)
   ```

3. **Parse, don't validate.** Validate external, persisted, and network data once at the boundary, into trusted domain types. Internal methods receive trusted values, not re-checked raw strings. Prefer domain types for meaningful IDs, states, and versions; model legal states directly instead of nullable-field-and-boolean combos when practical.

   DON'T validate raw values and then throw away what the check proved:
   ```go
   validateVersion(input)
   install(input) // still a raw string
   ```
   DO parse into a trusted domain value once:
   ```go
   v, err := ParseVersion(input)
   if err != nil {
       return err
   }
   install(v) // internal code receives a Version, never re-checks it
   ```

   DON'T represent mutually exclusive states with nullable fields and booleans:
   ```ts
   type Server = {
     starting: boolean
     url?: string
     error?: string
   }
   ```
   DO model the legal states directly:
   ```ts
   type ServerState =
     | { kind: "stopped" }
     | { kind: "starting" }
     | { kind: "ready"; url: ServerUrl }
     | { kind: "failed"; error: ServerError }
   ```

4. **Deep modules, not helper shrapnel.** Extract only operations that hide real complexity behind a small interface. No shallow pass-through chains (Controller → Service → Repository that rename one call), no `prepareUpdate()/doUpdate()/finishUpdate()`.

5. **Patterns must pay rent.** Every layer, interface, and file is a cost, paid only when it buys a concrete readability, correctness, testing, or change-isolation gain larger than that cost. Duplication is cheaper than the wrong abstraction. Start with the smallest honest use-case implementation; extract a port, service, or module only when it owns a real invariant, hides real complexity, or removes stable duplication (rule of three).
6. **Evidence before complexity.** No machinery for imagined edge cases. Complexity is justified by an observed failure (runtime, log, test repro, user report) plus its likelihood, never by "could" or "what if". When evidence arrives, fix the smallest real failure at the boundary that owns it, not a general defense framework.
7. **One owner per state.** Tell the owner the domain operation (`session.promote(message)`); don't read its state and mutate it elsewhere. Domain decisions stay out of IO wrappers; IO stays in infrastructure.
8. **Tests at stable boundaries.** Prove behavior through real use-case boundaries. Don't test one-line helpers or mirror implementation sentence by sentence.

Completion standard: finish the whole change, run focused verification, delete temporary artifacts, do one final simplification pass. The result should feel boring, obvious, typed, cohesive, and native to the codebase.

## Writing

Applies to any text you produce for the user: summaries, explanations, scripts, messages, PR descriptions.

- No em dashes or en dashes as punctuation. Use commas, periods, colons, or parentheses. Compound-word hyphens (`one-time`, `free-text`) are fine.
- Write like a normal person, not an LLM. No "leverage", "delve", "robust", "seamless", "it's worth noting", or hedging filler. Direct, plain, a little conversational.
- Don't over-structure or pad. Skip formulaic intro/summary bookends, the reflex to bullet-point everything, and restating the request back. Say the thing and stop.
