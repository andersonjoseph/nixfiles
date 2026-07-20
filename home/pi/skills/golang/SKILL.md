---
name: golang
description: Go design guidance and gotchas for writing production-ready code — concurrency, context, error handling, testing, performance, safety, and modern version-keyed idioms. Use when writing, reviewing, refactoring, or debugging Go code.
license: MIT
metadata:
  author: pi (distilled from JetBrains go-modern-guidelines and samber/cc-skills-golang)
  version: "1.0.0"
---

# Go

Design-level guidance and language gotchas for Go. Distilled from JetBrains'
`go-modern-guidelines` and samber's `cc-skills-golang`, keeping what models
don't reliably get right and what linters don't catch.

## When to apply

Reference this skill when:

- Writing, reviewing, or refactoring Go code
- Choosing concurrency primitives, context patterns, or error-handling strategies
- Diagnosing performance, correctness, or concurrency bugs
- Deciding which stdlib features to reach for at the project's Go version

## What this skill deliberately does NOT cover

Mechanical style and correctness that **`golangci-lint`** (or `go vet`) already
enforces is omitted to avoid redundancy — assume the linter catches:

- unchecked errors / errors discarded with `_` (`errcheck`)
- `%w` vs `%v` in `fmt.Errorf`, and `errors.Is`/`As` vs `==` (`errorlint`)
- capitalized/punctuated error strings (staticcheck `ST1005`)
- deprecated APIs (staticcheck `SA1019`) and many "use the modern stdlib" rewrites (`modernize`)
- formatting, imports, naming conventions, unused code

So this skill focuses on **design decisions and gotchas** linters can't see:
when to use a channel vs a mutex, the single-error-handling rule, the nil-interface
trap, slice backing-array aliasing, the profiling-before-optimizing discipline, etc.

## Modern Go idioms

When writing Go, prefer the modern stdlib features available in the project's
target version. Detect it from `go.mod`:

```bash
grep '^go ' go.mod
```

Use features up to and including that version; never use newer features, and
never use a legacy pattern when a modern alternative exists. The full
version-keyed (Go 1.0 → 1.26) "use X not Y" list is in
[`references/modern-idioms.md`](references/modern-idioms.md).

## Topic reference

| Topic | File | Covers |
| --- | --- | --- |
| Concurrency | [`references/concurrency.md`](references/concurrency.md) | structured concurrency, channel vs mutex vs atomic, WaitGroup/errgroup, sync primitives, goroutine leaks |
| `context.Context` | [`references/context.md`](references/context.md) | propagation, cancellation/deadlines, `Cause`, request-scoped values, `WithoutCancel` |
| Error handling | [`references/error-handling.md`](references/error-handling.md) | wrapping with context, `errors.Join`, the single-handling rule, sentinel vs typed, panic discipline, slog |
| Testing | [`references/testing.md`](references/testing.md) | table-driven tests, file/naming conventions, the assert-scope leak gotcha, fuzz/examples, leak detection |
| Performance | [`references/performance.md`](references/performance.md) | profile-first methodology, ruling out external bottlenecks, the decision tree, common allocation/CPU/GC mistakes |
| Safety | [`references/safety.md`](references/safety.md) | the nil-interface trap, nil map/slice/channel behavior, slice aliasing, numeric gotchas, defensive copies |

## How to use

Read the individual reference files for detailed guidance and examples:

```
references/concurrency.md
references/modern-idioms.md
```

Each reference is self-contained — load the one relevant to the task at hand.
