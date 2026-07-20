# Go Error Handling

Treat every error as an event that must either be **handled or propagated with context** — silent failures and duplicate logs are equally unacceptable.

(Mechanical correctness — unchecked errors, `%w` vs `%v`, `errors.Is`/`As` vs `==`, capitalized error strings — is enforced by `errcheck`, `errorlint`, and staticcheck `ST1005`. This reference covers the design decisions linters don't catch.)

## Design principles

1. **Wrap errors with context as they propagate** — `fmt.Errorf("doing X: %w", err)` so the chain tells the story of what went wrong at each layer. (The `%w` verb itself is linter-enforced; the discipline of *adding context at each boundary* is not.)
2. **Use `errors.Join`** (Go 1.20+) to combine independent errors — e.g. aggregating failures from parallel sub-tasks.
3. **The single-handling rule: an error is either logged OR returned, never both.** Logging a value you also return produces duplicate entries in aggregators and obscures the real failure site. Pick the boundary where the error is finally consumed (usually the top of the request) and log there; everywhere else, wrap and return.
4. **Sentinel errors for expected conditions, custom types for carrying data.** Sentinel (`var ErrNotFound = errors.New("not found")`) when the caller needs to branch on identity. A custom type when you need to attach structured context (a code, a retryable flag) the caller can inspect.
5. **Reserve `panic` for truly unrecoverable states** — never for expected error conditions. `panic`/`recover` is not control flow: it allocates a stack trace and prevents inlining.
6. **Never expose technical errors to users.** Translate internal errors to user-friendly messages at the boundary; log the technical detail separately.

## Structured logging of errors

- **Prefer `log/slog`** (Go 1.21+) for structured error logging — not `fmt.Println` or `log.Printf`. Attach the error as a structured attribute: `slog.Error("failed to process order", "id", id, "err", err)`.
- **Use log levels to indicate severity** — `Error` for failures, `Warn` for degraded-but-handled, `Info`/`Debug` for routine flow.
- **Keep log grouping low-cardinality.** Keep the message template stable and attach IDs, paths, and counts as attributes. Don't interpolate high-cardinality data (user input, full URLs) into the message — it defeats log grouping/aggregation.
- **Log HTTP requests** with middleware that captures method, path, status, and duration as attributes.
