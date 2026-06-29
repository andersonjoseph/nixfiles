# Working Style

**Tradeoff:** These guidelines bias toward caution over speed. Even for trivial tasks, produce the full plan in Section 4.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Simple doesn't always mean adding less code — sometimes the simplest result requires reshaping or removing existing code (see Section 3).

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Integration, Not Accretion

**Your job is to integrate a change, not insert code into existing code.**

When adding or changing a feature, the code you touch should read as if it was designed with this feature in mind — not like the feature was
bolted on after the fact.

- If changing a function signature makes the new feature cleaner, change it and update all callers.
- If your approach makes a previous method or variable unnecessary, remove it.
- If nearby code can be simplified as part of your change, simplify it.
- If two things can be merged into one now, merge it.

**The accretion problem:** Every variable, method, or branch that survives past its usefulness becomes the style the next agent copies.
Removing what your change makes obsolete is not optional cleanup — it's part of the change.

**The boundary — clean only where you're already working:**
- You're reshaping the area your change touches, not refactoring the whole file.
- Code in unrelated areas that you just happened to notice? Leave it alone.
- If you're unsure whether something is related to your change, ask.

**The final check:** Look at the code you touched. If you were writing it from scratch, would you write it the same way? If not, fix it
before moving on.

## 4. Plan Before Implementing

When asked to build or extend a feature, **do not jump to code**.
Produce a plan first and wait for approval before touching files.

Produce the full 3-phase plan below for **every** feature, regardless of size.
Do not skip or abbreviate it for "small" or "trivial" changes.

#### Phase 1: Architectural Plan & Boundaries

Break the feature into a high-level modular plan. Explicitly identify:
- Where the core domain logic will live.
- Where the external infrastructure boundaries are (database persistence, external APIs, network/RPC boundaries, stateful actors).

#### Phase 2: Pseudo-Code, Types, & Interfaces

Write the pseudo-code, types, and interfaces that define boundaries and composition.
- Focus strictly on types, interfaces, and function signatures.
- Do not write concrete method implementations.
- Use clean dependency injection or modular layer-based patterns so infrastructure can be swapped easily.

#### Phase 3: Modification Map (To-Dos)

List the exact changes the codebase needs, as a concrete to-do list:
- Which files are created, modified, or removed.
- Which functions/signatures change and what their callers must be updated to.
- Which DB tables, queries, or migrations are touched.
- Which tests are added or updated.

This is the bridge between the plan and implementation: every item should be
specific enough that someone else could execute it without re-deriving the design.
If an item is vague ("clean up the handler"), make it specific or drop it.

Only after the plan is approved, proceed to implementation (still following rules 1-3).

## 5. How Features Are Described

The user will describe features in natural language — explaining the business flow,
what happens in the UI, what triggers what, and what actors are involved
(e.g., "expired products appear in a separate tab, we raise an alert,
category managers can move them back or remove them").

Translate that into the structured 3-phase plan. Ask clarifying questions if the
domain intent is ambiguous. Do not infer business rules that weren't stated.
