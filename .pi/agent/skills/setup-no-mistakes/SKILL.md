# Set up a New Project with `no-mistakes`

This skill explains how to install, configure, and use `no-mistakes` — an AI-driven validation pipeline by kunchenguid — on a new project.

> **Source**: https://github.com/kunchenguid/no-mistakes | Docs: https://kunchenguid.github.io/no-mistakes/

**What it is**: `no-mistakes` puts a local git proxy (the "gate") in front of your real remote. Push to `no-mistakes` instead of `origin`, and it spins up a disposable worktree, runs review → test → docs → lint → push → PR → CI, and opens a clean PR automatically once every check passes. It is agent-agnostic (works with Claude, Codex, Pi, OpenCode, Rovo Dev, Copilot, or ACP targets).

---

## 1. Install

**macOS / Linux** (one-liner):
```sh
curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
```

**Windows** (PowerShell):
```powershell
irm https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.ps1 | iex
```

**Go install** (no embedded telemetry):
```sh
go install github.com/kunchenguid/no-mistakes/cmd/no-mistakes@latest
```

**From source**:
```sh
git clone git@github.com:kunchenguid/no-mistakes.git
cd no-mistakes
make build
make install
```

The installer puts the real binary in `~/.no-mistakes/bin`, symlinks it to `~/.local/bin` or `/usr/local/bin`, and restarts the background daemon.

**Telemetry**: Official release binaries include the default self-hosted telemetry. Disable with `NO_MISTAKES_TELEMETRY=0`. Override host/ID with `NO_MISTAKES_UMAMI_HOST` and `NO_MISTAKES_UMAMI_WEBSITE_ID`.

---

## 2. Prerequisites

| Dependency | Required for | Check with |
|---|---|---|
| `git` | Everything | `git --version` |
| One agent binary | Pipeline AI steps | `no-mistakes doctor` |
| `gh` CLI | GitHub PR + CI | `gh auth status` |
| `glab` CLI (v1.5x) | GitLab MR + CI | `glab auth status` |
| `NO_MISTAKES_BITBUCKET_EMAIL` + `NO_MISTAKES_BITBUCKET_API_TOKEN` | Bitbucket Cloud PR + CI | — |

**Supported agents** (for `agent: auto` resolution order): `claude`, `codex`, `opencode`, `acli` (Rovo Dev), `pi`, `copilot`.

Optional: `acpx` binary for `agent: acp:<target>` (ACP protocol agents).

```sh
no-mistakes doctor   # Check what's available
```

---

## 3. Initialize a Project

Navigate to any git repo with an `origin` remote:

```sh
cd /path/to/your/project
no-mistakes init
```

This creates a local bare gate repo at `~/.no-mistakes/repos/<id>.git`, installs a post-receive hook, adds a `no-mistakes` git remote to your working repo, installs the `/no-mistakes` agent skill at user level, and ensures the daemon is running.

For **GitHub fork contributions**:
```sh
# origin should point at the parent repo
git remote set-url origin git@github.com:parent-owner/repo.git
no-mistakes init --fork-url git@github.com:your-user/repo.git
```

`init` is idempotent — safe to re-run later to refresh gate wiring or update the skill after an upgrade.

---

## 4. Configure the Pipeline

Configuration is optional — the default `agent: auto` path works. Two config files:

| File | Scope |
|---|---|
| `~/.no-mistakes/config.yaml` | Global defaults for all repos |
| `<repo>/.no-mistakes.yaml` | Per-repo overrides |

### Global config (`~/.no-mistakes/config.yaml`)

```yaml
# Default agent for all repos
agent: auto   # auto | claude | codex | rovodev | opencode | pi | copilot | acp:<target>

# Optional agent binary path overrides
agent_path_override:
  claude: /Users/you/bin/claude
  codex: /opt/homebrew/bin/codex

# Optional extra CLI flags per native agent (global only)
agent_args_override:
  codex:
    - -m
    - gpt-5.4
    - --full-auto

# CI monitoring timeout (idle timeout, re-armed on base-branch movement)
ci_timeout: "168h"   # 7 days; use "unlimited" to never self-terminate

log_level: info      # debug | info | warn | error

# Max auto-fix attempts per step. 0 = disabled.
auto_fix:
  rebase: 3
  review: 0          # disabled by default — requires manual approval
  test: 3
  document: 3
  lint: 3
  ci: 3

# Transcript-based intent extraction from local agent sessions
intent:
  enabled: true
  threshold: 0.2
  slack_days: 3
  disabled_readers: []   # claude, codex, opencode, rovodev, pi, copilot

# Test evidence storage (default: temporary local)
test:
  evidence:
    store_in_repo: false
    dir: .no-mistakes/evidence
```

