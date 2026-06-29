---
name: create-agents-md
description: Use when the user asks to create, update, review, or audit an AGENTS.md file, or when setting up agent configuration for a project. Also trigger when evaluating existing AGENTS.md, CLAUDE.md, Cursor rules, or Copilot instructions.
---

# Create or Update AGENTS.md

This skill instructs an agent to create, review, or update AGENTS.md files for a project — concise, action-dense reference files that coding agents use to work effectively in the repository. An AGENTS.md is a **README for agents**: a predictable, dedicated place for the context and instructions AI coding agents need.

The core mandate: **maximize agent efficiency per token**. Every line must earn its place. If it doesn't directly help an agent ship correct code faster, cut it.

---

## Default Approach

1. **Discovery first** — run the systematic checklist (§2.1) before writing anything
2. **Commands first** — the build/test/lint section is the highest-value section, lead with it
3. **Concrete over abstract** — every style rule needs a ✅/❌ code example; every command needs flags
4. **Ruthless cutting** — if you can't answer "what would go wrong if I deleted this line?", delete it
5. **Verify** — run every command you document before declaring done

For the full format, see `assets/example-agents-md.md`.

---

## Gotchas

- **AGENTS.md is NOT a README.** Agents don't need product descriptions, marketing copy, or contribution guidelines for humans. If you find yourself writing a paragraph of prose, replace it with a concrete rule or example.
- **"Use best practices" is noise.** Every agent already attempts this. Replace with a specific, verifiable rule.
- **Commands need flags.** `npm test` is vague; `npm test -- --coverage` is actionable. Always include the flags the team actually uses.
- **Don't dump package.json scripts.** Agents can read `package.json`. Curate to the 3-5 commands agents actually run.
- **Don't list every dependency.** Agents read lockfiles. Call out only the 5-8 they'll actually touch.
- **Subdirectory AGENTS.md files are rare.** Only create them for truly autonomous packages (§5.1) — not for every top-level folder. An AGENTS.md in every subdirectory is noise.
- **Run the commands you document.** If `npm test` fails with a missing env var, document that env var. Unverified commands produce broken instructions.
- **Every boundary needs a reason.** "Never touch `prisma/migrations/`" without "(managed by Prisma CLI)" — agents ignore unexplained restrictions.
- **Read existing agent config files before overwriting.** Don't blindly replace an existing AGENTS.md. Audit it (§4.1) first. If it scores well, make targeted edits.

---

## 1. Philosophy

| AGENTS.md is... | AGENTS.md is NOT... |
|---|---|
| Executable commands with flags | Marketing copy or project descriptions |
| Concrete code examples showing style | Abstract style guides |
| Specific file paths and boundaries | Vague "use best practices" advice |
| Versioned stack identifiers | A dumping ground for wiki pages |
| Rules the agent MUST follow | Optional suggestions |

**Length target**: Root AGENTS.md should fit in ~100-250 lines. Every line beyond ~250 is a tax on every future agent invocation.

---

## 2. Discovery Phase — Understanding the Project

Before writing a single line, the agent MUST build a working mental model of the project.

### 2.1 Systematic Discovery Checklist

Run these investigations. Do NOT skip any.

| # | Investigation | How |
|---|---|---|
| 1 | **Project type** | Read top-level `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Gemfile`, etc. Identify: monorepo, library, CLI, web app, mobile, etc. |
| 2 | **Build system** | Find build scripts in `package.json#scripts`, `Makefile`, `Justfile`, `Taskfile`, `earthly`, `Bazel`, etc. Identify the one primary build command. |
| 3 | **Test framework + commands** | Locate test config files (`vitest.config.*`, `jest.config.*`, `pytest.ini`, etc.). Find how to run all tests, a single file, a single test. |
| 4 | **Lint/format** | Find `eslint.config.*`, `.prettierrc*`, `biome.json`, `ruff.toml`, `clippy.toml`, etc. Identify auto-fix commands. |
| 5 | **Language + version** | Check `package.json#engines`, `.nvmrc`, `.tool-versions`, `rust-toolchain.toml`, `pyproject.toml#requires-python`, `go.mod#go`. Be specific: "Node 22", not "Node". |
| 6 | **Directory structure** | Map the top 2-3 levels. Identify where source lives, where tests live, where config lives, where generated code lives, where docs live. |
| 7 | **Key dependencies** | Extract from the lockfile/manifest: framework, ORM, key libraries. Limit to the 5-8 things an agent will actually encounter. |
| 8 | **Git workflow** | Check `.github/workflows/` for CI steps. Identify required checks. Check branch naming conventions from recent merged PRs. |
| 9 | **Existing AGENTS.md** | Check root and subdirectories for existing AGENTS.md, AGENT.md, CLAUDE.md, `.cursor/rules/`, `.github/copilot-instructions.md`. Read and evaluate against §4. |
| 10 | **Secrets / sensitive paths** | Find `.env.example`, `.gitignore` entries for `.env`, secrets directories, production config files. These become the "never touch" boundary list. |

