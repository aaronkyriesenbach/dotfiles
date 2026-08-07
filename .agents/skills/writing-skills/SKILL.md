---
name: writing-skills
description: Write or update an agent skill. Use when the user asks to create, write, design, or improve a skill, or when they describe a task they want the agent to handle better. Covers the full lifecycle — discovery, planning, writing, and testing — plus the vocabulary for judging a skill's quality.
disable-model-invocation: true
---

# Writing Skills

A skill exists to wrangle determinism out of a stochastic system. **Predictability** — the agent taking the same *process* every run, not producing the same output — is the root virtue everything below serves. A good skill adds what the agent lacks, wastes no tokens on what it already knows, and triggers reliably when it's needed. Every line must earn its place.

Read the `writing-for-agents` skill first — it's the vocabulary and principles reference (context pointers, information hierarchy, leading words, pruning) this skill assumes and builds on. What follows here is skill-specific: the lifecycle, concrete patterns, and templates for actually producing one.

---

## 1. The Skill Lifecycle

```
[User's Request] → Discovery → Plan → Draft → Review → Deliver
```

### Step 1: Discovery — Understand What's Needed

Seed task: $ARGUMENTS (if blank, start discovery from scratch)

Before writing a single line, ask the user clarifying questions. Use `ask_user_question`. Don't guess — the first draft's quality depends entirely on how well you understand the domain. Use the seed task above (if given) as your starting point, not a substitute for asking.

**Minimum questions to ask**:

- **Task scope**: What exactly should this skill help the agent do? What's in scope vs. out?
- **Trigger context**: When should the agent load this skill? What user prompts or situations?
- **Domain knowledge**: Are there specific tools, APIs, conventions, or gotchas the agent wouldn't know?
- **Category**: Does this map to a known skill category? (See [categories.md](references/categories.md).)

**If the user has examples** of the task being done well (past conversations, runbooks, style guides, code), ask them to share them. Skills anchored in real expertise outperform those derived from general knowledge.

### Step 2: Plan the Structure

Plan the skill's shape before writing. Decide:

