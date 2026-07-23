---
name: implement-multiple
description: "Implement a scoped batch of open tickets (an epic, a count, a wave count, an explicit set, or all ready-for-agent) using subagent-driven waves."
argument-hint: "[an epic, a count, wave count, or ticket set/label — if blank, you'll be asked to pick an epic]"
---

# Implement Multiple

Take a scoped batch of open tickets, group them into dependency-respecting **waves**, then implement one wave at a time with parallel subagents. Each subagent runs the [`/implement`](../implement/SKILL.md) skill against one ticket. This is a batch operation over your issue tracker — determine scope, plan the waves, confirm with the user, then execute wave by wave.

## 1. Read the tracker config

Read `docs/agents/issue-tracker.md`. If it doesn't exist, tell the user to run `/setup-engineering-skills` first and stop. This file tells you which CLI to use (`gh`, `glab`, or freeform) and the conventions for listing, reading, and commenting on issues.

## 2. Determine scope

The user's request: $ARGUMENTS (if blank, you'll be asked to pick an epic — see the last bullet below)

Parse what the user asked for when they invoked this skill:

- **An epic** ("implement the checkout-redesign epic", "implement epic #42") — scope to that epic's open, `ready-for-agent` children only (see step 3 for how to resolve them per tracker).
- **A ticket count** ("implement 5 tickets") — cap the total tickets run this pass at N, filled wave by wave in order (fill Wave 1 first, then Wave 2, etc.; never take a later wave's ticket over an earlier wave's). Combine with an epic scope when both are given (e.g. "implement 5 tickets from the checkout-redesign epic").
- **A wave count** ("implement 2 waves") — run only the first N computed waves in full, regardless of ticket count.
- **An explicit label/set, or "all ready-for-agent"** ("implement all ready-for-agent tickets", "implement #12 and #14", a milestone, etc.) — use exactly that filter in step 3. This includes cross-epic bulk scopes — they're still available, just never the default.
- **No scope given** — do NOT default to all ready-for-agent. Instead, list the available epics (open issues labelled `epic` that still have at least one open `ready-for-agent` child, per the per-tracker lookup in step 3), showing each epic's title, reference, and ready-child count. Ask the user to pick one — or to name an explicit alternative scope instead (all ready-for-agent, a label, specific tickets). Don't proceed until the user picks something explicit; there is no silent default.

Carry whichever scope you parsed into steps 3 and 6 below.

## 3. Gather the open tickets

**If the scope is an epic** (chosen explicitly, or picked from the list in step 2): resolve its children using the epic mechanism documented in `docs/agents/issue-tracker.md`'s "Epics" section — GitHub's sub-issues endpoint (`gh api repos/<owner>/<repo>/issues/<epic>/sub_issues`), GitLab's `Part of #<epic>` body-text scan over open issues, or (local files) the files under `.scratch/<feature-slug>/issues/`. Keep only children that are open and carry `ready-for-agent`.

