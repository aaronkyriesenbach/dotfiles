---
name: implement-multiple
description: "Implement a scoped batch of open tickets (a count, a wave count, an explicit set, or all ready-for-agent) using subagent-driven waves."
argument-hint: "[a count, wave count, ticket set/label, or blank for all ready-for-agent]"
---

# Implement Multiple

Take a scoped batch of open tickets, group them into dependency-respecting **waves**, then implement one wave at a time with parallel subagents. Each subagent runs the [`/implement`](../implement/SKILL.md) skill against one ticket. This is a batch operation over your issue tracker — determine scope, plan the waves, confirm with the user, then execute wave by wave.

## 1. Read the tracker config

Read `docs/agents/issue-tracker.md`. If it doesn't exist, tell the user to run `/setup-engineering-skills` first and stop. This file tells you which CLI to use (`gh`, `glab`, or freeform) and the conventions for listing, reading, and commenting on issues.

## 2. Determine scope

The user's request: $ARGUMENTS (if blank, default to all ready-for-agent tickets, per the last bullet below)

Parse what the user asked for when they invoked this skill:

- **A ticket count** ("implement 5 tickets") — cap the total tickets run this pass at N, filled wave by wave in order (fill Wave 1 first, then Wave 2, etc.; never take a later wave's ticket over an earlier wave's).
- **A wave count** ("implement 2 waves") — run only the first N computed waves in full, regardless of ticket count.
- **An explicit label/set** ("implement all ready-for-agent tickets", "implement #12 and #14", a milestone, etc.) — use exactly that filter in step 3.
- **No scope given** — default to *all* ready-for-agent tickets, but this default **must be explicitly confirmed** in step 7 before any wave runs. Don't treat silence as consent to an open-ended, potentially large batch.

Carry whichever scope you parsed into steps 3 and 6 below.

## 3. Gather the open tickets

