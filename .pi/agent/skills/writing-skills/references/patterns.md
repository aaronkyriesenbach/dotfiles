# Instruction Patterns — Detailed Examples

Expanded examples for the patterns introduced in SKILL.md.

## Gotchas

The single highest-value content. Each entry prevents a specific mistake the agent would make without being told. Extract these from domain expertise and real corrections.

```markdown
## Gotchas
- The `users` table uses soft deletes (`deleted_at` column). Every query must
  include `WHERE deleted_at IS NULL` or it will return deactivated accounts.
- `user_id` in the database, `uid` in the auth service, and `accountId` in the
  billing API all refer to the same value. Don't assume the field name is consistent.
- The `/health` endpoint returns 200 as long as the web server process is running,
  even if the database is down. Use `/ready` for full service health checks.
- Staging Stripe webhooks return 200 but don't actually process. Check
  `payment_events` table for the real state.
- The `subscriptions` table is append-only. The active row is the one with the
  highest `version`, not the most recent `created_at`.
- The build cache is in `~/.cache/project-builds/`, not `node_modules/.cache/`.
  Clear it when you get stale snapshot errors.
```

**How to build**: Every time you correct the agent while using the skill, add the correction here. This section grows with real usage.

## Output Format Templates

When output format matters, provide a template. Agents pattern-match well against concrete structures.

### Inline Template (short, always needed)

```markdown
## Report format

Structure every analysis as:

```markdown
# [Analysis Title]

## Summary
[One-paragraph overview]

## Key Findings
- Finding 1 with data
- Finding 2 with data

## Recommendations
1. Actionable recommendation
2. Actionable recommendation
```

```

### External Template (long, conditional)

```markdown
## PR description format

Copy the template from `assets/pr-template.md` and fill it in.
```

## Checklists

Track progress through multi-step workflows. Especially valuable when steps have dependencies or validation gates.

```markdown
## Deployment workflow

Check each step:

- [ ] Step 1: Run `scripts/pre-deploy-check.sh` (validates config, DB, secrets)
- [ ] Step 2: Build: `npm run build`
- [ ] Step 3: Smoke test: `scripts/smoke-test.sh staging`
- [ ] Step 4: Deploy canary: `scripts/deploy.sh --canary 10%`
- [ ] Step 5: Monitor for 5 minutes: `scripts/monitor.sh --duration 300`
- [ ] Step 6: If healthy, full deploy: `scripts/deploy.sh --full`
- [ ] Step 7: Verify: `scripts/smoke-test.sh production`
```

## Validation Loops

Instruct the agent to validate before proceeding. The pattern: do → check → fix → re-check.

```markdown
## Form processing

1. Analyze the form: `python scripts/analyze_form.py input.pdf` → creates `fields.json`
2. Create your field mapping in `values.json`
3. Validate: `python scripts/validate.py fields.json values.json`
4. If validation fails:
   - Read the error messages carefully
   - Fix the issues in `values.json`
   - Run validation again
5. Only fill the form once validation passes: `python scripts/fill.py input.pdf values.json output.pdf`
```

## Plan-Validate-Execute

For batch or destructive operations. The agent creates a plan, validates it, and only then executes.

```markdown
## Batch rename

1. Generate rename plan: `scripts/generate-rename-plan.py src/ > rename-plan.json`
   (lists every old path → new path mapping)
2. Validate the plan: `scripts/validate-rename.py rename-plan.json`
   (checks: no path collisions, all source files exist, no destinations exist)
3. Review the plan output. If validation fails, fix and revalidate.
4. Execute: `scripts/execute-rename.py rename-plan.json`
5. Verify: `scripts/verify-rename.py rename-plan.json`
```

## Reusable Scripts

When you notice the agent independently rewriting the same logic across sessions, extract it into `scripts/`.

### Example: CSV parsing script

Instead of having the agent write CSV parsing code every time:

```python
# scripts/csv-summary.py
import csv, sys
from collections import Counter

with open(sys.argv[1]) as f:
    reader = csv.DictReader(f)
    rows = list(reader)

print(f"Rows: {len(rows)}")
print(f"Columns: {reader.fieldnames}")
for col in reader.fieldnames:
    non_empty = sum(1 for r in rows if r[col].strip())
    print(f"  {col}: {non_empty} non-empty")
```

Now the skill says:

```markdown
1. Run `python scripts/csv-summary.py data.csv` to understand the data
2. Based on the summary, write the analysis script
```
