# Modern Go Idioms

Modern, version-keyed Go idioms — "use feature X instead of legacy pattern Y." When writing or reviewing Go, prefer the modern stdlib features available in the project's target version.

## Detecting the target version

Find the project's Go version from `go.mod`:

```bash
grep '^go ' go.mod
```

Use ALL features up to and including that version. Never use features from a newer Go version than the target, and never use an outdated pattern when a modern alternative exists. If there is no `go.mod` (or the version is unclear), ask which Go version to target.

## Annotations

Entries marked with observed-frequency and tooling data from JetBrains' [go-modern-guidelines](https://github.com/JetBrains/go-modern-guidelines) catalog:

- **Impact** — Critical / High / Medium / Low: how often the legacy pattern appears in a typical project (Critical = dozens of occurrences, Low = rare). When reviewing code, hunt the Critical and High ones first.
- **`go fix`** — the modernize analyzer rewrites the legacy pattern automatically, so on existing code `go fix ./...` does the cleanup. This reference exists so new code is written modern the first time.

---

## Go 1.0+

- `time.Since` (High): `time.Since(start)` instead of `time.Now().Sub(start)`

## Go 1.8+

- `time.Until` (Medium): `time.Until(deadline)` instead of `deadline.Sub(time.Now())`

## Go 1.13+

- `errors.Is` (Critical): `errors.Is(err, target)` instead of `err == target` (works with wrapped errors)

## Go 1.18+

- `any` (Critical, `go fix`): Use `any` instead of `interface{}`
- `bytes.Cut` (Medium): `before, after, found := bytes.Cut(b, sep)` instead of Index+slice
- `strings.Cut`: `before, after, found := strings.Cut(s, sep)`

## Go 1.19+

- `fmt.Appendf` (Medium, `go fix`): `buf = fmt.Appendf(buf, "x=%d", x)` instead of `[]byte(fmt.Sprintf(...))`
- `atomic.Bool`/`atomic.Int64`/`atomic.Pointer[T]` (Medium): Type-safe atomics instead of `atomic.Value` + type assertion (which can panic) or `atomic.StoreInt32`

```go
var flag atomic.Bool
flag.Store(true)
if flag.Load() { ... }

var ptr atomic.Pointer[Config]
ptr.Store(cfg)
```

## Go 1.20+

- `strings.Clone` / `bytes.Clone` (Medium): copy without sharing backing memory — replaces `string([]byte(s))` and `append([]byte(nil), b...)`
- `strings.CutPrefix/CutSuffix` (High, `go fix`): `if rest, ok := strings.CutPrefix(s, "pre:"); ok { ... }` instead of `HasPrefix` + `TrimPrefix`
- `errors.Join` (High): `errors.Join(err1, err2)` to combine multiple errors — `errors.Is`/`errors.As` check all wrapped errors
- `context.WithCancelCause` (Medium): `ctx, cancel := context.WithCancelCause(parent)` then `cancel(err)` — `ctx.Err()` stays generic but `context.Cause(ctx)` returns the actual reason
- `context.Cause` (Medium): `context.Cause(ctx)` to get the error that caused cancellation

## Go 1.21+

**Built-ins:**
- `min`/`max` (High, `go fix`): `max(a, b)` instead of if/else comparisons
- `clear` (Medium): `clear(m)` to delete all map entries, `clear(s)` to zero slice elements

**slices package:**
- `slices.Contains` (Critical, `go fix`): `slices.Contains(items, x)` instead of a search loop with a `found` flag
- `slices.Index` (Medium): `slices.Index(items, x)` returns index (-1 if not found) instead of a manual index-search loop
- `slices.SortFunc` (High, `go fix`): `slices.SortFunc(items, func(a, b T) int { return cmp.Compare(a.X, b.X) })` instead of `sort.Slice` — simpler and faster
- `slices.Sort`: `slices.Sort(items)` for ordered types
- `slices.Max`/`slices.Min` (Medium): instead of a manual loop
- `slices.Reverse` (Medium): instead of a manual swap loop
- `slices.Compact` (Low): removes consecutive duplicates in-place
- `slices.Clip`: `slices.Clip(s)` drops unused capacity
- `slices.Clone`: `slices.Clone(s)` creates a copy

**maps package:**
- `maps.Clone` (Medium): `maps.Clone(m)` instead of a manual copy loop
- `maps.Copy` (Medium, `go fix`): `maps.Copy(dst, src)` replaces `for k, v := range src { dst[k] = v }`
- `maps.DeleteFunc` (Low): `maps.DeleteFunc(m, func(k K, v V) bool { return condition })`