### Per-repo config (`<repo>/.no-mistakes.yaml`)

```yaml
# Override agent for this repo
agent: codex

# Explicit test/lint/format commands
commands:
  test: "bun run test"
  lint: "bun run check"
  format: "bun run format"

# Skip review/doc checks for generated files
ignore_patterns:
  - "*.generated.go"
  - "vendor/**"

# Per-repo auto-fix overrides
auto_fix:
  lint: 5

# Per-repo intent overrides
intent:
  enabled: true
```

**Precedence**: Repo config overlays global config. `agent` is overridable per-repo. `agent_path_override`, `agent_args_override`, `acpx_path`, and `acp_registry_overrides` are global-only.

---

## 5. Push Through the Gate

Three ways to trigger the same pipeline:

### a) `git push no-mistakes` (explicit Git path)

```sh
git checkout -b feat/my-feature
# ... do work, commit ...
git push no-mistakes
```

The push lands in the local gate repo, the hook notifies the daemon, and the daemon starts the pipeline in a disposable worktree. Your working tree stays clean.

### b) `no-mistakes` (TUI + setup wizard)

```sh
no-mistakes             # Interactive — wizard if no active run
no-mistakes -y          # Accept defaults automatically
no-mistakes --skip test,lint   # Skip steps for one run
```

The TUI shows pipeline progress, pauses for approval, lets you select findings and trigger fixes. Keybindings: `j/k` scroll, `space` toggle finding, `a` approve, `f` fix, `s` skip, `x` abort, `d` toggle diff, `y` toggle yolo mode, `?` help overlay.

### c) `/no-mistakes` (agent skill)

Inside a coding agent, validate existing committed work:

```
/no-mistakes
```

Or do a task AND gate it:

```
/no-mistakes add a --json flag to the status command
```

The agent inspects scope, preserves unrelated work, commits only the task changes on a feature branch, passes the task text as `--intent`, runs the pipeline, applies safe fixes itself, and stops to relay anything needing your judgment.

---

## 6. Pipeline Steps (in order)

```
intent → rebase → review → test → document → lint → push → pr → ci
```

| # | Step | What it does | Auto-fix limit |
|---|------|-------------|----------------|
| 1 | **Intent** | Use supplied intent or infer from recent agent transcripts | N/A |
| 2 | **Rebase** | Fetch fresh remote + branch target, rebase onto them | 3 |
| 3 | **Review** | AI code review of your diff | 0 (requires approval) |
| 4 | **Test** | Run baseline tests + gather evidence for available intent | 3 |
| 5 | **Document** | Update docs for code changes, report unresolved gaps | initial pass |
| 6 | **Lint** | Run linters/static analysis | 3 |
| 7 | **Push** | Safely push validated branch to configured target | N/A |
| 8 | **PR** | Create or update pull request | N/A |
| 9 | **CI** | Watch CI + mergeability, auto-fix failures | 3 |

If the branch has no diff after rebase, remaining steps are skipped.

**Data-loss guard**: Force-pushes are checked against the live push target and refused when they would discard commits the run did not incorporate. Every force-push uses `--force-with-lease=<ref>:<sha>` with an explicit SHA anchor.

---

## 7. Auto-Fix Configuration

When a pipeline step finds issues, `no-mistakes` can automatically ask the agent to fix them before pausing for your approval.

**Finding actions**:
- `auto-fix` — objective issues safe to fix automatically
- `ask-user` — intent-sensitive or ambiguous issues that pause for approval
- `no-op` — informational notes only

**Fix commits** use step-specific prefixes: `no-mistakes(review):`, `no-mistakes(test):`, `no-mistakes(lint):`, etc.

**Yolo mode** (`y` in TUI, `--yes` on AXI) auto-resolves paused steps: fixes `auto-fix` and `ask-user` findings once, approves fix-review gates, and approves gates with only `no-op` findings.

---

## 8. Provider Integration

### GitHub
```sh
brew install gh   # or install from https://github.com/cli/cli
gh auth login
```

### GitLab
```sh
brew install glab   # v1.5x required
glab auth login
```

### Bitbucket Cloud
```sh
export NO_MISTAKES_BITBUCKET_EMAIL=you@example.com
export NO_MISTAKES_BITBUCKET_API_TOKEN=your-api-token
```

