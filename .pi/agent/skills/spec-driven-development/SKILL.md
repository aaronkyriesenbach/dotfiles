---
name: spec-driven-development
description: Uses spec driven development using Github's spec-kit
---

# Spec-Driven Development Skill

Integrates spec-kit (GitHub's Spec-Driven Development toolkit) into any agent's workflow to implement complete features.

**Key fact**: spec-kit commands are slash commands installed in the project's `.pi/prompts/` or `.claude/skills/` directory by `specify init --integration <agent>`. The `specify` CLI itself is only a bootstrap and extension management tool — it has no `feature`, `plan`, `tasks`, `specify`, or `implement` subcommands. All SDD workflow commands exist as agent prompt files.

**How this skill works**: The agent that invokes this skill executes the spec-kit pipeline directly — interacting with the user for specification, running the spec-kit commands, and dispatching subagents only for parallel implementation tasks. This is not a "dispatch and forget" skill; the agent owns the entire lifecycle.

---

## 1. When to Use Spec-Driven vs. Skip to Implementation

The rule: **you decide based on complexity.** A small, well-defined change skips spec-kit entirely and goes straight to implementation.

### Use spec-driven when the change involves

- Multiple files, modules, or layers (e.g. backend + frontend + DB)
- New feature with multiple user stories
- Ambiguous requirements that benefit from explicit specification
- Cross-domain work (separate frontend/backend concerns)
- Something the user explicitly flags as "spec this out"

### Skip spec-kit when the change is

- A single-file bug fix
- A trivial addition to an existing function
- A well-understood, scoped change the user describes concretely
- Something the user says is small/obvious

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

**If the project doesn't exist yet**: clone or create it first using your normal flow, then bootstrap.

---

## 3. The Spec-Driven Flow

The SDD workflow is executed through spec-kit slash commands. Each `/speckit.*` command is defined by a prompt file under `.pi/prompts/` (for pi integration). These prompt files contain the full instructions, templates, and quality gates for that step.

The flow is **interactive during specification** and **autonomous during planning/implementation**:

```text
[User Input] → /speckit.specify → [User Reviews Spec] → /speckit.clarify ↺
                                        ↓ (approved)
                                    /speckit.plan → /speckit.tasks → Implement via subagents → /speckit.converge?
```

### Interactive Specification Loop (User-In-The-Loop)

Unlike the fully-automated plan/tasks/implement phases, the specification phase involves the user directly:

1. **Prompt the user** for a description of what they want to build
2. **Run `/speckit.specify`** with the user's description to generate the feature spec (`spec.md`)
3. **Present the generated spec** to the user for review — show its key sections, acceptance criteria, and any `[NEEDS CLARIFICATION]` markers
4. **Ask the user** if they have any clarifications, changes, or questions about the spec
5. **If the user has input**: run `/speckit.clarify` with the user's clarifications, then return to step 3
6. **If the user approves** (gives the go-ahead to proceed): move on to planning/implementation

> **Key principle**: The user stays in control of the "what" (spec). Once the spec is settled, the "how" (plan/tasks/implement) runs autonomously by default.

### Autonomous Execution (Plan → Tasks → Implement)

Once the user gives the go-ahead, the remaining phases run without per-step user intervention:

- `/speckit.plan` — Generate the implementation plan and design artifacts
- `/speckit.tasks` — Break the plan into executable tasks
- Implementation via subagents (§5)
- `/speckit.converge` — (optional) Verify completeness

### What the agent does

The agent manages the entire lifecycle — interacting with the user for specification, then running the spec-kit commands and dispatching subagents for implementation.

1. **Specification phase**: Work directly in the project directory (no worktree needed). Prompt the user, run `/speckit.specify`, present results, run `/speckit.clarify` as needed. Loop until the user approves.
2. **Planning phase**: Run `/speckit.plan` to generate the implementation plan and design artifacts.
3. **Tasks phase**: Run `/speckit.tasks` to break the plan into executable tasks with dependency ordering.
4. **Implementation phase**: Read `tasks.md`, dispatch subagents for parallel `[P]` tasks, implement sequential tasks directly. See §5 for the full dispatch algorithm.
5. **Validation**: Run typecheck/lint/test. Report `done` with a summary.
6. **Steering**: The agent only intervenes on `failed` or a terminal stalemate. No per-command steering needed after the user approves the spec.

---

## 4. Spec-Driven Flow in Detail

### Step 0: Establish Constitution (one-time per project)

If the project doesn't have `.specify/memory/constitution.md`, run `/speckit.constitution` with the project's principles (gather from the user if needed). This creates the constitution from the built-in template.

> **Constitution first**: Run this check before starting the interactive spec loop. If it doesn't exist, ask the user for project principles, then run `/speckit.constitution`.

### Step 1: `/speckit.specify` (Interactive)

This step runs **directly with the user**.

1. **Prompt the user** for a description of what they want to build. Use `ask_user_question` to gather their feature description if they haven't already provided one.
2. **Run `/speckit.specify`** inside the project root with the user's description. This creates:
   - `specs/<NNN>-<short-name>/spec.md` — the feature specification
   - `specs/<NNN>-<short-name>/checklists/requirements.md` — quality checklist
3. The spec focuses on **what** and **why** — no implementation details.
4. **Present the generated spec** to the user. Read `spec.md` and summarize its key sections: goals, acceptance criteria, scope, user stories, and any `[NEEDS CLARIFICATION]` markers.

### Step 2: `/speckit.clarify` (Interactive Loop)

After presenting the spec, enter the clarifications loop:

1. **Ask the user**: "Do you have any clarifications, changes, or questions about this spec?" Provide the key points from the spec as context.
2. **If the user provides clarifications**:
   - Run `/speckit.clarify` with the user's feedback
   - Re-read the updated `spec.md`
   - Present the updated spec to the user
   - Return to step 1 of this loop
3. **If the user says the spec looks good** or gives an explicit go-ahead to proceed:
   - Exit the clarify loop
   - Move to Step 3 (`/speckit.plan`)

> **Loop mechanics**: Each iteration of `/speckit.clarify` refines the spec. The user may go through 1-3 cycles on average. The loop always ends with the user's explicit approval — never assume approval from silence.

### Step 3: `/speckit.plan`

Read the spec, load the constitution, and run `/speckit.plan`. This generates:

- `plan.md` — implementation plan with tech stack, architecture, phases
- `research.md` — research findings (library choices, performance trade-offs)
- `data-model.md` — entities, fields, relationships
- `contracts/` — interface definitions, API contracts
- `quickstart.md` — validation scenarios

> **Important**: Always use `/speckit.plan` — never write `plan.md` manually.

### Step 4: `/speckit.tasks`

Read `spec.md`, `plan.md`, and any design artifacts, then run `/speckit.tasks`. This generates `tasks.md` with dependency-ordered implementation tasks organized by user story phase. Each task has a sequential ID, file path, `[P]` parallel markers, and `[US#]` story labels.

> **Important**: Always use `/speckit.tasks` — never write `tasks.md` manually. The command enforces task format, dependency ordering, phase structure, and quality gates.

### Step 5: Implementation (subagent-based dispatch)

After `/speckit.tasks` generates `tasks.md`, drive implementation by dispatching subagents from the task list.

**Dispatch algorithm:**

1. Read `tasks.md` — extract phases, `[P]` markers, file paths, and `[US#]` story labels.
2. For each phase (in order):
   a. Group tasks by `[P]` — all tasks with `[P]` in the same phase are parallelizable.
   b. For `[P]` groups: dispatch one subagent per task in **parallel** using the subagent PARALLEL mode. Each subagent receives the shared context (spec, plan, data model, contracts) plus its specific task.
   c. For sequential tasks (no `[P]` within a phase): dispatch as **chained** subagents, or implement them directly if they are simple.
3. Wait for all subagents in the current phase to complete before advancing to the next phase.
4. After all phases, run validation: typecheck, lint, test.
5. Report `done` with a summary of what was implemented.

**Justification rule for linear execution:** If all tasks in a phase lack `[P]` markers, or the phase has fewer than 3 tasks, implement directly or use a single linear subagent chain instead. Any other linear execution must be documented as a note in the `done` report.

**Single-file changes** (the common case): Skip subagent dispatch entirely and implement directly. Only multi-file, multi-module features with genuine `[P]` opportunity trigger subagent fan-out.

### Step 6: `/speckit.converge` (optional)

After implementation, run this to verify completeness against the spec and tasks.

---

## 5. Subagent-Based Parallel Implementation

The default implementation strategy after `/speckit.tasks` is **parallel by default**: fan out `[P]` tasks as independent subagents within the same working directory.

**Why subagents:**

- **Single working directory** — subagents share one checkout. No merge conflicts from concurrent edits, no import collisions, no test harness divergence.
- **Shared context** — every subagent inherits the same spec, plan, data model, and contracts without re-reading.
- **Phase order is natural** — wait for all subagents in phase N before advancing to phase N+1.

**Subagent tool:**

The pi-subagents skill provides `subagent` with PARALLEL mode (`{tasks: [{agent, task, ...}], concurrency: <N>}`) and CHAIN mode (`{chain: [{agent, task}, ...]}`).

**What the agent does:**

1. Load the pi-subagents skill (it's already available as a skill).
2. Determine the best-fit subagent for each task based on the agent definitions listed by `subagent({action: "list"})`.
3. Dispatch `[P]` groups via PARALLEL mode, sequential groups via CHAIN mode or implement directly.
4. After all phases, run validation and report `done`.

**Edge cases:**

- **Single-file change**: No subagents needed — implement directly.
- **One phase, all `[P]`**: All tasks dispatch in one parallel batch.
- **Mixed `[P]` and sequential within one phase**: `[P]` tasks dispatch in parallel; sequential tasks dispatch as a chain after the parallel group finishes, or are implemented directly.
- **Subagent fails**: Report `failed` with subagent details.

---

## 6. Complexity Judgment at Intake

When a user asks for a feature, load this skill and evaluate:

| Signal | Complex signals | Simple signals |
|--------|----------------|----------------|
| Change type | New feature / enhancement | Bug fix / refactor |
| Files touched | Many | Single / few |
| Domains involved | Multiple | One |
| Ambiguity | Medium / high | Low |
| User's description | Vague | Concrete |

If **3+ signals lean complex** → use the full spec-driven flow and tell the user "I'll spec this out first."
Otherwise → skip spec-kit and implement directly.

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
