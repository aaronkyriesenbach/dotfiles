# JavaScript / TypeScript Coverage Guide

## Runners

| Test runner | Coverage provider | Coverage command |
|---|---|---|
| Jest | `--coverage` (istanbul, built-in) | `npx jest --coverage` |
| Vitest | `--coverage` (istanbul or v8) | `npx vitest run --coverage` |
| Mocha | nyc (istanbul wrapper) | `npx nyc mocha` |
| Playwright | Built-in | `npx playwright test --reporter=html` (and check `playwright.config.ts` for coverage settings) |
| Cypress | Plugin-based (e.g., `@cypress/code-coverage`) | `npx cypress run` (with plugin configured) |

## Detection

Check `package.json` for:
- `"jest"` key → Jest
- `"vitest"` in devDependencies → Vitest
- `"nyc"` in devDependencies/config → Mocha + nyc
- `scripts.test` → may reveal the runner

## Coverage output

| Tool | Output format | Default location |
|---|---|---|
| Jest | `lcov.info`, `coverage-final.json`, HTML, text | `coverage/` |
| Vitest | `lcov.info`, `coverage-final.json`, HTML, text | `coverage/` |
| nyc | `lcov.info`, `coverage-final.json`, HTML, text | `coverage/` |

## Gotchas

- **Vitest `--coverage` requires `@vitest/coverage-v8` or `@vitest/coverage-istanbul`** — install if missing.
- **Jest coverage is slow** — warn the user if the project is large.
- **TypeScript paths aliases** (`@/foo`) may confuse coverage path mapping. Check `jest.config.ts` for `moduleNameMapper`.
- **`.spec.ts` vs `.test.ts`** — some projects use one convention. Check the Jest/Vitest config's `testMatch` or `testRegex`.
- **E2E tests** (Playwright, Cypress) often report component-level coverage, not server-side coverage if the server runs separately.

## Finding untested files

```bash
# Find .ts/.tsx files with no corresponding .test.* or .spec.*
for f in $(find src -name '*.ts' -o -name '*.tsx' | grep -v '\.test\.\|\.spec\.\|\.d\.ts\|__tests__'); do
  base=$(basename "$f" | sed 's/\.tsx\?$//')
  if ! find src -name "${base}.test.*" -o -name "${base}.spec.*" | grep -q .; then
    echo "NO TEST: $f"
  fi
done
```