| Decision | Guidance |
| --- | --- |
| **Scope** | One coherent unit of work. Too narrow → multiple skills for one task. Too broad → never triggers precisely. |
| **Category** | Identify which of the 9 skill categories this falls into. See [categories.md](references/categories.md). |
| **Invocation** | Model-invoked (default, keeps a `description`) costs **context load** every turn but the agent — and other skills — can fire it on its own. User-invoked (`disable-model-invocation: true`) costs the user **cognitive load** instead (they're the index who must remember it exists) but is free in context. Reserve user-invoked for skills that should never fire unasked; if several pile up, add one **router skill** that names them. See [skill-anatomy.md](references/skill-anatomy.md). |
| **Prescriptiveness** | Map each section to "flexible" (agent has freedom) or "rigid" (must follow exactly). |
| **SKILL.md size** | Aim for 150-300 lines. Over ~400 lines → split reference material into `references/`. |
| **Scripts needed?** | If the agent will repeatedly write the same boilerplate, bundle it as a script in `scripts/`. |
| **Templates needed?** | If output format matters, store templates in `assets/`. |

### Step 3: Draft — Write the Skill

Write the skill directory following the Agent Skills specification. See [skill-anatomy.md](references/skill-anatomy.md) for the full frontmatter and structure reference. Apply these content principles:

**Add what the agent lacks, omit what it knows.** The agent already knows what Markdown, TypeScript, Docker, or git are. Don't explain them. Focus on: project-specific conventions, non-obvious edge cases, specific APIs/tools to use, and domain procedures.

**Favor procedures over declarations.** Teach *how to approach* a class of problems, not *what to produce* for one specific instance. Write reusable methods:

```markdown
<!-- ❌ Single-use answer -->
Join the `orders` table to `customers` on `customer_id` and sum `amount`.

<!-- ✅ Reusable method -->
1. Read `references/schema.md` to find relevant tables
2. Join using the `_id` foreign key convention from schema
3. Apply user's filters as WHERE clauses
4. Aggregate and format as a markdown table
```

**Provide defaults, not menus.** Pick one recommended approach. Mention alternatives only as fallbacks:

```markdown
<!-- ❌ Menu of options -->
You can use pypdf, pdfplumber, PyMuPDF, or pdf2image...

<!-- ✅ Clear default -->
Use pdfplumber for text extraction. For scanned PDFs, use pdf2image with pytesseract.
```

**Match specificity to fragility.** Be prescriptive for brittle operations (migrations, deployments, destructive actions). Give freedom for flexible tasks (code review, analysis, scaffolding).

**End every step on a checkable completion criterion.** Can the agent tell done from not-done? Where it matters, make it exhaustive too ("every modified model accounted for", not "produce a change list") — a vague criterion invites the agent to declare victory before the work is genuinely finished.

**Reach for a leading word.** A leading word is a compact concept already living in the model's pretraining (*tight*, *red*, *tracer bullet*) that the agent thinks with while running the skill. One good word replaces a phrase restated at every site it applies ("fast, deterministic, low-overhead" → *tight*) and gives the agent a sharper hook to hang its behavior on. Prefer an existing word over inventing one — a coined term recruits no priors and costs you definition tokens to explain it. See `writing-for-agents`'s "Leading words" section for the full technique.

### Step 4: Review Against Quality Checklist

Before delivering, verify:

- [ ] **SKILL.md under 400 lines** — move reference content to `references/` if needed (fixes **sprawl**)
- [ ] **Gotchas section present** — non-obvious facts the agent would get wrong without being told
- [ ] **No "agent already knows this" padding** — cut explanations of fundamentals (**no-ops**: does the line change behavior versus what the model already does by default?)
- [ ] **Defaults provided** — a clear recommended approach, not a menu
- [ ] **Procedures over declarations** — reusable methods, not single-instance answers
- [ ] **Each meaning lives in one place** — no fact or rule restated in two sections (**duplication**)
- [ ] **No stale content** — every line still bears on what the skill actually does today (**sediment**)
- [ ] **Completion criteria are checkable and exhaustive** where it matters
- [ ] **Description targets triggers** — imperative framing, focused on user intent, mentions contexts, one trigger phrase per distinct branch (no restating the same trigger as a synonym)
- [ ] **Description < 1024 chars** — the hard limit per spec
- [ ] **Name is valid** — lowercase, hyphens, 1-64 chars, no leading/trailing/consecutive hyphens
- [ ] **Relative paths** for references, scripts, assets
- [ ] **Prescriptiveness calibrated** — rigid where it matters, flexible elsewhere

### Step 5: Deliver

Present the skill to the user. Tell them:

- The skill name and where it was created
- What it covers (scope) and what it doesn't
- How to trigger it (what user prompts match the description, or how to invoke it by hand if user-invoked)
- Any setup steps (dependencies, config)
- Known limitations or future improvements to consider

---

## 2. Patterns to Use in Every Skill

These are the highest-leverage patterns from the Agent Skills ecosystem. Use at least the first two in every skill. See [patterns.md](references/patterns.md) for full worked examples of each.

### Gotchas (Required)

The single highest-value pattern. Concrete corrections to assumptions the agent will make without being told. Build this section from domain expertise — every gotcha prevents a real mistake.

```markdown
## Gotchas
- The `users` table uses soft deletes. Queries must include `WHERE deleted_at IS NULL`.
- `/health` returns 200 even when the DB is down. Use `/ready` for full service health.
- `user_id` in DB, `uid` in auth service, `accountId` in billing API — all the same value.
```

### Default Approach (Required)

Always give the agent a clear first path. Mention alternatives only as fallbacks.

### Checklists for Multi-Step Workflows

```markdown
Progress:
- [ ] Step 1: Analyze inputs
- [ ] Step 2: Generate plan
- [ ] Step 3: Validate plan
- [ ] Step 4: Execute
- [ ] Step 5: Verify output
```

### Validation Loops

Do the work → run a validator → fix issues → repeat until clean:

```markdown
1. Make your edits
2. Run validation: `./scripts/validate.sh`
3. If validation fails, review errors, fix, and re-run
4. Only proceed when validation passes
```

### Plan-Validate-Execute (for Destructive/Batch Operations)

```markdown
1. Create a plan file (`plan.json`)
2. Validate with `./scripts/validate-plan.py plan.json`
3. Only execute after validation passes: `./scripts/execute.py plan.json`
```

---

## 3. Writing the Description

The `description` is the sole trigger mechanism for a model-invoked skill — it's a **context pointer**; read `writing-for-agents`'s "Context pointers" section for how a pointer's wording (not its target) decides whether and how reliably the agent reaches it, and for the shared pruning rules (front-load the leading word, one trigger per branch, cut identity the body already carries).

What's specific to a skill's description:

1. **Use imperative framing**: "Use when…" not "This skill does…"
2. **Focus on user intent**: Describe what the user is trying to achieve, not the skill's internals
3. **Be pushy about contexts**: name specific situations, including cases where the user doesn't name the domain directly
4. **Keep it concise**: well under the 1024-character limit

```yaml
# ❌ Too vague
description: Helps with skills.

# ❌ Implementation-focused
description: This skill writes markdown files for agent skills.

# ✅ User-intent focused with triggers
description: Write or update an agent skill. Use when the user asks to create, write, design,
  or improve a skill, or when they describe a task they want the agent to handle better.
  Covers the full lifecycle — discovery, planning, writing, and testing.
```

For a user-invoked skill (`disable-model-invocation: true`), the description becomes human-facing instead — a one-line summary, trigger phrasing stripped, since only a human typing the name will ever reach it.

See [testing.md](references/testing.md) for how to systematically test and optimize a model-invoked description's trigger rate.

---

## 4. Gotchas for Skill Authors

Lessons from real skill-building experience:

- **Don't explain fundamentals.** The agent knows what JSON, HTTP, SQL, and React are. Cut any sentence that starts with a definition.
- **One skill, one job.** "Write and deploy an API" is two skills. Split them.
- **Descriptions are not summaries.** They're trigger rules for the agent. Write them accordingly.
- **Over-rigid instructions backfire.** If the agent can't adapt to the user's context, the skill becomes a straitjacket. Be prescriptive only where it matters.
- **The agent won't read references unless told when to.** "See references/" is useless. Say: "If the API returns 401, read `references/auth-errors.md`."
- **Steer positive, not negative** — see `writing-for-agents`'s Negation section for why a prohibition backfires; the cure is the same for a skill's instructions as for any document.
- **First drafts need refinement.** Expect to iterate after real usage. Watch for false triggers, missed triggers, and instructions the agent ignores.
- **A skill directory with only SKILL.md is fine.** Don't create `scripts/` or `references/` until you have content that justifies them.
- **Extract gotchas from corrections.** Every time you have to correct the agent while using the skill, add that correction to the gotchas section.

---

## 5. Information Hierarchy and When to Split

Read `writing-for-agents`'s "Information hierarchy" and "When to split" sections for the full model (steps vs. reference, disclosed vs. in-file, progressive disclosure, co-location, splitting by sequence) — it applies to a skill exactly as it does to any agent-consumed document. The one skill-specific addition, splitting by invocation (model- vs. user-invoked), is in `skill-anatomy.md`.

---

## 6. Templates

Start from one of these templates depending on complexity:

- **Simple skill**: [skill-template.md](references/skill-template.md) — for straightforward single-workflow skills
- **Extensive skill**: [skill-template-extensive.md](references/skill-template-extensive.md) — for skills with references, scripts, and multi-step workflows

Copy the template, fill it in, then strip any sections that don't apply.

---

## 7. Reference Files

Load these on-demand when you need deeper detail:

| Topic | File |
| --- | --- |
| Vocabulary and principles for writing any agent-consumed document (read this first) | `writing-for-agents` skill |
| Skill categories (the 9 types) | [categories.md](references/categories.md) |
| Full frontmatter + structure spec, invocation mechanics | [skill-anatomy.md](references/skill-anatomy.md) |
| Detailed instruction patterns with worked examples | [patterns.md](references/patterns.md) |
| Testing & optimizing descriptions | [testing.md](references/testing.md) |