**Without any provider setup**, you get the full local gate: rebase, review, test, document, lint, and push through normal Git transport. PR automation and CI monitoring require provider wiring.

---

## 9. Agent AXI Interface (for coding agents)

Agents drive the gate non-interactively via `no-mistakes axi`:

```sh
# Home view — check daemon, active runs, help
no-mistakes axi

# Start validation for the current branch
no-mistakes axi run --intent "the user's goal"

# Answer an approval gate
no-mistakes axi respond --action approve
no-mistakes axi respond --action fix --findings F1,F2
no-mistakes axi respond --action skip

# Check status of the current run
no-mistakes axi status

# View step logs
no-mistakes axi logs --step review

# Cancel the active run
no-mistakes axi abort
```

Key rules for agents:
- `--intent` is required when starting a new run — describe the goal, not the diff
- Read every return and respond at each `gate:` — the run never advances past a gate on its own
- Resolve `auto-fix` findings on judgment, ignore `no-op` when approving, stop on `ask-user`
- Do NOT `abort` or `rerun` to go fix a finding yourself while a run is active — use `axi respond --action fix`
- After `outcome: checks-passed`, summarize the run and ask the user to review/merge (the CI monitor is still live)

---

## 10. Common Commands Reference

| Command | What it does |
|---------|-------------|
| `no-mistakes init` | Initialize or refresh the gate for current repo |
| `git push no-mistakes <branch>` | Push through the gate |
| `no-mistakes` | Open TUI (or setup wizard if no active run) |
| `no-mistakes attach` | Attach to active run (any branch) |
| `no-mistakes rerun` | Rerun pipeline for current branch |
| `no-mistakes status` | Show repo, daemon, and run status |
| `no-mistakes runs` | List recent pipeline runs |
| `no-mistakes stats` | Show historical usage stats |
| `no-mistakes doctor` | Check system health |
| `no-mistakes update` | Update binary + reset daemon |
| `no-mistakes update --beta` | Update to latest beta |
| `no-mistakes eject` | Remove gate from current repo |
| `no-mistakes daemon start\|stop\|restart\|status` | Daemon management |

---

## 11. Troubleshooting

**Daemon not running**: `no-mistakes daemon start` or `no-mistakes init` (re-initialize).

**Agent binaries not found**: Set `agent_path_override` in `~/.no-mistakes/config.yaml`. Check `~/.no-mistakes/logs/daemon.log` for resolution warnings.

**Agent recommendations not working**: Ensure `NO_MISTAKES_NO_UPDATE_CHECK` is not suppressing update checks for binary compatibility.

**Login-shell env vars not passing to daemon**: Put env vars in login shell rc files (`.zprofile`, `.zshrc`, `.bash_profile`). The daemon reloads from the login shell on macOS/Linux.

**PR step skipped**: Check provider CLI is installed and authenticated (`gh auth status`, `glab auth status`). For Bitbucket, verify the two env vars are set.

**"Cannot determine daemon executable path" on update**: Ensure the daemon was started by a known binary path.

**Fork routing not working**: Verify `origin` points at the parent (not the fork) and you used `no-mistakes init --fork-url <fork-url>`.

**Nudging a stale CI monitor**: After a failed/cancelled run or a closed PR, use `no-mistakes rerun` to cancel the stale monitor and re-run. Use `no-mistakes axi abort --run <id>` to reap an orphaned monitor from outside its worktree.

---

## 12. Environment Variables

| Variable | Purpose |
|----------|---------|
| `NM_HOME` | Override data directory (default: `~/.no-mistakes`) |
| `NO_MISTAKES_TELEMETRY=0` | Disable telemetry |
| `NO_MISTAKES_UMAMI_HOST` | Override telemetry host |
| `NO_MISTAKES_UMAMI_WEBSITE_ID` | Override telemetry website ID |
| `NO_MISTAKES_NO_UPDATE_CHECK=1` | Suppress background update checks |
| `NO_MISTAKES_BITBUCKET_EMAIL` | Bitbucket Cloud account email |
| `NO_MISTAKES_BITBUCKET_API_TOKEN` | Bitbucket Cloud API token |
| `NO_MISTAKES_BITBUCKET_API_BASE_URL` | Bitbucket Cloud API base URL |
| `XDG_DATA_HOME` | OpenCode transcript discovery |
| `GLAB_CONFIG_DIR` | glab config directory for self-hosted GitLab detection |
| `XDG_CONFIG_HOME` | Fallback for glab config location |