List open issues. Default to issues labelled ready for agent work (the tracker's `ready-for-agent` equivalent, per `docs/agents/triage-labels.md` if it exists) — these are the ones an agent can pick up without a human decision. If the user's scope (step 2) named an explicit filter instead (a label, a milestone, specific ticket numbers), use that filter here instead of the default.

For each candidate issue, fetch its full body, comments, and labels (per the tracker's "list issues" / "read an issue" convention). Drop anything that isn't actually actionable (still `needs-info`, `needs-triage`, or otherwise blocked on a human) and tell the user what you excluded and why.

## 4. Build the dependency graph

For each remaining issue, find what blocks it:

1. **Native dependencies** (GitHub): `gh api repos/<owner>/<repo>/issues/<n> --jq .issue_dependencies_summary.blocked_by` for the count, or list the edges directly via the dependencies endpoint. GitLab has an equivalent "blocked by" relation via `glab`.
2. **Body-text fallback**: scan the issue body for a `Blocked by: #12, #34` or `Depends on #12` line — some issues (or trackers without a dependencies API) only record this in prose.

A blocker only counts if it is itself in your candidate set **and still open**. A blocker that's closed, or outside the set entirely (already done, or not selected for this run), doesn't hold anything back.

## 5. Assign waves

Topologically sort by the blocking edges:

- **Wave 1**: every issue with no open blocker in the set.
- **Wave 2**: issues whose only open blockers are in Wave 1.
- **Wave N**: issues whose only open blockers are in Waves 1..N-1.

If a cycle exists (A blocks B blocks A), stop and flag it to the user instead of guessing — this needs a human decision, not a resolved wave.

## 6. Apply the scope

Trim the wave plan to whatever step 2 established:

- **Ticket count N**: walk the waves in order, taking tickets in full waves until adding the next wave would exceed N. If a wave would be split mid-wave to hit the count exactly, stop at the last fully-included wave instead and tell the user the count landed you at M tickets across K waves, not literally N — never half-run a wave.
- **Wave count N**: keep only Waves 1..N; drop the rest from this run.
- **Explicit set or default-all**: no trimming — every wave from step 5 runs.

Tell the user about any tickets/waves this dropped so the plan in step 7 reflects exactly what will run.

## 7. Present the plan and confirm

Show the user the full (post-scope) wave plan before touching any code:

```markdown
## Implementation waves

**Wave 1** (no blockers, run in parallel):
- #12 — <title>
- #14 — <title>

**Wave 2** (blocked by Wave 1):
- #15 — <title> (blocked by #12)
```

Wait for the user to confirm, adjust the set, or reorder before executing. This is a batch operation across multiple tickets — don't skip confirmation.

If step 2 found **no explicit scope** (the user just said "implement multiple" / ran the skill bare), make the confirmation explicit and pointed rather than a generic "proceed?": state plainly that no scope was given, that you're about to run *all* ready-for-agent tickets (name the count and wave count), and ask the user to confirm that's really what they want or to narrow it — this is the guardrail against burning tokens on a bigger batch than intended.

## 8. Execute one wave at a time

For each wave, in order:

1. **Select a subagent per ticket.** Default to `worker` — it's the implementation agent and the one `/implement` is written for. Only deviate when the ticket's own nature calls for it: a pure review/cleanup ticket suits `reviewer`; a research spike with no code change suits `researcher`. When in doubt, use `worker`.
2. **Launch the wave in parallel** with `worktree: true` so each ticket gets an isolated git worktree — parallel writers must not collide on the same working tree. Give every child the full issue body/comments (don't make it re-fetch), the issue number, and the instruction to apply the `implement` skill:

   ```
   subagent({
     tasks: [
       { agent: "worker", skill: "implement", task: "Implement issue #12: <title>.\n\n<full issue body>\n\nUse the implement skill: follow TDD at pre-agreed seams, run typechecking and tests, code-review, and commit." },
       { agent: "worker", skill: "implement", task: "Implement issue #14: ..." }
     ],
     worktree: true,
     concurrency: <wave size, capped sensibly>
   })
   ```
3. **Wait for the wave to finish**, then merge each worktree branch back into the base branch before starting the next wave — a later wave's tickets may build on this wave's code, so the base must be up to date before those children even start.
4. **Verify the merged state**: run the project's typecheck/build/test commands once per wave (not just per ticket) to catch cross-ticket integration issues `/implement`'s own single-ticket checks couldn't see.
5. If a child reports a blocker, a scope question, or a failing merge, stop and resolve it with the user before moving to the next wave — don't silently skip or reorder.

## 9. Summarize

After the last wave, report: tickets implemented (with commit/branch references), tickets skipped and why, and any follow-up the user needs to handle by hand (merge conflicts you couldn't auto-resolve, tickets that turned out blocked mid-run, etc.).

## Gotchas

- **Waves are a hard sequence, not a suggestion.** Never start Wave 2 before Wave 1's branches are merged back — its tickets were sequenced there specifically because they may depend on Wave 1's code, not just its ticket state.
- **A closed blocker doesn't retroactively unblock mid-run.** Compute the graph once at the start from the tickets you're actually running this pass; don't rescan the tracker mid-wave.
- **Same-wave tickets are assumed independent of each other**, not just unblocked — if two "unblocked" tickets clearly touch the same files/module, say so in the plan (step 5) and let the user split them across waves instead of racing two writers on the same area.
- **`/implement` already commits and code-reviews per ticket** — don't add a second commit or review pass per child; your job is the cross-ticket merge and the once-per-wave integration check.
- Skip tickets still in `needs-info`/`needs-triage` even if unblocked — "no open blocker" isn't the same as "ready for an agent."
- **Never silently default to "all ready-for-agent tickets."** An unscoped invocation is exactly the case where an oversized, unintended batch burns the most tokens — always surface the count and wave count and get an explicit yes before running.
- **A ticket-count scope never splits a wave.** Round down to the last fully-included wave and say so; running half of a wave defeats the point of waves being an atomic dependency unit.
