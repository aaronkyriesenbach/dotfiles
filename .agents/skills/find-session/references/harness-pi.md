# Pi

## Detecting Pi as the current harness

- `PI_CODING_AGENT` is `"true"`, and/or `PI_SESSION_ID` / `PI_SESSION_FILE` are set (see Pi's
  `environment-variables.md`). These are injected into every LLM-callable bash command, so a plain
  `echo "$PI_CODING_AGENT"` / `echo "$PI_SESSION_ID"` is enough to confirm it.

## Where sessions live

Default: `~/.pi/agent/sessions/`, one subdirectory per working directory (`/` replaced with `-`,
wrapped in leading/trailing `--`). Each session is a JSONL file:
`~/.pi/agent/sessions/--<cwd-with-dashes>--/<timestamp>_<uuid>.jsonl`.

Two env vars can move this, and the script already respects both:

- `PI_CODING_AGENT_SESSION_DIR` — overrides the sessions directory directly.
- `PI_CODING_AGENT_DIR` — overrides the whole config dir (sessions live at `<dir>/sessions`); default
  is `~/.pi/agent`.

Subagent runs nest their own session files under the parent session's directory (e.g.
`<session-dir>/tasks/*.jsonl` or `<uuid>/run-N/session.jsonl`) — `search_sessions_pi.sh` walks
recursively, so these are included automatically.

## Dependencies

`search_sessions_pi.sh` uses `jq` for JSON parsing (installed on most dev machines; `brew install jq` /
`apt install jq` if missing) — deliberately no Python, so the skill works without a project's Python
environment being set up.

## Why the script, not grep

A session file's `assistant` messages have a `thinking` content block carrying a `thinkingSignature`
field — an opaque base64 blob, unrelated to what was actually discussed. Plain `grep` over the raw
JSONL treats that blob as text and produces false-positive hits (a 4-character coincidental substring
match inside base64 looks identical to a real keyword match). `search_sessions_pi.sh` only extracts the
`text` field of `text`-typed content blocks from `user`/`assistant`/`custom_message` entries — it never
touches `thinkingSignature`, tool-call arguments, or raw tool-result payloads, so it can't produce that
class of false positive.

## Full JSONL schema

If you need to parse fields `search_sessions_pi.sh` doesn't cover (e.g. `model_change`, `compaction`,
`label` entries), see Pi's own `docs/session-format.md` — it documents every entry type and the full
`AgentMessage` union.
