# Testing and Optimizing Skill Descriptions

The description field determines whether a model-invoked skill triggers. Test it systematically.

## How Triggering Works

At startup, the agent loads only `name` and `description` of each skill. When the user's prompt matches a description, the agent loads the full SKILL.md (or prompt file). The description carries the entire burden of triggering.

**Key insight**: The agent only consults skills when the task requires knowledge beyond what it can handle alone. A simple "read this file" won't trigger a file-processing skill — the agent can handle it with basic tools.

## Writing a Test Query Set

Create ~20 queries: 8-10 that should trigger the skill, 8-10 that shouldn't.

### Should-Trigger Queries

Vary along these axes:

- **Phrasing**: formal, casual, with typos
- **Explicitness**: names the domain directly vs. describes the need without naming it
- **Detail**: terse vs. context-heavy (file paths, column names, backstory)
- **Complexity**: single-step vs. multi-step workflows

```json
[
  { "query": "Create a skill that helps with database migrations", "should_trigger": true },
  { "query": "I keep having to tell the agent how to run our deploy — can you make it remember?", "should_trigger": true },
  { "query": "Write me a skill for processing PDF forms", "should_trigger": true }
]
```

### Should-Not-Trigger Queries

The best negatives are **near-misses** — queries that share keywords with your skill but need something different:

```json
[
  { "query": "Write a Python script to parse CSV files", "should_trigger": false },
  { "query": "What's the weather today?", "should_trigger": false },
  { "query": "How do I install a VSCode extension?", "should_trigger": false }
]
```

Avoid obviously-irrelevant negatives — they don't test precision.

### Tips for Realism

Include: file paths, personal context ("my manager asked me to..."), company-specific names, casual language, and occasional typos.

## Testing Trigger Rates

Run each query through the agent with the skill installed. Run 3+ times per query (model behavior is non-deterministic). Compute trigger rate = fraction of runs where skill was invoked.

A query passes if:

- `should_trigger: true` and trigger rate ≥ 0.5, OR
- `should_trigger: false` and trigger rate < 0.5

## Avoiding Overfitting

Split queries into:

- **Train set (~60%)**: used to identify failures and guide improvements
- **Validation set (~40%)**: set aside, only used to check if improvements generalize

Both sets need proportional mix of should-trigger and should-not-trigger queries.

## Optimization Loop

1. **Evaluate** current description on both train and validation
2. **Identify failures** in train set only
3. **Revise description**:
   - Should-trigger failing → broaden scope or add trigger contexts
   - Should-not-trigger triggering → add specificity about what the skill does NOT do
   - Don't add keywords from failed queries (overfitting) — find the general category
   - If stuck after 3-4 iterations, try a structurally different framing
4. **Repeat** until train set passes or stops improving
5. **Select best** by validation pass rate (not necessarily the last iteration)

Usually 5 iterations is enough.

## Description Before/After Example

```yaml
# Before — too vague
description: Process CSV files.

# After — specific, pushy, user-intent focused
description: Analyze CSV and tabular data files — compute summary statistics,
  add derived columns, generate charts, and clean messy data. Use when the user
  has a CSV, TSV, or Excel file and wants to explore, transform, or visualize
  the data, even if they don't explicitly mention "CSV" or "analysis."
```

## Final Validation

After selecting a description:

1. Update the `description` field
2. Verify it's under 1024 characters
3. Manual sanity check: try a few prompts manually
4. Real check: 5-10 fresh queries (never seen during optimization) through the eval