**sync package:**
- `sync.OnceFunc` (Medium): `f := sync.OnceFunc(func() { ... })` instead of `sync.Once` + wrapper
- `sync.OnceValue` (Medium): `var GetConfig = sync.OnceValue(loadConfig)` replaces the `once.Do` + package-var pattern

**context package:**
- `context.AfterFunc` (Medium): `stop := context.AfterFunc(ctx, cleanup)` instead of `go func() { <-ctx.Done(); cleanup() }()`
- `context.WithTimeoutCause` (Low): `ctx, cancel := context.WithTimeoutCause(parent, d, err)`
- `context.WithDeadlineCause`: similar, with an absolute deadline

## Go 1.22+

**Loops:**
- `for i := range n` (Critical, `go fix`): instead of `for i := 0; i < n; i++`
- Loop variables are safe to capture (High, `go fix`): each iteration has its own copy — delete any `v := v` shadow copies made before closures or goroutines

**cmp package:**
- `cmp.Or` (High): `cmp.Or(flag, env, config, "default")` returns first non-zero value

```go
// Instead of:
name := os.Getenv("NAME")
if name == "" {
    name = "default"
}
// Use:
name := cmp.Or(os.Getenv("NAME"), "default")
```

**reflect package:**
- `reflect.TypeFor` (Low): `reflect.TypeFor[T]()` instead of `reflect.TypeOf((*T)(nil)).Elem()`

**net/http:**
- Enhanced `http.ServeMux` patterns (Medium): `mux.HandleFunc("GET /api/{id}", handler)` with method and path params, replacing manual method checks and path trimming
- `r.PathValue("id")` to read path parameters

## Go 1.23+

- `maps.Keys(m)` / `maps.Values(m)` (High) return iterators
- `slices.Collect(iter)` to build a slice from an iterator (not a manual loop)
- `slices.Sorted(iter)` to collect and sort in one step

```go
keys := slices.Collect(maps.Keys(m))       // not: for k := range m { keys = append(keys, k) }
sortedKeys := slices.Sorted(maps.Keys(m))  // collect + sort
for k := range maps.Keys(m) { process(k) } // iterate directly
```

**time package:**
- `time.Tick` is now safe to use freely — since Go 1.23 the GC can recover unreferenced tickers even if `Stop` is never called. There is no longer any reason to prefer `NewTicker` when `Tick` will do.

## Go 1.24+

- `t.Context()` (High, `go fix`) instead of `context.WithCancel(context.Background())` in tests. ALWAYS use `t.Context()` when a test needs a context.

Before:
```go
func TestFoo(t *testing.T) {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()
    result := doSomething(ctx)
}
```
After:
```go
func TestFoo(t *testing.T) {
    ctx := t.Context()
    result := doSomething(ctx)
}
```

- `omitzero` (Medium, `go fix`) instead of `omitempty` in JSON struct tags. ALWAYS use `omitzero` for `time.Duration`, `time.Time`, structs, slices, maps — `omitempty` does not work for these.

```go
type Config struct {
    Timeout time.Duration `json:"timeout,omitzero"`
}
```

- `b.Loop()` (Medium, `go fix`) instead of `for i := 0; i < b.N; i++` in benchmarks. ALWAYS use `b.Loop()` for the main benchmark loop.

```go
func BenchmarkFoo(b *testing.B) {
    for b.Loop() {
        doWork()
    }
}
```

- `strings.SplitSeq` / `strings.FieldsSeq` (High, `go fix`) instead of `strings.Split` / `strings.Fields` when iterating over the results in a `for range` loop — avoids the intermediate slice allocation. (Also: `bytes.SplitSeq`, `bytes.FieldsSeq`.)

```go
for part := range strings.SplitSeq(s, ",") {
    process(part)
}
```

## Go 1.25+

- `wg.Go(fn)` (High, `go fix`) instead of `wg.Add(1)` + `go func() { defer wg.Done(); ... }()`. ALWAYS use `wg.Go()` when spawning goroutines with a `sync.WaitGroup`.

```go
var wg sync.WaitGroup
for _, item := range items {
    wg.Go(func() {
        process(item)
    })
}
wg.Wait()
```

## Go 1.26+

- `new(val)` (High, `go fix`) instead of `x := val; &x` — `new()` now accepts expressions, not just types. Type is inferred: `new(0)` → `*int`, `new("s")` → `*string`, `new(T{})` → `*T`. Don't use redundant casts like `new(int(0))` — just `new(0)`.

```go
cfg := Config{
    Timeout: new(30),   // *int
    Debug:   new(true), // *bool
}
```

- `errors.AsType[T](err)` instead of `errors.As(err, &target)`. ALWAYS use `errors.AsType` when checking if an error matches a specific type.

```go
if pathErr, ok := errors.AsType[*os.PathError](err); ok {
    handle(pathErr)
}
```
