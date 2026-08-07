# Model tiers

Reference doc for [`implement-multiple`](SKILL.md) step 8.1's per-ticket model selection and step 8.4's escalation-on-failure retry. Kept separate from the workflow prompt because model rosters shift roughly monthly — this file is what should need updating, not the workflow logic that reads it.

**Last reviewed:** 2026-07-31. Re-verify tier membership if this date is more than ~60 days stale, especially for anything added since — and prefer independent, practitioner-run evals over vendor launch posts where they disagree (see "Why the floor is here").

## How to use this

Pick a tier from the criteria below — not price, not file count alone — then pick the cheapest model in your available roster that belongs to it (table at the bottom). Bias toward the cheaper tier on a boundary call: `implement-multiple` step 8.4's once-per-wave verification is downstream of every subagent and will catch a wrong call before anything merges.

## Tiers

- **Tier 0 — mechanical, no logic change.** Formatting, config/version bumps, docs-only changes, extraction/labeling, changelog/scaffold generation. File count doesn't matter here — reformatting five files is still Tier 0.
- **Tier 1 — default, the floor for any logic change.** The moment a ticket writes or modifies behavior — even a one-line, single-file bugfix — it starts here, not Tier 0. See "Why the floor is here" for why the boundary is drawn by behavior change rather than size.
- **Tier 2 — escalate.** Footprint over roughly 5 files or crossing modules; a wide-refactor expand/migrate/contract batch (by blast radius, not by how mechanical the edit looks); migration/framework-upgrade/security-sensitive work; genuinely ambiguous requirements; or a Tier 1 attempt that already failed on this ticket.

## Rules

- Prefer the cheaper tier on a boundary call — verification is the safety net, not a reason to pre-emptively over-provision every ticket.
- A wave-verification failure that traces to one ticket's subagent output is a routing signal, not just a bug to hand-fix: retry that ticket one tier up first.
- Mechanical-looking isn't the same as cheap at scale — a wide-refactor batch is still Tier 1 floor at minimum, and usually belongs in Tier 2 once its footprint crosses the threshold above.
- A lab's cheapest tier isn't always positioned the same way — some (e.g. OpenAI's Luna/nano line) are explicitly support/extraction models; others (e.g. Anthropic's Haiku) are explicitly positioned as full coding models at a lower price. Check a model's own positioning, not just its price rank, before placing something new in Tier 0.

## Why the floor is here

Vendor benchmarks put the cheapest tier within ~5-8 points of the mid tier on aggregate coding scores (SWE-Bench Pro, DeepSWE, Coding Agent Index). Independent, practitioner-run evals diverge sharply on tasks that actually write or fix code: one reviewer's own long-horizon coding benchmark scored the mid tier far below its vendor-claimed number and excluded the cheapest tier from real implementation work entirely; an independent PR-review test had the cheapest tier catch under 40% of known bugs in a small diff; another found its main coding failure mode wasn't wrong reasoning but "looks done, isn't" — plausible code with self-written tests whose expected values were wrong. Because `implement-multiple` verifies once per wave rather than per ticket, that failure mode is costlier here than in an interactive tool with a human watching — hence the Tier 1 floor for any logic change, not the narrower gap vendor benchmarks alone would suggest.

## Model roster snapshot

Resolve these against whatever your actual provider/roster exposes (fuzzy-match by family name via the `subagent` tool's `model` parameter) rather than pinning to the exact IDs below once they've rotated.

| Tier | OpenAI | Anthropic | Google | Other |
| --- | --- | --- | --- | --- |
| 0 | `gpt-5.6-luna`, `gpt-5.4-nano`, `gpt-5-mini` | — | — | — |
| 1 | `gpt-5.6-terra`, `gpt-5.4-mini`, `gpt-4.1` | `claude-sonnet-5`, `claude-haiku-4.5` | `gemini-3-flash-preview` | `kimi-k2.7-code` |
| 2 | `gpt-5.6-sol`, `gpt-5.5` | `claude-opus-4.8` and later, `claude-fable-5` | `gemini-3.1-pro-preview` | — |

**Unverified — check before routing to it as a general implementation subagent:** `mai-code-1-flash-picker`. Not confirmed as a general-purpose coding model during this review (may be a routing/selection-specific model); don't place it by price alone without checking its actual docs first.
