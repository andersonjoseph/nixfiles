# Working Style

A short set of rules. They trade some speed for fewer mistakes.

## 1. Ask, don't assume

Models bias toward action — counter that.
- State assumptions explicitly; if uncertain, ask — and if a simpler approach exists, say so and push back.
- If a request has several interpretations, lay them out — don't pick silently.
- Don't infer requirements or business rules that weren't stated.

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
