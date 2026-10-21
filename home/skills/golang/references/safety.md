# Go Safety: correctness & defensive coding

Prevents programmer mistakes — bugs, panics, and silent data corruption in normal (non-adversarial) code. (Security handles attackers; safety handles ourselves.) These are gotchas linters generally don't catch.

## Principles & gotchas

1. **Prefer generics over `any`** when the type set is known — the compiler catches mismatches at build time instead of panicking at runtime.
2. **Always use safe type assertions** — comma-ok (`v, ok := x.(T)`) for normal interfaces.
3. **A typed nil pointer inside an interface is not `== nil`** — see below; this is the most subtle nil bug in Go.
4. **Writing to a nil map panics** — always initialize before use.
5. **`append` may reuse the backing array** — both slices then share memory, silently corrupting each other.
6. **Return defensive copies** from exported functions when you expose slices/maps — otherwise callers mutate your internals.
7. **`defer` runs at function exit, not loop iteration** — resources opened in a loop accumulate until the function returns; extract the loop body to a function.
8. **Integer conversions truncate silently** — `int64` → `int32` wraps without error.
9. **Float arithmetic is not exact** — compare with an epsilon, or use `math/big`.
10. **Design useful zero values** — nil map fields panic on first write; lazy-init them.
11. **Use `sync.Once` for lazy init** — guarantees exactly-once even under concurrency.

## The nil interface trap

Interfaces store `(type, value)`. An interface is `nil` only when **both** are nil. Returning a typed nil pointer sets the type descriptor, making the interface non-nil:

```go
// ✗ interface{type: *MyHandler, value: nil} is NOT == nil
func getHandler() http.Handler {
    var h *MyHandler // nil pointer
    if !enabled {
        return h     // returns a non-nil interface holding a nil pointer
    }
    return h
}

// ✓ return nil explicitly
func getHandler() http.Handler {
    if !enabled {
        return nil   // interface{type: nil, value: nil} == nil
    }
    return &MyHandler{}
}
```

A `getHandler()` caller that does `if h == nil { … }` will take the wrong branch in the bad version.

## Nil map, slice, and channel behavior

| Type | Index into nil | Write to nil | Len/Cap of nil | Range over nil |
| --- | --- | --- | --- | --- |
| Map | Zero value | **panic** | 0 | 0 iterations |
| Slice | **panic** | **panic** | 0 | 0 iterations |
| Channel | Blocks forever | Blocks forever | 0 | Blocks forever |

```go
// ✗ panics on write
var m map[string]int
m["key"] = 1

// ✓ initialize, or lazy-init in methods
func (r *Registry) Add(name string, val int) {
    if r.items == nil {
        r.items = make(map[string]int)
    }
    r.items[name] = val
}
```

## Slice aliasing — the append trap

`append` reuses the backing array if capacity allows, so both slices share memory:

```go
// ✗ a and b share backing array
a := make([]int, 3, 5)
b := append(a, 4)
b[0] = 99 // also mutates a[0]

// ✓ full slice expression forces a new allocation
b := append(a[:len(a):len(a)], 4)
```

Use `slices.Clone` (Go 1.21+) when you need an independent copy.

## Numeric safety

```go
// ✗ silently wraps if val > math.MaxInt32
var val int64 = 3_000_000_000
i32 := int32(val) // -1294967296

// ✓ bounds-check before converting
if val > math.MaxInt32 || val < math.MinInt32 {
    return fmt.Errorf("value %d overflows int32", val)
}
i32 := int32(val)
```

Float comparison: `a + b == c` is unreliable. Compare with an epsilon: `math.Abs((a+b)-c) < 1e-9`. Integer division by zero panics; float division by zero yields `±Inf`/`NaN`.
