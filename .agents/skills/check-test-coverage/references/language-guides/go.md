# Go Coverage Guide

Go has built-in testing and coverage. No external tool required.

## Default commands

```bash
# Per-package
go test -cover ./...

# With coverage profile (for detailed analysis)
go test -coverprofile=coverage.out ./...

# View coverage by function
go tool cover -func=coverage.out

# HTML report
go tool cover -html=coverage.out -o coverage.html
```

## Detection

Check for `go.mod` — if present, the project is Go. Coverage is always via
`go test`.

## Coverage output

| Output | Format | Default location |
|---|---|---|
| Coverage profile | Text (lines with count) | `coverage.out` (if `-coverprofile` used) |
| Per-function summary | Terminal text | stdout from `go tool cover -func` |
| HTML | HTML | `coverage.html` (if `-html` used) |

## Gotchas

- **Go coverage is per-package by default.** `go test -cover ./...` reports
  each package separately — aggregate across them manually.
- **Test files in the same package** (`package foo` not `package foo_test`)
  can access unexported symbols.
- **`go test -cover` without `./...` only tests the current package.**
- **Generated Go files** (protobuf, `*_string.go`, `*.pb.go`) should be excluded.
- **Build tags** (`//go:build integration`) may skip tests. Check whether
  the coverage run includes all tags or just the default.

## Finding untested files

```bash
for f in $(find . -name '*.go' | grep -v '_test\.go\|vendor/\|\.pb\.go\|_string\.go'); do
  dir=$(dirname "$f")
  base=$(basename "$f" .go)
  if [ ! -f "${dir}/${base}_test.go" ]; then
    echo "NO TEST: $f"
  fi
done
```