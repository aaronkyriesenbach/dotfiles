---
name: address-pr-feedback
description: Address unresolved PR review comments by offering to fix easy issues, applying code changes, and replying/resolving threads.
---

# Address PR Feedback

## Overview

Address unresolved review threads on a GitHub pull request by:

1. Offering to fix easy issues.
2. Applying code changes with user confirmation.
3. Replying to threads and resolving them.

This skill fetches the latest unresolved feedback directly from GitHub and addresses it.

## Required Inputs

- **PR identifier**: PR number, branch name, or full URL (same formats `gh pr view` accepts).

## Prerequisites

- `gh` CLI authenticated with access to the target repository.
- `jq` installed.
- The current working directory must be inside the target repository.

## Script Contract

All scripts are located in the `get-pr-feedback` skill's scripts directory:

- `<get-pr-feedback-root>/scripts/preflight_check.sh <pr-identifier>` — Verifies the local checkout matches the PR's repo and branch. Outputs `pr_number`, `pr_repo`, `pr_branch`, `current_repo`, `current_branch`, `status` (one of `pass`, `repo_mismatch`, `branch_mismatch`).
- `<get-pr-feedback-root>/scripts/fetch_feedback.sh <pr-identifier>` — Fetches unresolved threads, writes JSON.
- `<get-pr-feedback-root>/scripts/reply_and_resolve_thread.sh <thread-id> <reply-body>` — Posts a reply to a thread and resolves it in one call.

Where `<get-pr-feedback-root>` is the `get-pr-feedback` skill directory (typically `~/.config/opencode/skills/get-pr-feedback`).

## Workflow

### Step 0 — Pre-flight validation and fetch feedback

**Pre-flight: Verify the local checkout matches the PR.**

1. Run the preflight check script:
   ```bash
   <get-pr-feedback-root>/scripts/preflight_check.sh <pr-identifier>
   ```
2. Parse the key=value output. Then:
   - **If `status=repo_mismatch`**: STOP and warn:
     > "The current repository (`{current_repo}`) does not match the PR's repository (`{pr_repo}`). You are likely in the wrong directory. Please `cd` to the correct repo and try again."
   - **If `status=branch_mismatch`**: STOP and warn:
     > "The current branch (`{current_branch}`) does not match the PR's branch (`{pr_branch}`). You should check out the PR branch first so fixes land on the correct branch. Run: `git checkout {pr_branch}`"
   - **If `status=pass`**: proceed.

**Fetch feedback:**

```bash
<get-pr-feedback-root>/scripts/fetch_feedback.sh <pr-identifier>
```

Read the output JSON. Each entry contains:
- `thread_id`: GraphQL node ID
- `thread_status`: `active` or `outdated`
- `path`: file path the comment targets
- `line`: line number
- `comments`: array of `{ author, body, createdAt }`

### Step 1 — Analyze threads

For each unresolved thread:

1. Read the **file and line range** referenced by the comment in the local checkout.
2. **Summarize** the reviewer's concern in 1-2 sentences.
3. Assess **factual**, **actionable**, and **fixability** (see `get-pr-feedback` skill for definitions).
4. Present the summary table.

If the user has already seen the analysis (e.g., from a prior `get-pr-feedback` run in the same session), skip re-analysis and proceed directly to Step 2.

### Step 2 — Offer fixes

Ask the user:

> "I found N threads that can be easily fixed. Would you like me to fix them? Reply with one of:
> - `fix-all` — fix all easy-fix threads
> - `fix-select` — let me choose which to fix
> - `skip` — skip fixes entirely"

If the user selects `fix-select`, list the easy-fix threads by number and ask which to fix.

**Before applying any fix:**
- Read the relevant AGENTS.md files for the changed paths.
- Follow existing code patterns and conventions.
- Make minimal, targeted changes — do not refactor surrounding code.

**After applying fixes:**
- Run `lsp_diagnostics` on each changed file.
- Show the user what was changed and ask for confirmation before proceeding to reply/resolve.

### Step 3 — Reply and resolve

After fixes are confirmed (or skipped), ask the user:

> "Would you like me to reply to the fixed threads and resolve them? Reply `yes` or `no`."

If yes, for each fixed thread:
1. Compose a brief reply summarizing what was done (e.g., "Fixed — added `@IsOptional()` decorator.").
2. Reply and resolve: `<get-pr-feedback-root>/scripts/reply_and_resolve_thread.sh <thread-id> <reply-body>`

For threads classified as `false` (comment is factually wrong), ask separately:

> "N threads appear to be factually incorrect. Would you like me to reply explaining why and resolve them? Reply `yes` or `no`."

If yes, compose a reply explaining why the comment is incorrect (cite the actual code) and resolve.

## Confirmation Gates

- **Before applying fixes**: Show planned changes, wait for explicit `fix-all`, `fix-select`, or `skip`.
- **Before replying/resolving**: Show planned replies, wait for explicit `yes` or `no`.
- If user says `stop`, `hold`, `pause`, or `cancel` at any gate, halt immediately.

## Hard Rules

- Do NOT check out a different branch. Analyze and fix from the current working tree.
- Do NOT apply fixes without user confirmation.
- Do NOT post replies or resolve threads without user confirmation.
- Do NOT refactor or change code unrelated to the review comment being addressed.
- Do NOT commit changes — only edit files. The user decides when to commit.
- If `gh` or `jq` is not available, stop and tell the user.
- If the PR identifier is not provided, ask the user.
- If the current repo or branch does not match the PR, stop and warn the user. Do NOT proceed with fixes.
