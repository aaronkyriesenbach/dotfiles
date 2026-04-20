---
name: get-pr-feedback
description: Fetch all unresolved PR review comments, summarize each, and assess factual accuracy, actionability, and fixability. Presents a structured report. Does NOT apply fixes or reply to threads — use address-pr-feedback for that.
---

# Get PR Feedback

## Overview

Collect every unresolved review thread on a GitHub pull request, then for each thread:

1. Summarize the reviewer's concern.
2. Assess whether the comment is **factual** (technically correct).
3. Assess whether the comment is **actionable** (suggests a concrete change).
4. Assess **fixability** — can it be resolved with a straightforward code change?

## Required Inputs

- **PR identifier**: PR number, branch name, or full URL (same formats `gh pr view` accepts).

## Prerequisites

- `gh` CLI authenticated with access to the target repository.
- `jq` installed.
- The current working directory must be inside the target repository (so `gh` can resolve owner/repo).

## Script Contract

- `<root>/scripts/fetch_feedback.sh <pr-identifier>` — Resolves PR metadata, fetches all review threads via GraphQL (paginated), filters to unresolved, writes JSON. Outputs `owner`, `repo`, `pr_number`, `output_json`, `status`.

## Workflow

### Step 0 — Pre-flight validation

Before fetching feedback, verify that the local checkout matches the PR:

1. Resolve the PR's head branch and repository using `gh pr view <pr-identifier> --json headRefName,headRepository -q '.headRepository.owner.login + "/" + .headRepository.name + " " + .headRefName'`.
2. Get the current repo with `gh repo view --json owner,name -q '.owner.login + "/" + .name'`.
3. Get the current branch with `git branch --show-current`.
4. **If the current repo does not match the PR's repository**, STOP and warn:
   > "⚠️ The current repository (`{current}`) does not match the PR's repository (`{expected}`). You are likely in the wrong directory. Please `cd` to the correct repo and try again."
5. **If the current branch does not match the PR's head branch**, STOP and warn:
   > "⚠️ The current branch (`{current}`) does not match the PR's branch (`{expected}`). You should check out the PR branch first so the analysis reflects the actual code under review. Run: `git checkout {expected}`"
6. If both match, proceed.

### Step 1 — Fetch unresolved threads

```bash
<root>/scripts/fetch_feedback.sh <pr-identifier>
```

Read the output JSON. Each entry contains:
- `thread_id`: GraphQL node ID
- `thread_status`: `active` or `outdated`
- `path`: file path the comment targets
- `line`: line number
- `comments`: array of `{ author, body, createdAt }`

### Step 2 — Analyze each thread

For every unresolved thread:

1. Read the **file and line range** referenced by the comment in the local checkout.
2. **Summarize** the reviewer's concern in 1-2 sentences.
3. **Factual check** — compare the comment's claims against the actual code:
   - `factual` — accurately describes the code's behavior or a real risk.
   - `false` — mischaracterizes the code (e.g., claims a decorator is missing when it exists).
   - `uncertain` — cannot determine without runtime/context not available locally.
4. **Actionable check** — does the comment request a specific change?
   - `actionable` — a concrete fix or improvement is suggested.
   - `informational` — raises a concern but offers no specific remedy.
   - `question` — asks a question that needs an answer, not a code change.
5. **Fixability check** — can this be resolved with a straightforward code change?
   - `easy-fix` — small, localized change (add a decorator, fix a typo, add validation, add an index, etc.).
   - `moderate` — requires changes across a few files or moderate refactoring.
   - `complex` — requires architectural changes, new features, or cross-cutting concerns.
   - `not-applicable` — comment is false, informational, or a question with no code change needed.

### Step 3 — Present results

Print a structured report grouped by file path. For each thread:

```
### <file-path>:<line>
**Reviewer**: <author>
**Status**: active | outdated
**Summary**: <1-2 sentence summary>
**Factual**: factual | false | uncertain — <brief reasoning>
**Actionable**: actionable | informational | question — <brief reasoning>
**Fixability**: easy-fix | moderate | complex | not-applicable — <brief reasoning>
```

After all threads, print a summary table:

| # | File | Line | Reviewer | Factual | Actionable | Fixability |
|---|------|------|----------|---------|------------|------------|

### Step 4 — Stop

After presenting the report, STOP. Do NOT offer to fix, reply, or resolve threads.

If the user wants to address the feedback, they should use the `address-pr-feedback` skill.

## Hard Rules

- Do NOT check out a different branch. Analyze from the current working tree.
- Do NOT apply any fixes or edits.
- Do NOT post replies or resolve threads.
- Do NOT offer to fix issues — that is the `address-pr-feedback` skill's job.
- If `gh` or `jq` is not available, stop and tell the user.
- If the PR identifier cannot be resolved, stop and tell the user.
- If the current repo or branch does not match the PR, stop and warn the user. Do NOT proceed with analysis.