### 2.2 Run What You Can

Execute the commands you plan to document. If `npm test` fails with a missing env var, document that env var. Commands that fail because of missing credentials should be noted as unverified.

---

## 3. Content Guidelines

### 3.1 Required Sections (in order)

The first 4 sections are **mandatory**. Sections 5–8 are strongly recommended. See `assets/example-agents-md.md` for a complete working example.

#### Section 1: Build & Run Commands (~10–20 lines)

The single most important section. Put it FIRST.

```markdown
## Commands

### Build
- **Build**: `npm run build` — compiles TypeScript to `dist/`
- **Dev server**: `npm run dev` — starts Vite dev server on :5173
- **Type-check**: `npm run typecheck` — `tsc --noEmit`

### Test
- **All tests**: `npm test` — runs Vitest (must pass before commits)
- **Single file**: `npx vitest run path/to/test.ts`
- **Single test**: `npx vitest run -t "test name pattern"`
- **With coverage**: `npm test -- --coverage`

### Lint & Format
- **Lint**: `npm run lint` — ESLint
- **Auto-fix lint**: `npm run lint -- --fix`
- **Format**: `npx prettier --check .`
- **Auto-format**: `npx prettier --write .`
```

**Rules**: Include flags. Show single-file and single-test variants. Group by purpose (build, test, lint, deploy), not alphabetically. Note required env vars inline.

#### Section 2: Tech Stack (~5–10 lines)

Be specific with versions — they determine what syntax and APIs are available.

```markdown
## Stack
- **Runtime**: Node.js 22 (see `.nvmrc`)
- **Language**: TypeScript 5.7, strict mode
- **Framework**: Next.js 15.1 (App Router)
- **Database**: PostgreSQL 16 via Prisma 6.1
- **Styling**: Tailwind CSS 4
- **Package manager**: pnpm 9
```

❌ Bad: "React project", "Uses TypeScript", "Postgres database" — too vague to be actionable.

#### Section 3: Directory Map (~15–30 lines)

Only directories an agent will read from or write to. Include purpose as inline comments. Mark generated directories (`dist/` — generated, do not edit). For monorepos, show the package layout at the top level.

#### Section 4: Boundaries — What NOT To Do (~10–15 lines)

```markdown
## Boundaries
- 🚫 **Never edit**: `.env`, `.env.*`, `dist/`, `.next/`, `node_modules/`
- 🚫 **Never commit**: Secrets, API keys, tokens, `.env` files
- 🚫 **Never touch**: `prisma/migrations/` (managed by Prisma CLI)
- ⚠️ **Ask before**: Adding dependencies, changing DB schema, modifying CI/CD config
- ✅ **Feel free**: Create/delete branches, edit source and tests, run any command
```

Every boundary needs a parenthetical reason. Agents ignore unexplained restrictions.

#### Section 5: Code Style (~15–25 lines)

Always include a concrete ✅/❌ example extracted from the actual codebase. One real example beats ten paragraphs of description. Only include rules that are consistently followed.

#### Section 6: Testing Conventions (~10–15 lines)

Framework, test location, naming conventions, coverage expectations. Include E2E commands if applicable.

#### Section 7: Git & PR Workflow (conditional, ~5–10 lines)

Only include if the project has specific conventions beyond standard Git.

#### Section 8: Environment & Setup (conditional, ~5–15 lines)

Only include if setup is non-trivial. Document required tools, first-time setup commands, and required env vars.

### 3.2 What to EXCLUDE

- ❌ **Project descriptions** — for README.md. Agents don't need your product's value prop.
- ❌ **Setup for every OS** — document the primary OS the team uses.
- ❌ **Contribution guidelines for humans** — CLA signing, code of conduct, issue templates.
- ❌ **Long prose explanations** — if a rule needs a paragraph, make it a concrete example or hard boundary instead.
- ❌ **Lists of every dependency** — agents read `package.json`. Only call out the 5-8 they'll actually touch.
- ❌ **Changelogs, roadmap, credits** — not actionable.
- ❌ **Duplicate information** — if it's in README AND AGENTS.md, cut it from AGENTS.md.

---

## 4. Reviewing and Updating Existing AGENTS.md Files

### 4.1 Audit Checklist

| Criterion | What to check |
|---|---|
| **Commands present?** | Are executable commands with flags listed? Are they correct and runnable? |
| **Commands first?** | Are commands near the top, where agents access them fastest? |
| **Stack specific?** | Are versions specified? Is the framework/runtime explicit? |
| **Structure mapped?** | Is the directory layout explained with purposes? |
| **Boundaries clear?** | Are "never touch" files/dirs explicitly listed? |
| **Examples over prose?** | Are there concrete ✅/❌ code examples? |
| **Concise?** | Is the file under ~250 lines? Is every line justified? |
| **Up to date?** | Do the commands actually work? Are dependencies current? |
| **Not duplicating README?** | Is the file agent-focused, not human-focused? |

