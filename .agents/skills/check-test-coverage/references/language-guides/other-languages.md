# Other Languages — Coverage Heuristics

If the project doesn't match JS/TS, Python, Go, or Rust, use these heuristics
to discover the coverage tooling.

## Discovery steps

1. Check the project manifest for test-related dependencies or scripts.
2. Search for coverage configuration files: `.coveragerc`, `codecov.yml`,
   `sonar-project.properties`, `jest.config.*`, `vitest.config.*`.
3. Look at CI config (`.github/workflows/*.yml`, `.gitlab-ci.yml`) — CI
   often runs coverage and publishes it.
4. If all else fails, ask the user: "How do you run tests with coverage in
   this project?"

## Generic find for untested files

```bash
# Most languages: test files match *test* or *spec* in name
for f in $(git ls-files | grep -v -E '(test|spec|vendor|node_modules|\.generated\.|\.d\.ts$)'); do
  ext="${f##*.}"
  case "$ext" in
    ts|tsx|js|jsx|py|rs|go|rb|java|kt|swift|scala|php) ;;
    *) continue ;;
  esac
  dir=$(dirname "$f")
  base=$(basename "$f" ".$ext")
  if ! echo "$f" | grep -q -E "(test|spec|__tests__|_test)"; then
    # Check if a test file exists
    test_pattern="${base}\.(test|spec|_test)\.${ext}"
    if ! git ls-files "$dir" | grep -qE "$test_pattern"; then
      echo "NO TEST: $f"
    fi
  fi
done
```