# Rust Coverage Guide

Rust has built-in testing but coverage requires an external tool.

## Runners

| Tool | Command |
|---|---|
| `cargo-tarpaulin` (recommended) | `cargo tarpaulin --out Html --out Lcov` |
| `cargo-llvm-cov` | `cargo llvm-cov --lcov --output-path lcov.info` |
| `grcov` | Complex setup — see project docs |

## Detection

Check for `Cargo.toml`. Coverage is not built-in — one of the tools above
must be installed.

## Gotchas

- **Rust coverage tools need `nightly` or specific flags.** `cargo-tarpaulin`
  works on stable. `cargo-llvm-cov` needs `-C instrument-coverage`.
- **Proc macros and build scripts are not measured.**
- **Integration tests in `tests/` report separately** from unit tests.
- **`#[cfg(test)]` modules report as 100% coverage** — they only exist in
  test builds.

## Finding untested files

```bash
# Rust convention: tests next to code (mod tests) or in tests/
for f in $(cargo metadata --format-version=1 --no-deps 2>/dev/null | \
  python3 -c "import json,sys; [print(p.replace('file://','')) for m in json.load(sys.stdin)['packages'] for t in m.get('targets',[]) if 'lib' in t['kind']]" 2>/dev/null); do
  echo "Library source (check manually): $f"
done
```