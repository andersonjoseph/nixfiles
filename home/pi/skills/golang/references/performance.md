# Go Performance

## Core philosophy

1. **Profile before optimizing** — intuition about bottlenecks is wrong ~80% of the time. Use pprof to find actual hot spots.
2. **Allocation reduction yields the biggest ROI.** Go's GC is fast but not free; cutting allocations per request usually matters more than micro-optimizing CPU.
3. **Document optimizations.** Add a comment explaining *why* a pattern is faster, with benchmark numbers when you have them. Future readers (and you) need that context to avoid reverting an "unnecessary" optimization.

## Rule out external bottlenecks first

Before optimizing Go code, confirm the bottleneck is actually *in* your process. If 90% of latency is a slow DB query or upstream API call, allocation work won't help.

- **`fgprof`** captures on-CPU *and* off-CPU (I/O wait) time. If off-CPU dominates, the bottleneck is external.
- **`go tool pprof` (goroutine profile)** — many goroutines stuck in `net.(*conn).Read` or `database/sql` means external wait.
- **Distributed tracing** (OpenTelemetry) — span breakdown shows which upstream is slow.

When the bottleneck is external, fix that component (query tuning, caching, connection pools, circuit breakers) instead.

## Iterative methodology

The cycle: **Define goals → Benchmark → Diagnose → Improve → Benchmark**.

1. **Define your metric** — latency, throughput, memory, or CPU? Without a target, optimization is random.
2. **Write an atomic benchmark** — isolate one function per benchmark so results aren't contaminated.
3. **Measure baseline** — `go test -bench=BenchmarkMyFunc -benchmem -count=6 ./pkg/... | tee /tmp/report-1.txt`
4. **Diagnose** — pick the tool from the table below.
5. **Improve** — apply **one** change at a time, with an explanatory comment.
6. **Compare** — `benchstat /tmp/report-1.txt /tmp/report-2.txt` to confirm statistical significance.
7. **Commit** — paste the benchstat output in the commit body so reviewers see the exact improvement.
8. **Repeat** for the next bottleneck. Keep the `/tmp/report-*.txt` files as an audit trail.

## Decision tree: where is time spent?

| Bottleneck | Signal (from pprof) | Look at |
| --- | --- | --- |
| Too many allocations | `alloc_objects` high in heap profile | Memory: `sync.Pool`, backing-array reuse, struct alignment, `strings.Builder` |
| CPU-bound hot loop | function dominates CPU profile | Inlining, cache locality, reflection avoidance |
| GC pauses / OOM | high GC%, container limits | Runtime: `GOMEMLIMIT`, `GOGC`, `GOMAXPROCS`, PGO |
| Network / I/O latency | goroutines blocked on I/O | HTTP transport config, streaming, batching |
| Repeated expensive work | same computation/fetch repeatedly | Caching, `singleflight`, work avoidance |
| Wrong algorithm | O(n²) where O(n) exists | Algorithmic complexity |
| Lock contention | mutex/block profile hot | Worker pools, sharding, less locking |

## Common mistakes

| Mistake | Fix |
| --- | --- |
| Optimizing without profiling | Profile with pprof first — intuition is wrong ~80% of the time |
| Default `http.Client` without a configured `Transport` | `MaxIdleConnPerHost` defaults to 2; set it to match your concurrency level |
| Logging in hot loops | Log calls prevent inlining and allocate even when the level is disabled. Use `slog.LogAttrs` and guard hot paths |
| `panic`/`recover` as control flow | `panic` allocates a stack trace and unwinds the stack — return errors |
| `unsafe` without benchmark proof | Only justified when profiling shows a large win in a verified hot path |
| No GC tuning in containers | Set `GOMEMLIMIT` to ~80–90% of container memory to prevent OOM kills |
| `reflect.DeepEqual` in production | 50–200× slower than typed comparison — use `slices.Equal`, `maps.Equal`, `bytes.Equal` |
