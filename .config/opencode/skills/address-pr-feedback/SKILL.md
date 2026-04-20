---
name: address-pr-feedback
description: Address unresolved PR review comments by offering to fix easy issues, applying code changes, and replying/resolving threads. Auto-detects feedback JSON from a prior get-pr-feedback run, or accepts an optional PR number to fetch fresh data.
---

# Address PR Feedback

## Overview

Address unresolved review threads on a GitHub pull request by:

1. Offering to fix easy issues.
2. Applying code changes with user confirmation.
3. Replying to threads and resolving them.

This skill expects feedback data from a prior `get-pr-feedback` run. It will auto-detect the JSON file, or fetch fresh data if needed.

## Required Inputs

- **PR identifier** (optional): PR number, branch name, or full URL. If omitted, the skill auto-detects the most recent feedback JSON for the current repository.

## Prerequisites

- `gh` CLI authenticated with access to the target repository.
- `jq` installed.
- The current working directory must be inside the target repository.

## Script Contract

All scripts are located in the `get-pr-feedback` skill's scripts directory:

- `<get-pr-feedback-root>/scripts/fetch_feedback.sh <pr-identifier>` — Fetches unresolved threads, writes JSON.
- `<get-pr-feedback-root>/scripts/reply_and_resolve_thread.sh <thread-id> <reply-body>` — Posts a reply to a thread and resolves it in one call.

Where `<get-pr-feedback-root>` is the `get-pr-feedback` skill directory (typically `~/.config/opencode/skills/get-pr-feedback`).

## Workflow

### Step 0 — Pre-flight validation and locate feedback data

**Pre-flight: Verify the local checkout matches the PR.**

1. Determine the PR number. Either use the provided PR identifier, or extract it from the most recent feedback JSON filename (`/tmp/pr_feedback_{owner}_{repo}_{pr_number}.json`).
2. Resolve the PR's head branch and repository using `gh pr view <pr-number> --json headRefName,headRepository -q '.headRepository.owner.login + "/" + .headRepository.name + " " + .headRefName'`.
3. Get the current repo with `gh repo view --json owner,name -q '.owner.login + "/" + .name'`.
4. Get the current branch with `git branch --show-current`.
5. **If the current repo does not match the PR's repository**, STOP and warn:
   > "⚠️ The current repository (`{current}`) does not match the PR's repository (`{expected}`). You are likely in the wrong directory. Please `cd` to the correct repo and try again."
6. **If the current branch does not match the PR's head branch**, STOP and warn:
   > "⚠️ The current branch (`{current}`) does not match the PR's branch (`{expected}`). You should check out the PR branch first so fixes land on the correct branch. Run: `git checkout {expected}`"
7. If both match, proceed.

**Locate feedback data:**

1. Determine `owner` and `repo` from `gh repo view --json owner,name -q '.owner.login + "_" + .name'`.
2. Look for `/tmp/pr_feedback_{owner}_{repo}_*.json` files.
3. If exactly one exists, use it. If multiple exist, use the most recently modified one.
4. If none exist and a PR identifier was provided, run `fetch_feedback.sh <pr-identifier>` to generate it.
5. If none exist and no PR identifier was provided, ask the user for a PR number.

Read the JSON. Each entry contains:
- `thread_id`: GraphQL node ID
- `thread_status`: `active` or `outdated`
- `path`: file path the comment targets
- `line`: line number
- `comments`: array of `{ author, body, createdAt }`

### Step 1 — Analyze threads (if not already analyzed)

If this is a fresh fetch (Step 0 ran `fetch_feedback.sh`), analyze each thread:

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
- If no feedback data can be found and no PR identifier is provided, ask the user.
- If the current repo or branch does not match the PR, stop and warn the user. Do NOT proceed with fixes.
