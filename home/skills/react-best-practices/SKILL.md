---
name: vercel-react-best-practices
description: React performance optimization guidelines from Vercel Engineering, plus House Rules for every React task. Use when writing, reviewing, or refactoring React code. Triggers on React components, data fetching, bundle optimization, or performance improvements. Component API design and composition are composition-patterns.
license: MIT
metadata:
  author: vercel
  version: "1.0.0"
---

# Vercel React Best Practices

Performance optimization guide for React applications from Vercel: 59 rules
across 7 categories, prioritized by impact.

## House Rules

Non-negotiable, from explicit user feedback. Checked on every task, before the catalog below:

- **Default to no new hooks.** Every `useMemo` / `useCallback` / `useEffect` a diff introduces must be justifiable in one phrase: referential identity a consumer actually needs, a genuinely expensive computation, or a sync that can't be an event handler or a derived value. Two `format()` calls is not a memo; apply `rerender-simple-expression-in-memo` strictly.
- **Audit hooks before finishing.** List every hook your diff adds and justify each. If the justification is "just in case" or "reads nicer", replace with a plain const/function and delete the hook.
- **Comments only where code can't speak.** One short comment for a non-obvious contract, guard, or why-decision. Never narrate what the code plainly does; no multi-line essays introducing a block; if the name says it, no comment.
- **Reuse before writing.** Before adding a component, helper, formatter or colour constant, search `components/`, `utils/` and the nearest view that does the same job. Use what exists; extend it when it lacks one option. Never write a second version.
- **No view switches in JSX.** A ternary or `&&` that picks between two layouts or states becomes a named component with early returns. A ternary for a value (a class, a label) is fine.
- **Every field has a reader.** No contract field, returned value or export that nothing uses yet.
- **No file only for constants.** A constant lives next to its first user, or in the shared module that already holds its kind.
- **Tests use the real thing.** Render the real component with its real setup (e.g. registered grid modules). Mock only at the edge — a chart component, the network. No stubs or probes that skip the behaviour under test.

## Rule catalog

| Priority | Category | Impact | Prefix |
|----------|----------|--------|--------|
| 1 | Eliminating Waterfalls | CRITICAL | `async-` |
| 2 | Bundle Size Optimization | CRITICAL | `bundle-` |
| 3 | Client-Side Data Fetching | MEDIUM-HIGH | `client-` |
| 4 | Re-render Optimization | MEDIUM | `rerender-` |
| 5 | Rendering Performance | MEDIUM | `rendering-` |
| 6 | JavaScript Performance | LOW-MEDIUM | `js-` |
| 7 | Advanced Patterns | LOW | `advanced-` |

Read the rule files for the categories the task touches — each holds the
explanation, incorrect and correct examples, and references:

```
rules/async-parallel.md
rules/bundle-barrel-imports.md
```

The complete guide with all rules expanded: `references/full.md`.
