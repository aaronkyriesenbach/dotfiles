---
name: branch-review
description: Use to review code changes in a branch, PR, or diff before merging. Triggered by prompts like "review my changes", "code review this PR", "check this branch before merging", or "is this ready to merge?"
---

# Code Review

Conduct a structured code review of changes on the current branch, producing a severity-rated issue list and a final REJECT/ACCEPT verdict. A diff only shows half a change — the other half is how it lands on the **unchanged** code around it. Every step below treats that interaction as mandatory, not optional.

## Procedure

### Step 1 — Discover the changeset

Determine what changed. Use exactly one of these based on what's available:

- **GitHub PR** (if user provided a PR number or URL): `gh pr diff <pr-identifier>`
- **Branch diff against default branch**: `git log main...HEAD --oneline` then `git diff main...HEAD`
- **Branch diff against another ref**: `git diff <base-ref>...HEAD` (use the ref the user specifies)

If the user hasn't specified what to review, default to `git diff main...HEAD`. If `main` doesn't exist, try `master`, then `develop`.

### Step 2 — Run automated checks

Before manual review, run these and note any failures:

```bash
lsp_diagnostics          # LSP errors/warnings on changed files
lens_diagnostics mode=delta  # pi-lens warnings for this session
```

If the project has a linter or build command, run it:

```bash
# e.g., npm run lint, cargo clippy, etc.
```

**Do not proceed past automated failures without noting them.** These are automatically Critical severity issues.

### Step 3 — Trace the blast radius

Before reading diff hunks in isolation, find every place the change touches code you are *not* looking at:

1. For every changed file, run `module_report` with `blastRadius: true`.
2. For every changed **exported/public symbol** (function, class, method, API route, type, config value, permission/role constant), run `lsp_navigation` (find references) to list every call site.
3. For each call site outside the diff, read enough surrounding context (`read_enclosing`) to answer: *does this caller's assumption about the old behavior still hold after this change?* Look specifically for: a caller relying on a check the change removed or moved, a caller now reachable from a different trust level (e.g. an internal helper now called from a public/unauthenticated path), and a caller whose invariant about return shape/error behavior/side effects no longer matches.

**Completion criterion (exhaustive):** every changed exported symbol has a recorded outcome — either "checked N call sites, no broken assumption" or "found impact: `<description>`". A symbol with no recorded outcome means this step isn't done, regardless of how clean the diff hunk looks.

### Step 4 — Security pass

Security bugs are frequently invisible in the diff because the vulnerable half is the unchanged code the diff now flows into. Work through this checklist explicitly — every item gets a yes/no/n-a, not silence:

- **Weakened boundary**: does this change remove, relocate, weaken, or bypass an auth/validation/sanitization check that unchanged downstream code relied on being enforced upstream?
- **Trust-level shift**: is a changed function now reachable from a context with lower trust than it was written for (new caller, new route, new entry point found in Step 3)?
- **Data flow to sink**: for every new or changed input-handling site, trace the value to its sink even through unchanged files — SQL, shell exec, deserialization, template rendering, file path construction, redirects.
- **Permission/role logic**: if role or permission logic changed, check every existing caller found in Step 3 against its expected role, not just the new caller the PR was written for.
- **Secrets**: any credential, token, or key touched, logged, or newly exposed (error messages, debug output, client-visible responses).
- **Full-context read**: for any file touching auth, payments, permissions, session, or crypto, read the full enclosing function/class via `read_enclosing`/`module_report` — never judge these from the diff hunk alone.

If the diff touches any of auth, session, permission, payment, crypto, or raw input parsing/deserialization, spawn a `security-appsec-engineer` (or `security-architect`) subagent in parallel with your own review. Give it only: the diff, and the call-site list from Step 3. Ask it to report Critical/High findings only, focused on trust-boundary and data-flow issues. Fold its findings into Step 6 under the `security` category, tagged `(security-subagent)`.

### Step 5 — Review the diff

Walk through changed files. For each file, read the relevant sections using `read`, `module_report`, or `read_enclosing`. Check against these categories, weighted by project standards in AGENTS.md:

1. **Type safety** — No `any` types, no lint-suppression comments, proper null handling. These are Critical per AGENTS.md.
2. **DRY violations** — Duplicated logic, redefined types, relative imports instead of path aliases.
3. **Correctness & logic** — Edge cases, off-by-one errors, race conditions, incorrect assumptions.
4. **Error handling** — Uncaught promises, swallowed errors, missing validation, unclear error messages.
5. **Performance** — N+1 queries, unnecessary allocations, missing indexes, blocking operations.
6. **Security** — Findings carried over from Step 4, plus anything new spotted while reading (injection vectors, exposed secrets, missing auth checks, unsafe deserialization).
7. **Readability & naming** — Confusing names, missing comments on non-obvious logic, overly clever code.

Rate each finding: **Critical**, **High**, **Medium**, or **Low**.

**Completion criterion (exhaustive):** every changed file has been checked against all 7 categories, every changed exported symbol has its Step 3 blast-radius outcome recorded, and every Step 4 checklist item has an explicit answer.

### Step 6 — Present findings

Use this format:

```markdown
## Code Review: <branch-or-pr-name>

### Automated Checks
- LSP diagnostics: <N errors, N warnings> (or "clean")
- Lint: <status>
- Build: <status>

### Blast Radius
- <changed symbol>: <N call sites checked, no broken assumption | impact found: ...>
(one line per changed exported symbol)

### Security Checklist
- Weakened boundary: <yes/no/n-a — detail>
- Trust-level shift: <yes/no/n-a — detail>
- Data flow to sink: <yes/no/n-a — detail>
- Permission/role logic: <yes/no/n-a — detail>
- Secrets: <yes/no/n-a — detail>
- Security subagent run: <yes, findings below | not applicable>

### Issues

#### <file-path>:<line-range> — <severity>
**Category**: <type-safety | dry | correctness | error-handling | performance | security | readability>
**Problem**: <concise description of what's wrong>
**Fix**: <specific, actionable suggestion>

(repeat for each issue)

### Verdict: REJECT | ACCEPT

<Detailed reasoning. ACCEPT only if no Critical or High issues remain and coverage is complete.>
```

### Step 7 — Apply verdict rules

- **REJECT** if: any Critical issue, 3+ High issues, any automated check failure, any unresolved Critical/High **security** finding (this overrides the "3+ High" count — one security Critical/High is enough on its own), or any changed exported symbol / security-checklist item left without a recorded outcome ("coverage incomplete").
- **ACCEPT** if: at most a few Medium/Low issues that can be addressed in follow-up, and Step 3/Step 4 coverage is fully recorded.

If REJECT, do NOT offer to fix — let the user decide. If they want fixes, the `address-pr-feedback` skill handles that flow.

## Gotchas

- Don't flag generated code (protobuf, GraphQL types, Prisma client, `.d.ts` files, auto-generated configs). Check file headers for "auto-generated" or "DO NOT EDIT" markers.
- Don't flag test snapshot updates or test fixture files as issues unless the snapshot content is clearly wrong.
- `lsp_diagnostics` on a directory scans all files — scope it to changed files only if the project is large.
- AGENTS.md forbids `any` types, lint-suppression comments, and relative imports — these are always Critical, not matters of style.
- If you can't determine whether a pattern is intentional (e.g., a deliberate `any` escape hatch), flag it as Medium with a question, not Critical.
- A changed *internal* (non-exported) helper still needs Step 3 if it's large or central — check `module_report`'s usedBy list, not just export status, to decide.
- If Step 3's reference search returns too many call sites to check individually (e.g. a widely used utility), sample the highest-risk ones (different trust boundary, different module, security-sensitive) rather than skipping the step — record that a sample was used, not a full check.

## Hard Rules

- Never apply fixes during review. Review is read-only.
- Never commit, push, or modify branch state.
- Never skip automated checks to save time — they're the highest-signal part of the review.
- Never skip Step 3 (blast radius) or Step 4 (security checklist) to save time — an ACCEPT without recorded coverage on these is not a valid ACCEPT.