**If listing available epics** (step 2's no-scope path): find open issues labelled `epic`, then for each, resolve its children (same mechanism as above) and keep only epics with at least one open `ready-for-agent` child. Exclude epics with zero remaining ready children — they're already fully cut and implemented, or not yet broken down into tickets.

**Otherwise** (a ticket count, wave count, explicit label/set, or "all ready-for-agent"): list open issues per the user's filter as today, but always exclude anything labelled `epic` — a spec/epic issue is never itself an implementable ticket.

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
- **An epic, explicit set, or "all ready-for-agent"**: no trimming — every wave from step 5 runs.

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

Wait for the user to confirm, adjust the set, or reorder before executing. This is a batch operation across multiple tickets — don't skip confirmation, even when the scope is a single epic picked from a list.

## 8. Execute one wave at a time

For each wave, in order:

1. **Select a subagent type and model per ticket, from your actual available agent roster** (the types listed in the `subagent` tool's own description — built-ins plus every custom agent under `.pi/agents/`/`~/.pi/agent/agents/`). Match the ticket's domain to the best-fit specialist by its description: a frontend/UI ticket suits `engineering-frontend-developer`, a backend/API ticket suits `engineering-backend-architect`, a schema/migration ticket suits `engineering-database-optimizer`, an infra/CI ticket suits `engineering-devops-automator` or `engineering-sre`, a security fix suits the matching `security-*` specialist, a mobile ticket suits `engineering-mobile-app-builder`, a pure review/cleanup ticket suits `engineering-code-reviewer`, a docs-only ticket suits `engineering-technical-writer`, and so on. Fall back to `general-purpose` when no specialist clearly fits — it inherits the parent's full system prompt and conventions, which is the safest default for a generic implementation ticket. Every agent type in the roster is opted into git-worktree isolation via `subagents-worktrees.json` (see below), so whichever type you pick, the child still gets an isolated worktree automatically. Then pick a model sized to the ticket's difficulty:
   - Routine, well-scoped, mechanical tickets (small fixes, boilerplate, config/doc changes) → a faster/cheaper model.
   - Standard feature/bugfix tickets → the default model.
   - Tickets that are architecturally risky, touch many files/modules, or have ambiguous/underspecified requirements → a stronger/higher-reasoning model.

   Judge this from the ticket's title, body, and any size/complexity signals the tracker exposes (e.g. `size:S`/`size:L` labels) — don't just default every ticket to the same model.
2. **Launch the wave in parallel**, one `subagent` call per ticket with the chosen `subagent_type` and `run_in_background: true`. Worktree isolation is automatic and config-driven (via the `@gotgenes/pi-subagents-worktrees` extension) — there is no `worktree` parameter on this tool, and none is needed: because every agent type is listed in `worktreeAgents`, each child transparently gets its own detached worktree before it runs, regardless of which specialist you picked. Give every child the full issue body/comments (don't make it re-fetch), the issue number, and the instruction to apply the `implement` skill:

   ```
   subagent({ subagent_type: "engineering-backend-architect", model: "sonnet", description: "Implement #12", run_in_background: true,
     prompt: "Implement issue #12: <title>.\n\n<full issue body>\n\nUse the implement skill: follow TDD at pre-agreed seams, run typechecking and tests, code-review, and commit." })
   subagent({ subagent_type: "general-purpose", model: "haiku", description: "Implement #14", run_in_background: true,
     prompt: "Implement issue #14: ..." })
   ```

   Each call returns an agent ID immediately; collect them all before moving to the next step. The extension's own concurrency limit (default 4, tunable via `/subagents:settings`) queues excess launches automatically — no need to compute a `concurrency` value yourself.
3. **Wait for the wave to finish** with `get_subagent_result({ agent_id, wait: true })` per child. Each result that made changes carries a trailer like `Changes saved to branch \`pi-agent-<id>\`. Merge with: \`git merge <branch>\`` — read the branch name from there (a child with no changes has its worktree removed automatically and carries no branch to merge). Merge every wave-member's branch back into the base branch before starting the next wave — a later wave's tickets may build on this wave's code, so the base must be up to date before those children even start.
4. **Verify the merged state**: run the project's typecheck/build/test commands once per wave (not just per ticket) to catch cross-ticket integration issues `/implement`'s own single-ticket checks couldn't see.
5. **Close each successfully implemented ticket** once its wave is merged and verified: post a closing comment with its commit/branch reference, then close it per the tracker's convention in `docs/agents/issue-tracker.md` (e.g. `gh issue close <n> --comment "..."`, or `glab issue note` followed by `glab issue close`, or the local-file equivalent). Do this per ticket, not as a batch note on the wave.
6. **Check whether any epic this wave touched is now fully done.** For each distinct epic among the tickets just closed (resolved via the same per-tracker lookup used in step 3), re-fetch its *complete* child set — not just this run's scope, since a ticket-count/wave-count trim or an unrelated earlier run may have left other children still open. If every child is now closed, post a summary comment on the epic listing the tickets that completed it, then close the epic too. If any child is still open, leave the epic open and note the remaining open count for the final summary.
7. If a child reports a blocker, a scope question, or a failing merge, stop and resolve it with the user before moving to the next wave — don't silently skip or reorder.

## 9. Summarize

After the last wave, report: tickets implemented and closed (with commit/branch references), any epics closed as a result (and which tickets completed them), tickets skipped and why, any epic touched this run that's still short of closing (with its remaining open-child count), and any follow-up the user needs to handle by hand (merge conflicts you couldn't auto-resolve, tickets that turned out blocked mid-run, etc.).

## Gotchas

- **Waves are a hard sequence, not a suggestion.** Never start Wave 2 before Wave 1's branches are merged back — its tickets were sequenced there specifically because they may depend on Wave 1's code, not just its ticket state.
- **A closed blocker doesn't retroactively unblock mid-run.** Compute the graph once at the start from the tickets you're actually running this pass; don't rescan the tracker mid-wave.
- **Same-wave tickets are assumed independent of each other**, not just unblocked — if two "unblocked" tickets clearly touch the same files/module, say so in the plan (step 5) and let the user split them across waves instead of racing two writers on the same area.
- **`/implement` already commits and code-reviews per ticket** — don't add a second commit or review pass per child; your job is the cross-ticket merge, the once-per-wave integration check, and closing tickets/epics once they're actually done.
- Skip tickets still in `needs-info`/`needs-triage` even if unblocked — "no open blocker" isn't the same as "ready for an agent."
- **Close tickets after their wave is verified, not the moment a subagent reports success.** A ticket that merges clean in isolation but fails the once-per-wave integration check isn't actually done — don't close it until step 8's verify step passes for that wave.
- **An epic closes on whichever run finishes its last ticket, not only on a run explicitly scoped to it.** Always re-check the epic's full child set (not just this run's scope) before closing — a trimmed run, or a bulk cross-epic run, may finish an epic incidentally.
- **An unscoped invocation always asks which epic first — never a silent batch.** List the available epics and their ready-child counts (step 2) and wait for the user to pick one, or to explicitly name an alternative scope like all ready-for-agent. The step 7 wave-plan confirmation is still required on top of that, regardless of how the scope was chosen.
- **A ticket-count scope never splits a wave.** Round down to the last fully-included wave and say so; running half of a wave defeats the point of waves being an atomic dependency unit.
- **Model *and* subagent type are per-ticket, not per-wave.** A wave can mix a cheap-model doc fix routed to `engineering-technical-writer` with a strong-model refactor routed to `engineering-backend-architect` — don't pick one model or one specialist for the whole wave.
- **This workflow depends on `subagents-worktrees.json`'s `worktreeAgents` covering every agent type you might pick in step 8.1.** There's no wildcard — the extension only isolates types explicitly listed by name. If you pick a specialist that isn't in `worktreeAgents`, that child silently runs unisolated in the parent cwd instead of a worktree (no error, no note). Keep the config's `worktreeAgents` list in sync with `.pi/agents/`/`~/.pi/agent/agents/` whenever you add a new custom agent type.
