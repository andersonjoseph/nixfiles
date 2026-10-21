# Go Concurrency

Go's concurrency model is built on goroutines and channels. Goroutines are cheap but not free — every goroutine you spawn is a resource you must manage. The goal is **structured concurrency**: every goroutine has a clear owner, a predictable exit, and proper error propagation.

## Core principles

1. **Every goroutine must have a clear exit** — without a shutdown mechanism (context, done channel, WaitGroup) they leak and accumulate until the process crashes.
2. **Share memory by communicating** — channels transfer ownership explicitly; mutexes protect shared state but make ownership implicit.
3. **Send copies, not pointers, on channels** — sending a pointer creates invisible shared memory and defeats the purpose of channels.
4. **Only the sender closes a channel** — closing from the receiver panics if the sender writes after close.
5. **Specify channel direction** (`chan<-`, `<-chan`) — the compiler prevents misuse at build time.
6. **Default to unbuffered channels** — larger buffers mask backpressure; use them only with measured justification.
7. **Always include `ctx.Done()` in `select`** — without it, goroutines leak after caller cancellation.
8. **Avoid repeated `time.After` in hot loops** — each call allocates a timer; use `time.NewTimer` + `Reset` for long-running loops.

## Choosing the primitive

| Scenario | Use | Why |
| --- | --- | --- |
| Passing data between goroutines | Channel | Communicates ownership transfer |
| Coordinating goroutine lifecycle | Channel + context | Clean shutdown via `select` |
| Protecting shared struct fields | `sync.Mutex` / `sync.RWMutex` | Simple critical sections |
| Simple counters, flags | `sync/atomic` | Lock-free, lower overhead |
| Many readers, few writers on a map | `sync.Map` | Optimized for read-heavy workloads. **Concurrent map read/write on a plain map is a hard crash** |
| Caching expensive computations | `sync.Once` / `singleflight` | Execute once or deduplicate |

## WaitGroup vs errgroup

| Need | Use |
| --- | --- |
| Wait for goroutines, errors not needed | `sync.WaitGroup` (Go 1.25+: `wg.Go`) |
| Wait + collect first error | `errgroup.Group` |
| Wait + cancel siblings on first error | `errgroup.WithContext` |
| Wait + limit concurrency | `errgroup.SetLimit(n)` |

## Sync primitives quick reference

| Primitive | Use case | Key notes |
| --- | --- | --- |
| `sync.Mutex` | Protect shared state | Keep critical sections short; never hold across I/O |
| `sync.RWMutex` | Many readers, few writers | Never upgrade an RLock to a Lock (deadlock) |
| `sync/atomic` | Counters, flags | Prefer typed atomics (Go 1.19+): `atomic.Int64`, `atomic.Bool` |
| `sync.Map` | Concurrent map, read-heavy | No explicit locking; use `RWMutex`+map when writes dominate |
| `sync.Pool` | Reuse temporary objects | Always reset before `Put()`; reduces GC pressure |
| `sync.Once` | One-time init | Go 1.21+: `OnceFunc`, `OnceValue`, `OnceValues` |
| `sync.WaitGroup` | Simple fire-and-wait | Go 1.25+: `wg.Go(func(){ ... })` for tasks that don't panic and don't propagate errors. For errors/cancellation/limits, use `errgroup` with context. |
| `x/sync/singleflight` | Deduplicate concurrent calls | Prevents cache stampede |
| `x/sync/errgroup` | Goroutine group + errors | `SetLimit(n)` replaces hand-rolled worker pools |

## Checklist before spawning a goroutine

- [ ] **How will it exit?** — context cancellation, channel close, or explicit signal
- [ ] **Can I signal it to stop?** — pass `context.Context` or a done channel
- [ ] **Can I wait for it?** — `sync.WaitGroup` or `errgroup`
- [ ] **Who owns the channels?** — creator/sender owns and closes
- [ ] **Should this be synchronous instead?** — don't add concurrency without a measured need

## Common mistakes

| Mistake | Fix |
| --- | --- |
| Fire-and-forget goroutine | Provide a stop mechanism (context, done channel) |
| Closing a channel from the receiver | Only the sender closes |
| `time.After` in a hot loop | Reuse `time.NewTimer` + `Reset` |
| Missing `ctx.Done()` in `select` | Always select on context to allow cancellation |
| Unbounded goroutine spawning | `errgroup.SetLimit(n)` or a semaphore |
| Sharing a pointer via a channel | Send copies or immutable values |
| `wg.Add` inside the goroutine | Call `Add` before `go` — `Wait` may return early otherwise |
| Mutex held across I/O | Keep critical sections short |

Always run `go test -race ./...` in CI to catch data races. Detect leaked goroutines in tests with `go.uber.org/goleak` (`goleak.VerifyTestMain` in `TestMain`).

## Further reading

- [Go Concurrency Patterns: Pipelines](https://go.dev/blog/pipelines)
- [Effective Go: Concurrency](https://go.dev/doc/effective_go#concurrency)
