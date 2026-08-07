# Skill Anatomy Reference

Full structural reference for a skill/SKILL.md, drawn from the [Agent Skills specification](https://agentskills.io/specification).

## Directory Structure

```
skill-name/
├── SKILL.md          # Required. Frontmatter + instructions.
├── scripts/          # Helper scripts (optional)
│   └── do-thing.sh
├── references/       # Detailed docs loaded on-demand (optional)
│   └── api-ref.md
└── assets/           # Templates, configs, static files (optional)
    └── template.json
```

## SKILL.md Format

````markdown
---
name: skill-name
description: When to use this skill. Imperative, user-intent focused.
---

# Skill Title

Instructions go here. Use relative paths to reference bundled files.

See [references/api.md](references/api.md) for more details.
````

## Frontmatter Reference

| Field | Required | Rules |
| --- | --- | --- |
| `name` | **Yes** | 1-64 chars. Lowercase a-z, 0-9, hyphens. No leading/trailing/consecutive hyphens. |
| `description` | **Yes** | Max 1024 chars. Write for the model: imperative framing, user intent, trigger contexts. |
| `license` | No | License name or reference to bundled file. |
| `compatibility` | No | Max 500 chars. Environment requirements. E.g., "Requires Node.js 22+, pnpm, and gh CLI." |
| `metadata` | No | Arbitrary key-value map. E.g., `version: "1.0.0"`. |
| `allowed-tools` | No | Space-delimited list of pre-approved tools (experimental). |
| `disable-model-invocation` | No | When `true`, skill hidden from the system prompt. User must invoke it explicitly (e.g. `/skill:name`). |

### Name Validation

**Valid**: `pdf-processing`, `data-analysis`, `code-review`
**Invalid**: `PDF-Processing` (uppercase), `-pdf` (leading hyphen), `pdf--processing` (consecutive hyphens)

Pi does NOT require the name to match the parent directory, unlike the Agent Skills standard.

### Description Formatting Options

Multi-line descriptions in YAML:

```yaml
# Flow scalar (short)
description: Write or update agent skills. Use when creating new skills.

# Folded block scalar (multiline, newlines become spaces)
description: >
  Write or update an agent skill. Use when the user asks to create, write,
  design, or improve a skill. Covers discovery, planning, writing, and testing.

# Literal block scalar (multiline, newlines preserved)
description: |
  Write or update an agent skill.
  Use when creating new skills or updating existing ones.
```

Prefer `>` (folded) for multi-line descriptions — it keeps newlines as spaces in the rendered string.

## Invocation

Read `writing-for-agents`'s `SKILL-MECHANICS.md` for the model-invoked vs. user-invoked decision, router skills, and the mechanics (`disable-model-invocation`) that implement the choice.

## Progressive Disclosure Pattern

Keep the top-level prompt/SKILL.md under ~400 lines. Move detailed reference material into on-demand files (`references/`, or a same-named subdirectory for a standalone prompt).

**Tell the agent *when* to load each file**, not just *where* it is:

```markdown
<!-- ❌ Vague — agent won't know when -->
See references/ for details.

<!-- ✅ Conditional trigger — agent knows exactly when -->
If the API returns a non-200 status, read references/api-errors.md.
If you need to format the output for Slack, read references/slack-format.md.
```

A pointer's wording — not its target — decides whether and how reliably the agent reaches the material. See `writing-for-agents`'s "Context pointers" section for why.

## Relative Paths

All file references within a skill or prompt use paths relative to its directory:

```markdown
[API reference](references/api.md)
Run `./scripts/process.sh input.txt`
Copy `assets/template.json` to get started.
```

## Script Execution

Scripts in `scripts/` must be executable. The agent runs them with `bash`:

```bash
./scripts/validate.sh input.txt
python scripts/analyze.py data.json
```
