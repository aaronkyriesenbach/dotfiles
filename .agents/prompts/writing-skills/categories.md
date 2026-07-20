# Skill Categories

The Anthropic Claude Code team identified 9 categories that skills fall into. A well-scoped skill cleanly fits one; skills that straddle several tend to confuse the agent.

## 1. Library and API Reference

Explain how to correctly use a library, CLI, or SDK. Often include reference code snippets and gotchas.

**Examples**: `billing-lib` (internal library edge cases), `internal-platform-cli` (subcommand reference), `sandbox-proxy` (egress gateway configuration).

**Key elements**: Function/API reference, common patterns, gotchas, when to use which approach.

## 2. Product Verification

Describe how to test or verify that code works. Often paired with Playwright, tmux, or other verification tools.

**Examples**: `signup-flow-driver` (headless browser test + state assertions), `checkout-verifier` (UI checkout + Stripe test cards + invoice verification), `tmux-cli-driver` (interactive CLI testing).

**Key elements**: Test commands, assertion patterns, verification scripts, expected outputs.

## 3. Data Fetching and Analysis

Connect to data and monitoring stacks. Include credentials guidance, dashboard IDs, common queries.

**Examples**: `funnel-query` (event join path), `cohort-compare` (retention analysis), `grafana` (datasource UIDs, dashboard lookup), `datadog` (field reference, service list).

**Key elements**: Query patterns, data source locations, field mappings, aggregation methods.

## 4. Business Process and Team Automation

Automate repetitive workflows into one command. Often depend on other skills or MCP servers.

**Examples**: `standup-post` (jira + GitHub + Slack → formatted standup), `create-ticket` (schema enforcement + post-creation workflow), `weekly-recap` (merged PRs + closed tickets + deploys → recap post).

**Key elements**: Workflow steps, input sources, output format, dependencies on other skills.

## 5. Code Scaffolding and Templates

Generate framework boilerplate for a specific codebase pattern.

**Examples**: `new-workflow` (scaffold service/handler with org annotations), `new-migration` (migration template + gotchas), `create-app` (new internal app with auth, logging, deploy config).

**Key elements**: Template files, code patterns, configuration defaults, build commands.

## 6. Code Quality and Review

Enforce code quality standards. Often include deterministic scripts or tools.

**Examples**: `adversarial-review` (fresh subagent critique → fix → iterate), `code-style` (convention enforcement), `testing-practices` (how to write tests and what to test).

**Key elements**: Lint rules, review checklists, style examples, testing conventions.

## 7. CI/CD and Deployment

Fetch, push, and deploy code. May reference other skills.

**Examples**: `babysit-pr` (monitor PR → retry CI → resolve conflicts → auto-merge), `deploy-service` (build → smoke test → gradual rollout), `cherry-pick-prod` (worktree → cherry-pick → PR).

**Key elements**: Deploy commands, rollback procedures, monitoring dashboards, approval gates.

## 8. Runbooks

Take a symptom (alert, error, thread) → multi-tool investigation → structured report.

**Examples**: `service-debugging` (symptom → tool → query mapping), `oncall-runner` (alert → usual suspects → finding), `log-correlator` (request ID → matching logs across systems).

**Key elements**: Diagnostic flowcharts, tool references, query templates, report format.

## 9. Infrastructure Operations

Routine maintenance and operational procedures, some destructive.

**Examples**: `orphans-cleanup` (find orphaned resources → Slack → soak → cleanup), `dependency-management` (approval workflow), `cost-investigation` (spike → buckets → query patterns).

**Key elements**: Safety gates, approval workflows, dry-run commands, rollback procedures.