### 4.2 Update Strategy

- **7+ criteria met**: Targeted edits only. Fix outdated commands, add missing boundaries, tighten prose.
- **3–6 criteria met**: Propose a restructured version alongside the original. Show the diff.
- **0–2 criteria met**: Create a new AGENTS.md. Archive the old one as `AGENTS.md.old`.
- **Multiple agent config files** (CLAUDE.md + AGENTS.md + `.cursor/rules/`): Consolidate into a single AGENTS.md if tools support it. Note tool-specific files that must be kept.

### 4.3 Legacy File Mapping

| Old file | Action |
|---|---|
| `AGENT.md` | Rename to `AGENTS.md`, add symlink `ln -s AGENTS.md AGENT.md` |
| `CLAUDE.md` | Migrate to `AGENTS.md`. Keep as symlink if Claude is a target agent. |
| `.cursor/rules/*.mdc` | Extract agent-relevant rules into `AGENTS.md`. Keep Cursor-specific rules in place. |
| `.github/copilot-instructions.md` | Migrate to `AGENTS.md`. Copilot Code Review reads both. |
| `.windsurfrules` | Migrate to `AGENTS.md`. Keep for Windsurf compatibility if needed. |

---

## 5. Hierarchical AGENTS.md Files

### 5.1 When to Create a Subdirectory AGENTS.md

Only when a subdirectory is **truly autonomous** — own build, tests, dependencies, and an agent working in it would be misled by the root AGENTS.md.

**Good candidates**: monorepo packages with independent build/test/lint, separately-deployed services, completely different language/runtime, independently-published SDKs.

**Bad candidates**: every top-level directory, feature folders, directories differing only in content (not tooling/conventions), directories with fewer than ~20 files.

### 5.2 Nested AGENTS.md Rules

- **Inheritance**: The closest AGENTS.md wins — no merging with parent files.
- **Avoid repetition**: Only what's DIFFERENT from root. A nested file might be 20–40 lines.
- **Cross-reference**: Root AGENTS.md should note which subdirectories have their own file.

### 5.3 Order of Operations

1. Create/update the root AGENTS.md first
2. Identify subdirectories that need their own (§5.1)
3. For each, create a minimal AGENTS.md covering only what differs
4. Update root AGENTS.md with cross-references

---

## 6. Execution — Step by Step

1. **Discovery**: Run the §2.1 checklist. Read key config files. Run build/test/lint commands to verify.
2. **Check for existing files**: `find . -maxdepth 3 \( -name "AGENTS.md" -o -name "AGENT.md" -o -name "CLAUDE.md" -o -name ".windsurfrules" \) 2>/dev/null`
3. **Evaluate or Plan**: If AGENTS.md exists, run §4.1 audit. Otherwise, plan content following §3.
4. **Present the plan**: Brief overview of sections, changes (if updating), and any ambiguous conventions. Use `ask_user_question` for anything you can't determine from the codebase.
5. **Write or Update**: Follow the format guidelines from §3. Reference `assets/example-agents-md.md` as a model.
6. **Verify**: Run every command listed. Verify every path exists. Check total length (~250 line target). Confirm no README duplication.
7. **Handle subdirectories**: Evaluate against §5.1. Create nested AGENTS.md files if justified.
8. **Report**: Summarize files created/modified, key sections, subdirectory files, and verified/unverified commands.

---

## 7. Quality Checklist

Before declaring done, confirm:

- [ ] Build command is listed and verified working
- [ ] Test commands include "all", "single file", and "single test" variants
- [ ] Lint/format commands include auto-fix variants
- [ ] Tech stack specifies language, framework, and key dependency versions
- [ ] Directory map covers all agent-relevant paths with purposes
- [ ] Boundaries list specific files/directories agents must never touch
- [ ] At least one ✅/❌ code style example is included
- [ ] Total file is under ~250 lines (or each line is justified)
- [ ] No marketing prose, README duplication, or human contribution guidelines
- [ ] Every listed command has been executed and confirmed working (or noted as unverified)
- [ ] Subdirectory AGENTS.md files only exist where justified by §5.1
- [ ] Root AGENTS.md cross-references nested AGENTS.md files if any exist

---

## 8. Anti-Patterns

| Anti-pattern | Fix |
|---|---|
| Dumping package.json scripts verbatim | Curate to the 3-5 commands agents actually run. |
| "Use best practices" | Replace with a concrete rule or ✅/❌ example. |
| Listing every dev dependency | List only the 5-8 key dependencies. |
| 500+ line AGENTS.md | Cut to ~250 lines max. Move details to nested files. |
| Paragraphs of architecture rationale | Add a one-line rule. Link to ADRs for rationale. |
| Duplicating the README | Cut everything in README unless agents specifically need it. |
| AGENTS.md in every subfolder | Only in truly autonomous subdirectories (§5.1). |
| Commands without flags | Always include the flags the team actually uses. |
| "Run tests before committing" without HOW | Always pair rules with the exact command. |
