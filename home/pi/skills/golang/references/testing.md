# Go Testing

Principles for maintainable, fast, and reliable Go tests.

## Design principles

1. **Table-driven tests use named subtests** — every case needs a `name` field passed to `t.Run`, so failures point at the exact scenario.
2. **Integration tests use build tags** (`//go:build integration`) to stay separable from fast unit tests.
3. **Tests must not depend on execution order** — each test is independently runnable.
4. **Never test implementation details** — test observable behavior and public-API contracts, so refactors don't break tests.
5. **Mock interfaces, not concrete types** — lets you swap fakes without touching call sites.
6. **Keep unit tests fast** (< 1 ms each); push anything with external dependencies behind a build tag.
7. **Use testify (or similar) as helpers, not a replacement for the standard library.**
8. **Include `Example*` functions as executable documentation** — they compile-check your docs in `go test`.
9. Run `go test -race ./...` in CI.

## File and naming conventions

- One test file per source file: `foo.go` → `foo_test.go`. Tools (`go test`, coverage, IDE "jump to test", `gotests`) resolve tests by source file, not by symbol. Splitting a source file's tests by function name scatters them and breaks that mapping. Only split a genuinely huge file by concern, and keep each split derived from the source name (`foo_test.go` + `foo_edgecases_test.go`).
- Order test functions to match the order of the functions they test in the source — a reader scrolling both files can find matches by position.
- `package foo` (white-box, can touch unexported) vs `package foo_test` (black-box, public API only) — choose per what you need to assert.

```go
func TestAdd(t *testing.T) { ... }                // function
func TestMyStruct_MyMethod(t *testing.T) { ... }  // method
func BenchmarkAdd(b *testing.B) { ... }           // benchmark (Go 1.24+: use for b.Loop())
func ExampleAdd() { ... }                         // example
func FuzzAdd(f *testing.F) { ... }                // fuzz test
```

## Table-driven shape

```go
func TestCalculatePrice(t *testing.T) {
    tests := []struct {
        name      string
        quantity  int
        unitPrice float64
        expected  float64
    }{
        {name: "single item", quantity: 1, unitPrice: 10.0, expected: 10.0},
        {name: "bulk discount", quantity: 100, unitPrice: 10.0, expected: 900.0},
        {name: "zero quantity", quantity: 0, unitPrice: 10.0, expected: 0.0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := CalculatePrice(tt.quantity, tt.unitPrice)
            if got != tt.expected {
                t.Errorf("CalculatePrice(%d, %.2f) = %.2f, want %.2f",
                    tt.quantity, tt.unitPrice, got, tt.expected)
            }
        })
    }
}
```

## Gotcha: assert scope leaking into subtests

Never build a testify `assert`/`require` instance in the parent test and reuse it inside `t.Run` closures. `assert.New(t)` captures the parent's `*testing.T`, so failures raised inside a subtest get attributed to the **parent** — the failing subtest still reports `PASS`, silently hiding which case broke.

```go
// ✗ `is` is bound to the parent's t — failures misattribute
func TestX(t *testing.T) {
    is := assert.New(t)
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            is.Equal(tt.expected, Calc(tt.in)) // attributed to parent on failure
        })
    }
}

// ✓ Each subtest builds its own instance from its own t
func TestX(t *testing.T) {
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            is := assert.New(t)
            is.Equal(tt.expected, Calc(tt.in))
        })
    }
}
```

Check with a deliberately-broken case: if `go test -v` shows `FAIL: TestX` but every `PASS: TestX/subtest` line still says PASS, the assert scope is leaking.

## Goroutine leak detection

For packages that spawn goroutines, add `go.uber.org/goleak` in `TestMain` to fail tests when goroutines leak:

```go
func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}
```
