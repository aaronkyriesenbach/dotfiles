---
name: check-test-coverage
description: >
  Thoroughly check test coverage in a project and identify areas for improvement.
  Use when the user asks about test coverage, wants to find untested code, asks
  "what's not tested?", "are there coverage gaps?", "check my tests", "how good
  is our coverage?", or wants a coverage audit. Produces a structured report of
  coverage gaps, missing edge cases, under-tested critical paths, and ambiguous
  behavior that needs clarification — not just a coverage percentage.
---

# Check Test Coverage

Deep coverage audit that goes beyond a percentage: finds untested code, missing
edge cases, under-tested critical paths, and behavior that tests don't
clarify. Produces a structured report with prioritized recommendations.

Coverage percentage is the starting line, not the finish. This skill treats
100% line coverage with weak assertions as more dangerous than 60% with strong,
spec-aligned tests.

---

## Process

The audit runs in five phases. Do not skip phases — each builds on the last.

### Phase 1 — Discover the test setup

Detect what the project uses. There is no universal coverage command, so
identify the stack first:

1. Read `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Makefile`,
   `CMakeLists.txt`, or equivalent project manifest.
2. Identify the test runner and coverage tool. If a coverage script is defined
   (e.g., `"test:coverage"` in package.json scripts, a Makefile target,
   `.github/workflows/*.yml`), note it.
3. Read `CONTEXT.md` or `AGENTS.md` if they exist — they may document testing
   conventions.

If the tooling is ambiguous, load only the relevant language guide from
`references/language-guides/`:

| Project language | Load |
|---|---|
| JavaScript / TypeScript | [references/language-guides/javascript-typescript.md](references/language-guides/javascript-typescript.md) |
| Python | [references/language-guides/python.md](references/language-guides/python.md) |
| Go | [references/language-guides/go.md](references/language-guides/go.md) |
| Rust | [references/language-guides/rust.md](references/language-guides/rust.md) |
| Anything else | [references/language-guides/other-languages.md](references/language-guides/other-languages.md) |

**Only load the one matching the project's primary language.** Don't pollute
context with guides for other languages.

### Phase 2 — Measure coverage

Run the project's coverage command. If none is configured, use the default
from the language guide.

**Critical**: coverage must be measured with _all_ tests, not just a subset.
Read the project's test configuration to confirm the scope.

Capture these artifacts (don't read them raw — they're often huge):

| Artifact | Purpose |
|---|---|
| Coverage summary (terminal output) | Line/branch/function % per file |
| Coverage data file (`coverage/lcov.info`, `coverage/coverage-final.json`, `coverage.xml`) | Per-line detail |
| Test file list (`find` commands below) | Find modules with no test file |

**Find modules with no tests at all** — these are the highest-priority gaps.
Use the `Finding untested files` command from the language guide you loaded
in Phase 1. Each guide has a `find` one-liner tailored to that language's
file naming conventions.

### Phase 3 — Analyze coverage gaps

Now dig into the data. Process the coverage file with code so raw bytes stay
out of context — use `ctx_execute` or `ctx_execute_file`.

**3a. Low-coverage files** — extract files below these thresholds:

| Metric | Warning threshold | Critical threshold |
|---|---|---|
| Line coverage | < 80% | < 50% |
| Branch coverage | < 70% | < 40% |
| Function coverage | < 80% | < 50% |

**3b. Critical paths with uncovered lines** — use `module_report` with
`blastRadius: true` on high-traffic modules (those with many dependents)
to identify uncovered code that has broad downstream impact. These are
higher priority than uncovered code in leaf modules.

**3c. Uncovered branches** — the coverage data file reports which branches
(if/else, switch/case, ternary, `&&`/`||` short-circuit) were never taken.
Extract these. A function with 100% line coverage but 50% branch coverage
is a red flag — the tests only exercise one path.

### Phase 4 — Edge case and ambiguity analysis

Coverage tools only know which lines ran — they don't know which scenarios
you tested. Go beyond the tooling:

**4a. Read a sample of tested functions.** For each file with high line
coverage (>90%), read 3-5 functions using `read_symbol` or `read_enclosing`.
Check the corresponding test file. Ask:

- Are assertions present and meaningful? (A test that only calls a function
  with no `expect`/`assert` is not a test — it's a smoke check.)
- Are edge cases covered? For each function that accepts input:
  - Empty / null / undefined / zero values
  - Boundary values (max, min, off-by-one)
  - Negative values (if numeric)
  - Unicode / special characters (if string)
  - Concurrent / repeated calls (if stateful)
- Are error paths tested? If the function throws or returns errors, are
  those paths exercised?
- Are external dependencies mocked meaningfully? Mocking a DB but never
  testing the error case is a gap.

**4b. Identify ambiguous behavior.** For each uncovered or under-tested
function, note whether the expected behavior is clear from the code or docs.
Flag anything where:

- The function's behavior on edge cases is undocumented
- The code contradicts comments or type signatures
- Two functions seem to overlap in responsibility
- Error handling is inconsistent across similar functions

### Phase 5 — Produce the report

Structure findings as:

```markdown
# Test Coverage Audit: <project-name>

## Summary
- **Overall line coverage**: XX% (was it measured locally?)
- **Overall branch coverage**: XX%
- **Coverage tool**: <tool name>
- **Modules with no tests**: N
- **Total findings**: N Critical, N High, N Medium, N Low

## Critical Gaps
<!-- Untested critical paths, 0% coverage on key modules, missing test files
     for core logic -->

### <file-path> — <severity>
**Issue**: <what's missing>
**Impact**: <why it matters — cite blast radius if applicable>
**Recommendation**: <specific tests to write>

## Missing Edge Cases
<!-- Functions with high line coverage but weak assertions or untested branches -->

### <file-path>::<function-name> — <severity>
**Issue**: <what edge case is untested>
**Recommendation**: <specific test case to add>

## Under-Tested Critical Paths
<!-- High blast-radius modules with coverage below threshold -->

### <file-path> — <severity>
**Coverage**: XX% lines, YY% branches
**Dependents**: N modules depend on this
**Issue**: <what's at risk>
**Recommendation**: <what coverage target to reach and which paths first>

## Ambiguous Behavior
<!-- Behavior that tests don't clarify or that the code leaves unclear -->

### <file-path>::<function-name>
**Question**: <what's unclear>
**Recommendation**: <how to resolve — add a test, document it, ask the team>

## Summary of Recommendations
<!-- Ordered by priority — highest impact first -->

1. [Critical] <action>
2. [High] <action>
3. ...
```

**Severity definitions:**

| Severity | Criteria |
|---|---|
| **Critical** | Core module with no tests, uncovered auth/security path, uncovered data mutation, 0% coverage on a high-traffic module |
| **High** | Module with <50% coverage, missing error-path tests on critical logic, uncovered branch in a widely-used function |
| **Medium** | <80% coverage on a non-critical module, missing edge cases on utility functions |
| **Low** | Minor uncovered branches in leaf modules, style-only functions |

### Save the report (optional)

After presenting inline, ask: "Save this report to a file?" If yes, write it
to `docs/test-coverage-audit-<date>.md`. If the user specified a path, use
that directly.

---

## Gotchas

- **Coverage percentage is not test quality.** A file can have 100% line
  coverage with zero assertions. Coverage data only tells you which lines
  ran — it cannot tell you whether those runs verified anything. Always
  spot-check test assertions in high-coverage files.
- **Generated code skews coverage.** Exclude `*.generated.*`, `*.d.ts`,
  protobuf stubs, GraphQL types, Prisma client, auto-generated configs.
  They inflate uncovered lines without being meaningful.
- **Test files count toward coverage unless excluded.** Most coverage tools
  include test files by default. If overall coverage seems suspiciously
  high, check whether test files are inflating the number.
- **Branch coverage gaps hide in plain sight.** A file with 100% line
  coverage can still have 50% branch coverage. Ternary operators, `&&`/`||`
  short-circuits, and `switch` cases without `default` are common culprits.
- **CI coverage config may differ from local.** CI often has a different
  coverage threshold or include/exclude pattern. If the user mentions CI,
  check `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc.
- **`lcov.info` line counts are 0-based; editor line numbers are 1-based.**
  A coverage tool reporting "line 5 uncovered" may point to line 6 in the
  editor.
- **Monorepos need per-package coverage.** If the project has multiple
  packages (Nx, Turborepo, pnpm workspaces, Lerna), audit each package
  separately — a 90% average can hide one package at 10%.
- **Coverage thresholds in config can mask degradation.** A project set to
  `lines: 80` that drops from 95% to 81% looks "passing" but has lost
  significant coverage. Always compare against the actual percentage, not
  just pass/fail.
- **Don't flag vendored or third-party code.** `vendor/`, `third_party/`,
  `node_modules/` (if somehow included in coverage) are not project code.

## Hard Rules

- Never modify test files or source code during the audit. This is
  read-only analysis.
- Never skip Phase 4 (edge case analysis). A coverage report is incomplete
  without it.
- If no coverage tool is configured and the language guide doesn't have a
  quick default, stop and ask the user how they measure coverage — don't
  guess.
- If a `coverage` script exists in the project manifest, use it. Don't
  override with a different tool.
- Present findings before asking whether to save a file.