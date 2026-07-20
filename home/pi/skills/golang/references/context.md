# Go `context.Context`

`context.Context` propagates cancellation signals, deadlines, and request-scoped values across API boundaries and between goroutines. Think of it as the "session" of a request — it ties together every operation that belongs to the same unit of work.

## Core principles

1. **Propagate the same context through the entire request lifecycle**: HTTP handler → service → DB → external APIs. Breaking the chain breaks cancellation and tracing.
2. **`ctx` is the first parameter**, named `ctx context.Context`.
3. **Never store a context in a struct** — pass it explicitly through function parameters.
4. **Never pass `nil`** — use `context.TODO()` if you don't have one yet.
5. **`context.Background()` only at the top level** (main, init, tests). Never create a fresh `Background()` mid-request — it orphans the work from cancellation/tracing.
6. **Context value keys must be unexported types** to prevent collisions across packages.
7. **Context values carry only request-scoped metadata** (request ID, user ID, trace span) — never function parameters.
8. **Use `context.WithoutCancel`** (Go 1.21+) when spawning background work that must outlive the parent request (e.g. audit logs emitted after the response is sent).

## Picking the right context

| Situation | Use |
| --- | --- |
| Entry point (main, init, test) | `context.Background()` |
| Function needs a context but caller doesn't provide one yet | `context.TODO()` |
| Inside an HTTP handler | `r.Context()` |
| Need manual cancellation | `context.WithCancel(parent)` |
| Need a timeout | `context.WithTimeout(parent, duration)` |
| Need to know *why* it was cancelled | `context.WithCancelCause` / `context.Cause` (Go 1.20+) |

## The propagation rule

```go
// ✗ Breaks the chain — orphans this query from cancellation/deadlines
func (s *OrderService) Create(ctx context.Context, order Order) error {
    return s.db.ExecContext(context.Background(), "INSERT INTO orders ...", order.ID)
}

// ✓ Propagates the caller's context
func (s *OrderService) Create(ctx context.Context, order Order) error {
    return s.db.ExecContext(ctx, "INSERT INTO orders ...", order.ID)
}
```

Always use the `*Context` variants of I/O methods (`QueryContext`, `ExecContext`, `http.NewRequestWithContext`) so they respect deadlines.

## Listening for cancellation

In concurrent code, select on `<-ctx.Done()` so the goroutine can exit when the caller cancels:

```go
select {
case <-ctx.Done():
    return ctx.Err()
case result := <-work:
    return result
}
```
