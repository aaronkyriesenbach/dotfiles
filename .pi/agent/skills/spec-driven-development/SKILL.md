# Spec-Driven Development Skill

Integrates spec-kit (GitHub's Spec-Driven Development toolkit) into firstmate's ship lifecycle.

**Key fact**: spec-kit commands are slash commands installed in the project's `.pi/prompts/` or `.claude/skills/` directory by `specify init --integration <agent>`. The `specify` CLI itself is only a bootstrap and extension management tool — it has no `feature`, `plan`, `tasks`, `specify`, or `implement` subcommands. All SDD workflow commands exist as agent prompt files.

Trigger points:

- **Dispatch evaluation**: Load this skill when dispatching a ship task to decide whether to use spec-driven vs. straight implementation.
- **Spec-driven flow**: Reference the correct `/speckit.*` prompt or dispatch a crewmate to run it at each stage.

---

## 1. When to Use Spec-Driven vs. Skip to Implementation

The captain's rule: **you decide based on complexity.** A small, well-defined change skips spec-kit entirely and goes straight to a crewmate as a normal ship task.

### Use spec-driven when the change involves

- Multiple files, modules, or layers (e.g. backend + frontend + DB)
- New feature with multiple user stories
- Ambiguous requirements that benefit from explicit specification
- Cross-domain work (separate frontend/backend concerns)
- Something the captain explicitly flags as "spec this out"

### Skip spec-kit when the change is

- A single-file bug fix
- A trivial addition to an existing function
- A well-understood, scoped change the captain describes concretely
- Something the captain says is small/obvious

### When uncertain, err toward spec-driven

---

## 2. First-Time Bootstrap

If a project isn't already bootstrapped with spec-kit, do it at the start of your first spec-driven task for that project.

**Check if bootstrapped:**

```bash
test -f <project-root>/.specify/init-options.json && echo "bootstrapped"
```

**Bootstrap a project:**

Run `specify init` inside the project root with the `pi` integration:

```bash
cd <project-root>
specify init . --integration pi
```

This creates:

- `.specify/` — init config, templates, memory
- `.pi/prompts/` — spec-kit slash command prompt files (`speckit.specify.md`, `speckit.plan.md`, `speckit.tasks.md`, `speckit.implement.md`, etc.)
- `AGENTS.md` context entries with spec-kit markers

**Bootstrap for new projects** (not yet cloned/created): use the normal firstmate clone/create flow first, then bootstrap.

---

## 3. The Spec-Driven Flow

The SDD workflow is executed through spec-kit slash commands. Each `/speckit.*` command is defined by a prompt file under `.pi/prompts/` (for pi integration). These prompt files contain the full instructions, templates, and quality gates for that step.

Since firstmate dispatches crewmates (never works directly in project worktrees), the flow is:

1. Spawn a ship crewmate into the project worktree
2. The crewmate drives the spec-kit commands inside the worktree using the installed prompts:
   - `/speckit.specify` — Create the feature spec (`spec.md`) from a feature description
   - `/speckit.clarify` — (optional) Resolve ambiguities flagged with `[NEEDS CLARIFICATION]` markers
   - `/speckit.plan` — Generate the implementation plan and design artifacts (plan.md, research.md, data-model.md, contracts/, quickstart.md)
   - `/speckit.checklist` — (optional) Generate quality checklists
   - `/speckit.tasks` — Break the plan into executable tasks (`tasks.md`)
   - `/speckit.implement` — Execute the task list and implement the feature
   - `/speckit.converge` — (optional) Verify completeness after implementation

The chain is:

```text
/speckit.specify → /speckit.clarify? → /speckit.plan → /speckit.tasks → /speckit.implement → /speckit.converge?
```

### What firstmate does

Firstmate manages the lifecycle — dispatch, monitor, and coordinate. Each `speckit.*` command is a crewmate task:

1. **Spawning**: Create a worktree for the feature (standard ship task). The crewmate works inside it.
2. **Briefing**: The crewmate's brief tells it to run the full spec-kit chain — `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, then implement via subagents — using the prompts already installed in `.pi/prompts/`.
3. **Steering**: If the crewmate hits `[NEEDS CLARIFICATION]` markers, it surfaces them as `blocked: ...` — relay to the captain, then send the answer back. Otherwise, firstmate only intervenes on `failed` or a terminal stalemate.
4. **Hands-off after tasks**: Once `/speckit.tasks` completes, the crewmate owns the implementation flow internally. No per-command steering needed.

### What the crewmate does

Each crewmate runs the spec-kit command inside the worktree, following the prompt file for that step. The prompt files enforce templates, quality gates, constitution checks, and extension hooks automatically.

After `/speckit.tasks` completes, the crewmate reads `tasks.md` and extracts the phase structure and `[P]` markers. Within each phase, it dispatches all `[P]` tasks as parallel subagents (using the pi-subagents `subagent` PARALLEL mode). Sequential tasks — those without `[P]` or depending on parallel output — use CHAIN mode. After all subagents in a phase complete, it proceeds to the next phase. After all phases, it runs the project's pre-commit gate (`bun run check && bun run build && bun run test`) and reports `done`.

---

## 4. Spec-Driven Flow in Detail

### Step 0: Establish Constitution (one-time per project)

If the project doesn't have `.specify/memory/constitution.md`, the crewmate runs `/speckit.constitution` with the captain's project principles. This creates the constitution from the built-in template.

### Step 1: `/speckit.specify`

The crewmate takes the feature description, creates a spec directory under `specs/<NNN>-<short-name>/`, writes `spec.md` from the template, generates a quality checklist at `checklists/requirements.md`, and validates it.

The spec focuses on **what** and **why** — no implementation details.

### Step 2: `/speckit.clarify` (optional)

If the spec has unresolved `[NEEDS CLARIFICATION]` markers, the crewmate runs this command to prompt the captain for decisions.

### Step 3: `/speckit.plan`

The crewmate reads the spec, loads the constitution, and generates:

- `plan.md` — implementation plan with tech stack, architecture, phases
- `research.md` — research findings (library choices, performance trade-offs)
- `data-model.md` — entities, fields, relationships
- `contracts/` — interface definitions, API contracts
- `quickstart.md` — validation scenarios

### Step 4: `/speckit.tasks`

The crewmate reads `spec.md`, `plan.md`, and any design artifacts, then generates `tasks.md` with dependency-ordered implementation tasks organized by user story phase. Each task has a sequential ID, file path, `[P]` parallel markers, and `[US#]` story labels.

**This step MUST use `/speckit.tasks`** — never write `tasks.md` manually. The command enforces task format, dependency ordering, phase structure, and quality gates.

### Step 5: Implementation (subagent-based dispatch)

After `/speckit.tasks` generates `tasks.md`, the crewmate drives implementation itself by dispatching subagents from the task list. It does **not** run `/speckit.implement` as a monolithic command.

**Dispatch algorithm:**

1. Read `tasks.md` — extract phases, `[P]` markers, file paths, and `[US#]` story labels.
2. For each phase (in order):
   a. Group tasks by `[P]` — all tasks with `[P]` in the same phase are parallelizable.
   b. For `[P]` groups: dispatch one subagent per task in **parallel** (`subagent` PARALLEL mode). Each subagent receives the shared context (spec, plan, data model, contracts) plus its specific task.
   c. For sequential tasks (no `[P]` within a phase): dispatch as **chained** subagents.
3. Wait for all subagents in the current phase to complete before advancing to the next phase.
4. After all phases, run validation: pre-commit gate (typecheck, lint, test).
5. Report `done` with a summary of what was implemented.

**Justification rule for linear execution:** If all tasks in a phase lack `[P]` markers, or the phase has fewer than 3 tasks, the crewmate may use a single linear subagent chain instead. Any other linear execution must be documented as a note in the `done` report.

**Single-file changes** (the common case): The crewmate skips subagent dispatch entirely and implements directly. Only multi-file, multi-module features with genuine `[P]` opportunity trigger subagent fan-out.

### Step 6: `/speckit.converge` (optional)

After implementation, the crewmate can run this to verify completeness against the spec and tasks.

---

## 5. Subagent-Based Parallel Implementation

The default implementation strategy after `/speckit.tasks` is **parallel by default**: the crewmate fans out `[P]` tasks as independent subagents within its own worktree.

**Why subagents, not crewmates:**

- **Single worktree** — subagents share one checkout. No merge conflicts from concurrent edits, no import collisions, no test harness divergence.
- **Shared context** — every subagent inherits the same spec, plan, data model, and contracts without re-reading.
- **Phase order is natural** — the crewmate waits for all subagents in phase N before advancing to phase N+1.
- **Zero firstmate involvement** — the crewmate manages the fan-out internally. Firstmate sees one `done` for the whole implementation, not a flurry of per-task wake events.

**Subagent tool in play:**

The pi-subagents skill provides `subagent` with PARALLEL mode (`{tasks: [{agent, task, ...}], concurrency: <N>}`) and CHAIN mode (`{chain: [{agent, task}, ...]}`). The crewmate uses these directly.

**What the crewmate does:**

1. Load the pi-subagents skill (it's already available as a skill).
2. Determine the best-fit subagent for each task based on the agent definitions listed by `subagent({action: "list"})`.
3. Dispatch `[P]` groups via PARALLEL mode, sequential groups via CHAIN mode.
4. After all phases, run validation and report `done`.

**Edge cases:**

- **Single-file change**: No subagents needed — implement directly.
- **One phase, all `[P]`**: All tasks dispatch in one parallel batch.
- **Mixed `[P]` and sequential within one phase**: `[P]` tasks dispatch in parallel; sequential tasks dispatch as a chain after the parallel group finishes.
- **Subagent fails**: The crewmate reports `failed` with subagent details, same as any other crewmate failure.

---

## 6. Integration with Firstmate Lifecycle

### Complexity judgment at intake

When the captain asks for a feature, load this skill and evaluate:

| Signal | Complex signals | Simple signals |
|--------|----------------|----------------|
| Change type | New feature / enhancement | Bug fix / refactor |
| Files touched | Many | Single / few |
| Domains involved | Multiple | One |
| Ambiguity | Medium / high | Low |
| Captain's description | Vague | Concrete |

If **3+ signals lean complex** → use the full spec-driven flow and tell the captain "I'll spec this out first."
Otherwise → normal ship dispatch with no spec-kit.

### Dispatch pattern

For spec-driven work, the dispatch is:

```text
1. Spawn worktree in project (normal ship task)
2. Brief instructs crewmate to run the full spec-kit chain:
   /speckit.specify → /speckit.plan → /speckit.tasks
   Then implement from tasks.md via subagents (see §5)
3. Firstmate only intervenes for [NEEDS CLARIFICATION] escalations
   or to confirm a done/failed report
4. After implementation is reported done, teardown through
   normal project pipeline
```

### What not to do

- ❌ Do not call `specify feature`, `specify plan`, `specify tasks` etc. — those CLI subcommands do not exist in spec-kit 0.11.x
- ❌ Do not write `tasks.md` manually — always use `/speckit.tasks`
- ❌ Do not write `plan.md` from scratch — always use `/speckit.plan`
- ❌ Do not work directly in the project — dispatch a crewmate per firstmate rules

---

## 7. Key Files and Locations

| Artifact | Path (relative to project root) |
|---|---|
| Constitution | `.specify/memory/constitution.md` |
| Spec | `specs/<NNN>-<name>/spec.md` |
| Plan | `specs/<NNN>-<name>/plan.md` |
| Data model | `specs/<NNN>-<name>/data-model.md` |
| Contracts | `specs/<NNN>-<name>/contracts/` |
| Research | `specs/<NNN>-<name>/research.md` |
| Quickstart | `specs/<NNN>-<name>/quickstart.md` |
| Checklists | `specs/<NNN>-<name>/checklists/` |
| Tasks | `specs/<NNN>-<name>/tasks.md` |
| Agent assignments | `specs/<NNN>-<name>/agent-assignments.yml` |
| Feature dir tracking | `.specify/feature.json` |
| Init options | `.specify/init-options.json` |
| Templates | `.specify/templates/` |
| Spec-kit prompts | `.pi/prompts/speckit.*.md` |

The prompts themselves are the authoritative source for each command's behavior. If a question arises about what a command does, read the corresponding `.pi/prompts/speckit.<command>.md` file.
