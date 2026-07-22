# Issue tracker: Local Markdown

Issues and specs (you may know a spec as a PRD) for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` — never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each issue file (see `triage-labels.md` for the role strings)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Epics (specs broken into tickets)

Used by `to-spec`, `to-tickets`, and `implement-multiple`. The feature directory `.scratch/<feature-slug>/` already is the epic-to-tickets grouping — `spec.md` is the epic, everything under `issues/` belongs to it. No extra label or manifest is needed.

- **Mark the spec as an epic**: `spec.md` gets a `Type: epic` line near the top instead of a `Status:`/triage line — it isn't itself a triageable ticket.
- **List an epic's tickets**: list files under `.scratch/<feature-slug>/issues/`.
- **List available epics**: list `.scratch/*/spec.md` files that still have at least one file under their `issues/` with `Status: ready-for-agent` (or equivalent open/unclaimed state).
- **Close an epic**: once every file under its `issues/` is closed, append a `## Comments` note to `spec.md` listing which tickets completed it, then add `Status: complete` near its `Type: epic` line.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` — the Notes / Decisions-so-far / Fog body.
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.
