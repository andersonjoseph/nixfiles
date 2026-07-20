# Modern Go Idioms

Modern, version-keyed Go idioms — "use feature X instead of legacy pattern Y." When writing or reviewing Go, prefer the modern stdlib features available in the project's target version.

## Detecting the target version

Find the project's Go version from `go.mod`:

```bash
grep '^go ' go.mod
```

Use ALL features up to and including that version. Never use features from a newer Go version than the target, and never use an outdated pattern when a modern alternative exists. If there is no `go.mod` (or the version is unclear), ask which Go version to target.

> Note: if you run the `modernize` analyzer / `golangci-lint` modernize linter, much of this is also flagged on existing code. This reference exists so new code is written modern the first time, avoiding rework — and several entries (e.g. `omitzero`, `wg.Go`, `new(val)`, `errors.AsType`) are too recent or too semantic for linters to enforce.

---

## Go 1.0+

- `time.Since`: `time.Since(start)` instead of `time.Now().Sub(start)`

## Go 1.8+

- `time.Until`: `time.Until(deadline)` instead of `deadline.Sub(time.Now())`

## Go 1.13+

- `errors.Is`: `errors.Is(err, target)` instead of `err == target` (works with wrapped errors)

## Go 1.18+

- `any`: Use `any` instead of `interface{}`
- `bytes.Cut`: `before, after, found := bytes.Cut(b, sep)` instead of Index+slice
- `strings.Cut`: `before, after, found := strings.Cut(s, sep)`

## Go 1.19+

- `fmt.Appendf`: `buf = fmt.Appendf(buf, "x=%d", x)` instead of `[]byte(fmt.Sprintf(...))`
- `atomic.Bool`/`atomic.Int64`/`atomic.Pointer[T]`: Type-safe atomics instead of `atomic.StoreInt32`

```go
var flag atomic.Bool
flag.Store(true)
if flag.Load() { ... }

var ptr atomic.Pointer[Config]
ptr.Store(cfg)
```

## Go 1.20+

- `strings.Clone`: `strings.Clone(s)` to copy a string without sharing backing memory
- `bytes.Clone`: `bytes.Clone(b)` to copy a byte slice
- `strings.CutPrefix/CutSuffix`: `if rest, ok := strings.CutPrefix(s, "pre:"); ok { ... }`
- `errors.Join`: `errors.Join(err1, err2)` to combine multiple errors
- `context.WithCancelCause`: `ctx, cancel := context.WithCancelCause(parent)` then `cancel(err)`
- `context.Cause`: `context.Cause(ctx)` to get the error that caused cancellation

## Go 1.21+

**Built-ins:**
- `min`/`max`: `max(a, b)` instead of if/else comparisons
- `clear`: `clear(m)` to delete all map entries, `clear(s)` to zero slice elements

**slices package:**
- `slices.Contains`: `slices.Contains(items, x)` instead of manual loops
- `slices.Index`: `slices.Index(items, x)` returns index (-1 if not found)
- `slices.IndexFunc`: `slices.IndexFunc(items, func(item T) bool { return item.ID == id })`
- `slices.SortFunc`: `slices.SortFunc(items, func(a, b T) int { return cmp.Compare(a.X, b.X) })`
- `slices.Sort`: `slices.Sort(items)` for ordered types
- `slices.Max`/`slices.Min`: `slices.Max(items)` instead of a manual loop
- `slices.Reverse`: `slices.Reverse(items)` instead of a manual swap loop
- `slices.Compact`: removes consecutive duplicates in-place
- `slices.Clip`: `slices.Clip(s)` drops unused capacity
- `slices.Clone`: `slices.Clone(s)` creates a copy

**maps package:**
- `maps.Clone`: `maps.Clone(m)` instead of manual map iteration
- `maps.Copy`: `maps.Copy(dst, src)` copies entries from src to dst
- `maps.DeleteFunc`: `maps.DeleteFunc(m, func(k K, v V) bool { return condition })`

**sync package:**
- `sync.OnceFunc`: `f := sync.OnceFunc(func() { ... })` instead of `sync.Once` + wrapper
- `sync.OnceValue`: `getter := sync.OnceValue(func() T { return computeValue() })`

**context package:**
- `context.AfterFunc`: `stop := context.AfterFunc(ctx, cleanup)` runs cleanup on cancellation
- `context.WithTimeoutCause`: `ctx, cancel := context.WithTimeoutCause(parent, d, err)`
- `context.WithDeadlineCause`: similar, with an absolute deadline

## Go 1.22+

**Loops:**
- `for i := range n`: `for i := range len(items)` instead of `for i := 0; i < len(items); i++`
- Loop variables are now safe to capture in goroutines (each iteration has its own copy)

**cmp package:**
- `cmp.Or`: `cmp.Or(flag, env, config, "default")` returns first non-zero value

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
- `reflect.TypeFor`: `reflect.TypeFor[T]()` instead of `reflect.TypeOf((*T)(nil)).Elem()`

**net/http:**
- Enhanced `http.ServeMux` patterns: `mux.HandleFunc("GET /api/{id}", handler)` with method and path params
- `r.PathValue("id")` to read path parameters

## Go 1.23+

- `maps.Keys(m)` / `maps.Values(m)` return iterators
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

- `t.Context()` instead of `context.WithCancel(context.Background())` in tests. ALWAYS use `t.Context()` when a test needs a context.

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

- `omitzero` instead of `omitempty` in JSON struct tags. ALWAYS use `omitzero` for `time.Duration`, `time.Time`, structs, slices, maps — `omitempty` does not work for these.

```go
type Config struct {
    Timeout time.Duration `json:"timeout,omitzero"`
}
```

- `b.Loop()` instead of `for i := 0; i < b.N; i++` in benchmarks. ALWAYS use `b.Loop()` for the main benchmark loop.

```go
func BenchmarkFoo(b *testing.B) {
    for b.Loop() {
        doWork()
    }
}
```

- `strings.SplitSeq` / `strings.FieldsSeq` instead of `strings.Split` / `strings.Fields` when iterating over the results in a `for range` loop. (Also: `bytes.SplitSeq`, `bytes.FieldsSeq`.)

```go
for part := range strings.SplitSeq(s, ",") {
    process(part)
}
```

## Go 1.25+

- `wg.Go(fn)` instead of `wg.Add(1)` + `go func() { defer wg.Done(); ... }()`. ALWAYS use `wg.Go()` when spawning goroutines with a `sync.WaitGroup`.

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

- `new(val)` instead of `x := val; &x` — `new()` now accepts expressions, not just types. Type is inferred: `new(0)` → `*int`, `new("s")` → `*string`, `new(T{})` → `*T`. Don't use redundant casts like `new(int(0))` — just `new(0)`.

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
