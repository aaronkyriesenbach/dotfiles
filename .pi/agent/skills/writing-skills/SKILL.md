---
name: writing-skills
description: Write or update an agent skill. Use when the user asks to create, write, design, or improve a skill, or when they describe a task they want the agent to handle better. Covers the full lifecycle — discovery, planning, writing, and testing — and applies best practices from the Agent Skills ecosystem.
---

# Writing Skills

This skill teaches you how to create an effective agent skill from a user's request. Your job: elicit enough information to produce a high-quality first draft, then deliver it following the best practices and patterns in this skill.

**Philosophy**: A good skill adds what the agent lacks, wastes no tokens on what it already knows, and triggers reliably when it's needed. Every line must earn its place.

---

## 1. The Skill Lifecycle

```
[User's Request] → Discovery → Plan → Draft → Review → Deliver
```

### Step 1: Discovery — Understand What's Needed

Before writing a single line, ask the user clarifying questions. Use `ask_user_question`. Don't guess — the first draft quality depends entirely on how well you understand the domain.

**Minimum questions to ask**:

- **Task scope**: What exactly should this skill help the agent do? What's in scope vs. out?
- **Trigger context**: When should the agent load this skill? What user prompts or situations?
- **Domain knowledge**: Are there specific tools, APIs, conventions, or gotchas the agent wouldn't know?
- **Category**: Does this map to a known skill category? (See [references/categories.md](references/categories.md))

**If the user has examples** of the task being done well (past conversations, runbooks, style guides, code), ask them to share them. Skills anchored in real expertise outperform those derived from general knowledge.

### Step 2: Plan the Structure

Plan the skill's shape before writing. Decide:

| Decision | Guidance |
|---|---|
| **Scope** | One coherent unit of work. Too narrow → multiple skills for one task. Too broad → never triggers precisely. |
| **Category** | Identify which of the 9 skill categories this falls into. See [references/categories.md](references/categories.md). |
| **Prescriptiveness** | Map each section to "flexible" (agent has freedom) or "rigid" (must follow exactly). |
| **SKILL.md size** | Aim for 150-300 lines. Over ~400 lines → split reference material into `references/`. |
| **Scripts needed?** | If the agent will repeatedly write the same boilerplate, bundle it as a script in `scripts/`. |
| **Templates needed?** | If output format matters, store templates in `assets/`. |

### Step 3: Draft — Write the Skill

Write the skill directory following the Agent Skills specification. See [references/skill-anatomy.md](references/skill-anatomy.md) for the full frontmatter and structure reference. Apply these content principles:

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

### Step 4: Review Against Quality Checklist

Before delivering, verify:

- [ ] **SKILL.md under 400 lines** — move reference content to `references/` if needed
- [ ] **Gotchas section present** — non-obvious facts the agent would get wrong without being told
- [ ] **No "agent already knows this" padding** — cut explanations of fundamentals
- [ ] **Defaults provided** — a clear recommended approach, not a menu
- [ ] **Procedures over declarations** — reusable methods, not single-instance answers
- [ ] **Description targets triggers** — uses imperative framing, focused on user intent, mentions contexts
- [ ] **Description < 1024 chars** — the hard limit per spec
- [ ] **Name is valid** — lowercase, hyphens, 1-64 chars, no leading/trailing/consecutive hyphens
- [ ] **Relative paths** for references, scripts, assets
- [ ] **Prescriptiveness calibrated** — rigid where it matters, flexible elsewhere

### Step 5: Deliver

Present the skill to the user. Tell them:

- The skill name and where it was created
- What it covers (scope) and what it doesn't
- How to trigger it (what user prompts match the description)
- Any setup steps (dependencies, config)
- Known limitations or future improvements to consider

---

## 2. Patterns to Use in Every Skill

These are the highest-leverage patterns from the Agent Skills ecosystem. Use at least the first two in every skill.

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

See [references/patterns.md](references/patterns.md) for detailed examples, including templates for output format and reusable script design.

---

## 3. Writing the Description

The `description` is the sole trigger mechanism. The agent scans it at startup and decides whether to load the skill. An under-specified description → skill never triggers. An over-broad description → triggers when it shouldn't.

**How to write an effective description**:

1. **Use imperative framing**: "Use when…" not "This skill does…"
2. **Focus on user intent**: Describe what the user is trying to achieve, not the skill's internals
3. **Be pushy about contexts**: Name specific situations, including cases where the user doesn't name the domain directly
4. **Keep it concise**: A few sentences, well under the 1024-character limit

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

See [references/testing.md](references/testing.md) for how to systematically test and optimize descriptions.

---

## 4. Gotchas for Skill Authors

Lessons from real skill-building experience:

- **Don't explain fundamentals.** The agent knows what JSON, HTTP, SQL, and React are. Cut any sentence that starts with a definition.
- **One skill, one job.** "Write and deploy an API" is two skills. Split them.
- **Descriptions are not summaries.** They're trigger rules for the agent. Write them accordingly.
- **Over-rigid instructions backfire.** If the agent can't adapt to the user's context, the skill becomes a straitjacket. Be prescriptive only where it matters.
- **The agent won't read references unless told when to.** "See references/" is useless. Say: "If the API returns 401, read `references/auth-errors.md`."
- **First drafts need refinement.** Expect to iterate after real usage. Watch for false triggers, missed triggers, and instructions the agent ignores.
- **A skill directory with only SKILL.md is fine.** Don't create `scripts/` or `references/` until you have content that justifies them.
- **Extract gotchas from corrections.** Every time you have to correct the agent while using the skill, add that correction to the gotchas section.

---

## 5. Templates

Start from one of these templates depending on complexity:

- **Simple skill**: [assets/skill-template.md](assets/skill-template.md) — for straightforward single-workflow skills
- **Extensive skill**: [assets/skill-template-extensive.md](assets/skill-template-extensive.md) — for skills with references, scripts, and multi-step workflows

Copy the template, fill it in, then strip any sections that don't apply.

---

## 6. Reference Files

Load these on-demand when you need deeper detail:

| Topic | File |
|---|---|
| Skill categories (the 9 types) | [references/categories.md](references/categories.md) |
| Full frontmatter + structure spec | [references/skill-anatomy.md](references/skill-anatomy.md) |
| Detailed instruction patterns | [references/patterns.md](references/patterns.md) |
| Testing & optimizing descriptions | [references/testing.md](references/testing.md) |
