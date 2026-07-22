---
name: to-tickets
description: Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to the configured tracker — edges as text in one file per ticket locally, or native blocking links on a real tracker.
argument-hint: "[optional: spec path, issue #, or URL]"
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets** — tracer-bullet vertical slices, each declaring the tickets that **block** it.

The issue tracker and triage label vocabulary should have been provided to you — run `/setup-engineering-skills` if not.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, an issue number or URL) as an argument, fetch it and read its full body and comments.

Argument passed: $ARGUMENTS (if blank, work from the conversation context)

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring should be done first

</vertical-slice-rules>

Give each ticket its **blocking edges** — the other tickets that must complete before it can start. A ticket with no blockers can start immediately. **IMPORTANT**: Use the issue tracker's native subissue/blocking functionality if it exists to mark which tickets block which.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change — rename a column, retype a shared symbol — whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket — green is promised only there.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct — does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 5. Publish the tickets to the configured tracker

Publish the approved tickets **in dependency order, one ticket at a time — create, then immediately link, before moving to the next ticket.** Never batch-create every ticket and come back to link them afterward; that second pass is the step that gets skipped. Each ticket must exist before its dependents are created, so its real identifier is available to link against.

**How** depends on the tracker `/setup-engineering-skills` configured — read `docs/agents/issue-tracker.md` for this repo's exact commands (its "Wayfinding operations → Blocking" section has the literal command for native blocking on this tracker; reuse it here, not just for `/wayfinder`):

- **Local files** → write one file per ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first). Each file's "Blocked by" lists the numbers/titles it depends on. Use the per-ticket file template below — one ticket per file, never a single combined file.
- **GitHub** → `gh issue create` the ticket, then for each blocker immediately run `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>` (the blocker's numeric database id via `gh api repos/<owner>/<repo>/issues/<n> --jq .id` — not `#number`, not `node_id`). Also write the "Blocked by" text in the body as a human-readable backup. If the dependencies API 404s (feature disabled on this repo), fall back to a `Blocked by: #<n>, #<n>` line at the top of the body and say so in your summary — do not silently skip the native link without noting the fallback. Additionally, link the ticket to its parent spec/epic via GitHub's native sub-issues endpoint (`docs/agents/issue-tracker.md`'s "Epics" section has the exact command) and write `Part of #<epic>` at the top of the body as its human-readable backup.
- **GitLab** → `glab issue create` the ticket, then for each blocker immediately post `glab issue note <child> --message "/blocked_by #<blocker>"`. Also write the "Blocked by" text in the description. Fall back to a `Blocked by:` line only if native blocking links are unavailable (free tier), and say so. Additionally, write `Part of #<epic>` at the top of the description — GitLab has no reliable free-tier native epic mechanism, so this text line is the operative link, not a fallback (see `docs/agents/issue-tracker.md`'s "Epics" section).
- **Other tracker (Linear, Jira, …)** → look up that tracker's native "blocks / is blocked by" relationship (not just a parent/sub-task link, unless sub-task is the only mechanism) and set it via its CLI/API/MCP tool immediately after creating the ticket. Also look for a native epic/parent-issue relationship and set it the same way; if none exists, fall back to a `Part of #<epic>` text line. Record the exact mechanisms you used in `docs/agents/issue-tracker.md` for next time if they aren't documented there yet.
- **Local files** → the `.scratch/<feature-slug>/issues/` directory the ticket file lives in already scopes it to its epic (`.scratch/<feature-slug>/spec.md`) — no extra field needed.

In every case: set each ticket's "Blocked by" text too, and apply the `ready-for-agent` triage label unless instructed otherwise — the tickets are agent-grabbable by construction. The parent spec/epic issue itself never gets `ready-for-agent` (see `to-spec`) — only these tickets do.

### 6. Verify every blocking edge and epic link landed natively

Before reporting the ticket set as done, re-fetch each published ticket that has one or more blockers and confirm the native relationship is actually set (e.g. `gh issue view <n> --json ...` for `issue_dependencies_summary.blocked_by`, or the equivalent read for the configured tracker) — don't trust that the create/link calls succeeded just because they didn't error. Do the same for the epic link — GitHub: confirm via `gh api repos/<owner>/<repo>/issues/<n>/parent`; GitLab/other: confirm the `Part of #<epic>` line is present in the published body. Build a small table of ticket → expected blockers (from the approved breakdown in step 4) → confirmed native blockers → epic link confirmed, and fix any mismatch before finishing. Report this table to the user as part of your summary, including any tickets where you had to fall back to text-only "Blocked by" because native linking wasn't available.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

Do NOT close or modify any parent issue.

<local-ticket-template>

# <NN> — <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective — not a layer-by-layer implementation list.

**Blocked by:** the numbers/titles of the tickets that gate this one, or "None — can start immediately".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

</local-ticket-template>

<issue-template>

## Parent

`Part of #<epic>` — the epic/spec issue this ticket was cut from (also recorded as a native sub-issue link on trackers that support it — see `docs/agents/issue-tracker.md`'s "Epics" section).

## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective — not layer-by-layer implementation.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A reference to each blocking ticket, or "None — can start immediately".

</issue-template>

In either form, avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

Work the frontier one ticket at a time with `/implement`, clearing context between tickets.
