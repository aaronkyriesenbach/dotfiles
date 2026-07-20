---
name: SKILL-NAME
description: DESCRIPTION — imperative, user-intent focused. Say when to use this skill. Mention contexts even when the user doesn't name the domain directly. Under 1024 characters.
---

# SKILL TITLE

One-sentence summary of what this skill helps the agent do.

**Philosophy**: One-line core principle that guides the agent's approach.

---

## 1. When to Use vs. Skip

<!-- Help the agent decide whether to load this skill -->

**Use when**:

- Condition 1
- Condition 2
- Condition 3

**Skip when**:

- Condition 1
- Condition 2

---

## 2. Setup (if needed)

```bash
# Install dependencies
cd /path/to/skill && npm install

# Set up configuration
cp config.example.json config.json
# Edit config.json with your values
```

**Prerequisites**: List any required tools, runtimes, or credentials.

---

## 3. Core Workflow

<!-- The step-by-step procedure. Numbered, concrete. -->

### Step 1: Discovery / Preparation

Concrete actions with specific commands or code.

### Step 2: Main Action

What the agent actually does.

### Step 3: Validation

How to verify the work is correct.

### Step 4: Delivery

What to present to the user and how.

---

## 4. Patterns to Use

<!-- Reusable instruction patterns -->

### Pattern 1

```markdown
1. Do the thing
2. Run validation: `./scripts/validate.sh`
3. If validation fails, fix and re-run
4. Only proceed when validation passes
```

### Pattern 2

```markdown
Progress:
- [ ] Step 1: Description
- [ ] Step 2: Description
- [ ] Step 3: Description
```

---

## 5. Gotchas

<!-- Non-obvious facts that defy reasonable assumptions. The highest-value section. -->

- Gotcha 1 — what the agent would naturally assume, and the truth
- Gotcha 2 — every gotcha prevents a specific, concrete mistake
- Gotcha 3 — extract these from real corrections during skill usage

---

## 6. Output Format (if applicable)

```markdown
# [Title]

## Summary
[One paragraph]

## Key Findings
- Finding 1
- Finding 2

## Recommendations
1. Action 1
2. Action 2
```

---

## 7. Reference Files

<!-- Load these on-demand, not all at once -->

| Topic | File | When to load |
| --- | --- | --- |
| API reference | [references/api.md](references/api.md) | If the API returns a non-200 status |
| Schema details | [references/schema.md](references/schema.md) | When writing queries |
| Template output | [assets/output-template.md](assets/output-template.md) | When producing final output |

---

## 8. Scripts (if applicable)

```bash
./scripts/validate.sh input.txt     # Validates input against schema
./scripts/process.sh input.txt      # Main processing script
./scripts/summarize.sh output/       # Generates summary report
```
