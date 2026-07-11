---
name: branch-review
description: Use to review code changes in a branch, PR, or diff before merging. Triggered by prompts like "review my changes", "code review this PR", "check this branch before merging", or "is this ready to merge?"
---

# Code Review

Conduct a structured code review of changes on the current branch, producing a severity-rated issue list and a final REJECT/ACCEPT verdict.

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

### Step 3 — Review the diff

Walk through changed files. For each file, read the relevant sections using `read`, `module_report`, or `read_enclosing`. Check against these categories, weighted by project standards in AGENTS.md:

1. **Type safety** — No `any` types, no lint-suppression comments, proper null handling. These are Critical per AGENTS.md.
2. **DRY violations** — Duplicated logic, redefined types, relative imports instead of path aliases.
3. **Correctness & logic** — Edge cases, off-by-one errors, race conditions, incorrect assumptions.
4. **Error handling** — Uncaught promises, swallowed errors, missing validation, unclear error messages.
5. **Performance** — N+1 queries, unnecessary allocations, missing indexes, blocking operations.
6. **Security** — Injection vectors, exposed secrets, missing auth checks, unsafe deserialization.
7. **Readability & naming** — Confusing names, missing comments on non-obvious logic, overly clever code.

Rate each finding: **Critical**, **High**, **Medium**, or **Low**.

### Step 4 — Present findings

Use this format:

```markdown
## Code Review: <branch-or-pr-name>

### Automated Checks
- LSP diagnostics: <N errors, N warnings> (or "clean")
- Lint: <status>
- Build: <status>

### Issues

#### <file-path>:<line-range> — <severity>
**Category**: <type-safety | dry | correctness | error-handling | performance | security | readability>
**Problem**: <concise description of what's wrong>
**Fix**: <specific, actionable suggestion>

(repeat for each issue)

### Verdict: REJECT | ACCEPT

<Detailed reasoning. ACCEPT only if no Critical or High issues remain.>
```

### Step 5 — Apply verdict rules

- **REJECT** if: any Critical issues, 3+ High issues, or any automated check failure.
- **ACCEPT** if: at most a few Medium/Low issues that can be addressed in follow-up.

If REJECT, do NOT offer to fix — let the user decide. If they want fixes, the `address-pr-feedback` skill handles that flow.

## Gotchas

- Don't flag generated code (protobuf, GraphQL types, Prisma client, `.d.ts` files, auto-generated configs). Check file headers for "auto-generated" or "DO NOT EDIT" markers.
- Don't flag test snapshot updates or test fixture files as issues unless the snapshot content is clearly wrong.
- `lsp_diagnostics` on a directory scans all files — scope it to changed files only if the project is large.
- AGENTS.md forbids `any` types, lint-suppression comments, and relative imports — these are always Critical, not matters of style.
- If you can't determine whether a pattern is intentional (e.g., a deliberate `any` escape hatch), flag it as Medium with a question, not Critical.
- The `module_report` tool with `blastRadius: true` can reveal whether a change has unexpected downstream impact — use it for changes touching shared utilities or types.

## Hard Rules

- Never apply fixes during review. Review is read-only.
- Never commit, push, or modify branch state.
- Never skip automated checks to save time — they're the highest-signal part of the review.
