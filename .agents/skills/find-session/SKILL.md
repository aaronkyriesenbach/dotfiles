---
name: find-session
description: >
  Locate and summarize a past agent session/conversation that the user can't easily find themselves —
  triggers include "what did we discuss about X", "find that session where we talked about...",
  "summarize the conversation about Y", "did we cover Z before", or any request to recall prior session
  content by topic rather than by exact date/name. Searches the current coding-agent harness's session
  logs directly via a bundled script instead of manually grepping raw files, so it works with minimal
  context and scales to a large session history. Currently supports Pi only; stops and says so for any
  other or unrecognized harness rather than guessing at its storage format.
compatibility: Requires bash and jq (no Python or other runtime needed).
---

# Find Session

Recover a past conversation by topic when the user only remembers roughly what was discussed, not
which session it was in.

**Philosophy**: search compact, structured candidates first; only read full raw content once you know
exactly which file and which part of it you need.

## 1. Detect the harness

Run once, before anything else:

```bash
if [ "$PI_CODING_AGENT" = "true" ] || [ -n "$PI_SESSION_ID" ]; then
  echo pi
else
  echo unknown
fi
```

- **`pi`** → continue to step 2, use `references/harness-pi.md` for storage details if you need them.
- **anything else** → stop. Tell the user this skill only knows how to search Pi sessions today, and
  that support for their harness hasn't been added yet (see
  [references/adding-harness-support.md](references/adding-harness-support.md) if they want it built).
  Do not fall back to guessing a file location or grepping blind.

## 2. Search for candidates

Break the user's request into 3-6 varied search terms — their literal wording, likely synonyms, proper
nouns (tool/product/project names), and domain-specific terms. A single weak term (e.g. just "music")
will drown in noise or miss the session entirely; 3-6 specific terms narrow fast. See Gotchas.

```bash
./scripts/search_sessions_pi.sh search "<term1>" "<term2>" "<term3>" --limit 15
```

This prints, per matching file: path, `cwd`, session timestamp, which terms matched, and a couple of
short snippets — not the raw file. **Do not `read` or `cat` full session files at this stage** — the
script's output is already the low-context view of the candidates.

Useful flags:

- `--require-all` — only report files where every term matched (tightens results once you have several
  confident terms).
- `--cwd-filter <substring>` — restrict to sessions run from a project whose path contains this string,
  if the user gave you a hint about which project.
- `--days N` — restrict to sessions started in the last N days.
- `--json` — machine-readable output, if you need to post-process results.

## 3. Narrow to the right session

Rank candidates by recency and snippet relevance. If the top candidate's snippets already answer the
question, proceed to step 4. If several are plausible, or you need more surrounding context to pick the
right one:

```bash
./scripts/search_sessions_pi.sh show <path-to-file> --grep "<term>"
```

`show` prints only the human-written `user`/`assistant` text of that file — no thinking-block
signatures, no tool-call arguments, no raw tool-result payloads — so it stays cheap even for large
sessions. Drop `--grep` to print the whole condensed transcript once you're confident it's the right
file.

Only reach for the plain `read` tool on the raw `.jsonl` if you need something `show` intentionally
strips out — e.g. the exact tool calls made, URLs fetched, or command output.

## 4. If nothing found

Don't declare defeat after one search. Re-run step 2 with a fresh term set — broader/more generic
words, terms without harness- or project-specific jargon, a longer `--days` window, or `--limit`
raised. Try at most 2-3 revised searches. If still nothing, tell the user you couldn't find it and ask
for one more distinguishing detail (approximate date, project/directory, or another verbatim phrase) —
don't fabricate a plausible-sounding session.

## Gotchas

- **A single vague term returns too much or too little.** Generic English phrases ("without moving",
  "organize the files") appear by coincidence in unrelated sessions' prose. Prefer specific nouns,
  proper names, and multi-word phrases the user actually said, and require 2+ terms to match before
  trusting a candidate.
- **The session may not be under the project you'd expect.** A brainstorm about a not-yet-created
  project, or one run before `cd`-ing into its repo, lives under whatever `cwd` was active at the
  time — often the home directory (`~`) — not the project's own session directory. Don't restrict
  `--cwd-filter` unless the user is confident where they were.
- **An unnamed session won't surface via `/resume`'s search** (that only matches session
  names/titles). This script searches message content directly, which is why it works even when
  `/resume` wouldn't.
- **Never grep the raw JSONL for a keyword by hand.** Assistant `thinking` blocks carry a base64
  `thinkingSignature` field that can coincidentally contain any short string — a raw-text `grep` will
  report false hits inside it. `search_sessions_pi.sh` only reads real `text` content, so this can't
  happen; that's the whole reason the script exists instead of a one-line `grep -r`.
- **Tool-result content (web search dumps, fetched pages, file reads) is deliberately excluded** from
  what counts as a match. The user's own words and the assistant's own summaries are almost always
  enough to identify the right session, and including raw tool output would reintroduce the
  everything-matches-everything noise problem.

## Reference files

| Topic | File | When to load |
| --- | --- | --- |
| Pi session storage details, override env vars, why the script avoids `thinkingSignature` false positives | [references/harness-pi.md](references/harness-pi.md) | If you need to know exactly where/how Pi stores sessions, or want to double-check the false-positive story before explaining it to the user |
| How to extend this skill to a new harness | [references/adding-harness-support.md](references/adding-harness-support.md) | If the user asks to add support for a harness other than Pi |

## Scripts

```bash
./scripts/search_sessions_pi.sh search <term>... [--require-all] [--limit N] [--days N] [--cwd-filter STR] [--json]
./scripts/search_sessions_pi.sh show <file> [--grep TERM]
```
