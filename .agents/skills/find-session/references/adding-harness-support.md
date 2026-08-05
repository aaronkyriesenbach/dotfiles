# Adding Support for Another Harness

This skill currently only knows how to search Pi's session logs. To extend it for another coding
harness (Claude Code, Codex CLI, etc.):

1. **Find out where that harness persists conversation history**, and in what format (JSONL tree like
   Pi, flat JSON transcript, SQLite, etc.) — check that harness's own docs, not assumptions carried
   over from Pi.
2. **Add a detection rule** to `SKILL.md`'s harness-detection step — an env var, a config-dir
   convention, or a CLI check that's cheap to run and specific to that harness.
3. **Write `references/harness-<name>.md`** following the shape of `references/harness-pi.md`:
   detection signal, storage location (with any override env vars), file format gotchas, and why any
   naive `grep`/full-text approach would misfire (if applicable).
4. **Add a script** under `scripts/` named `search_sessions_<name>.sh` (e.g. `search_sessions_pi.sh` is
   the Pi one) for that harness's format. Reuse the same CLI shape (`search <terms...>` returning
   compact candidates; `show <file>` returning a condensed human-text-only transcript) so the
   workflow in `SKILL.md` doesn't need harness-specific branches beyond step 1's detection.
5. **Update the harness-support table** in `SKILL.md` and this file.

Until a harness has a reference file and a script here, the skill's instruction is to stop and say so
rather than guessing at that harness's storage format.
