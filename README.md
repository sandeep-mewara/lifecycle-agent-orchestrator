# Lifecycle Agent Orchestrator (LAO)

LAO, a **multi-agent orchestrator** is a **Claude Code & Cursor Plugin** - a portable, project-agnostic AI-powered product development lifecycle engine that uses **multiple agents** to orchestrates end-to-end workflows, driving requirements through to pull requests with cross-role review gates, structured checkpoints and built-in TDD workflows across phases such as technical design and automated testing, all **powered by advanced AI coding skills**. 

> **Note:** This plugin works in both [Claude Code](https://claude.ai/code) and
> [Cursor](https://cursor.com). All `/plugin` and `/lao` commands
> are typed inside the respective AI coding session, not in a regular terminal.
> The primary orchestrator command is `/lao`; `/lifecycle-agent-orchestrator` is the
> canonical full name and behaves the same way.

This **multi-agent orchestration** is done via 10 skills, one each for a role where each role is a distinct agent persona (PM, Architect, Designer, etc.) invoked by the orchestrator agent at the right phase.

## ✨ What This Is

A **multi-agent orchestrator** that coordinates 9 development phases:

```
Product Management → Experience Design → Architecture (System Design)
  → per ticket: Intake → Tech Design → Plan → Implement → Validate → Ship
```

Leveraging **multiple agents**, all cross-reviews (PM, XD, Architecture) happen in Phases 1-3 before any ticket work starts.
Phase 2 is conditional — skipped for backend-only requirements. The per-ticket loop
(Phases 4-9) is pure execution with no additional cross-review gates.

Each phase has a **base skill** with universal rules. Projects add **overlay files** for
project-specific conventions. The orchestrator invokes the right skill at the right time,
enforces cross-role review gates, and presents structured checkpoints for human approval.

**Preview-then-Execute:** The orchestrator always starts with a preview — simulating the
full pipeline without making any real changes. You iterate on scope, design, and plan
during preview, then say "proceed" to execute. All decisions carry forward, so preview
costs no extra tokens. Human approval checkpoints remain active during execution.


## Value Proposition - Impact Transformation: Manual to Orchestrated

| Area | FROM (Current State) | TO (Orchestrated Plugin) | Impact |
| :--- | :--- | :--- | :--- |
| **Requirements** | Manual PRD/Jira creation. High risk of missing Acceptance Criteria (AC). | AI-driven generation with automated **PM/XD/Arch cross-review**. | **3x faster intake**; 100% AC traceability. |
| **Handoffs** | "Throwing it over the fence." Tech feasibility issues found late in coding. | Automated **Cross-Review Gates** at every handoff phase. | **Eliminates rework** by catching gaps before coding starts. |
| **Context** | Engineers manually context-switch between Figma, Jira, and the IDE. | **Unified Context.** Plugin ingests all artifacts into a single workspace. | **Higher flow state**; full visibility into the "Why" behind the code. |
| **Reviews** | Code reviews focus on syntax; manual verification of requirements. | **Spec-Compliance Review.** AI validates code against Tech Design and ACs. | **Superior Quality.** PRs solve the business problem, not just the ticket. |
| **Portability** | Every project reinvents its development lifecycle, scripts, and conventions. | **Portable Skill Engine.** Base rules are universal; local rules live in **Overlays**. | **Plug-and-play.** Standardized lifecycle workflows across any project in minutes. |
| **Verification** | Disconnected testing. "It works on my machine." | **Automated Validation.** Every AC is proven via recorded evidence. | **Ship with Confidence.** PRs include an automated Acceptance Report. |


## Quickstart (5 minutes)

**1. Install** (inside a Claude Code or Cursor session):

```
/plugin marketplace add sandeep-mewara/lifecycle-agent-orchestrator
/plugin install lifecycle-agent-orchestrator@lifecycle-agent-orchestrator
```

**2. Try the dry run** — simulates the full 9-phase pipeline on a sample requirement with no real changes:

```
/lao-dry-run
```

Watch the orchestrator walk through Product Management → Experience Design → Architecture → Intake → Tech Design → Plan → Implement → Validate → Ship — all simulated. This validates the plugin is installed and working.

**3. Set up your project** — scan your repo and connect existing docs:

```
/lao-setup
```

The setup wizard detects your project's languages, finds architecture docs, coding standards, and domain knowledge, then helps you map them as overlays. You can choose config-based (`lao.config.yaml`) or convention-based (`skills/` directory) setup.

**4. Run the pipeline** — give it a requirement or Jira ticket:

```
/lao
```

The orchestrator starts in **preview mode** (no real changes). You iterate on scope, design, and plan, then say "proceed" to execute. Human approval checkpoints remain active throughout.

---

## Prerequisites

Use this checklist so the orchestrator has everything it composes at runtime:

1. [Claude Code CLI](https://claude.ai/code) **or** [Cursor](https://cursor.com) installed
2. This marketplace installed via [Installation](#installation) below (choose one option and verify with `/plugin list`)

## Installation

This repo is structured as a plugin marketplace. Both Claude Code and Cursor
use the same shared skill files — no content duplication.

### Claude Code

### Which option should I use?

| Where the Git remote lives | Recommended |
| --- | --- |
| **github.com** | Option A works if the shorthand `owner/repo` resolves for you; Options B and C always work |

If your Git remote is not on **github.com**, use Option B or Option C (local clone or `git` / `directory` source in `settings.json`).

Substitute your real clone URL everywhere you see `<YOUR_REPO_GIT_URL>` below. Example (use this as default if no other alternative):

- Public GitHub: `https://github.com/sandeep-mewara/lifecycle-orchestrator.git`

### Option A: `/plugin` Command (github.com repos)

All `/plugin` commands are typed **inside a Claude Code session** (start one with
`claude` in your terminal).

The example below assumes the marketplace repo is at **github.com** as `sandeep-mewara/lifecycle-orchestrator`. If you use a fork or different org, replace `sandeep-mewara/lifecycle-orchestrator` with your `owner/repo` on github.com.

```
/plugin marketplace add sandeep-mewara/lifecycle-orchestrator
/plugin install lifecycle-agent-orchestrator@lifecycle-agent-orchestrator
```

If shorthand install does not resolve your repo, use Option B or C below.

### Option B: `/plugin` with Local Clone (any Git host)

Clone the repo first, then add it as a local marketplace inside Claude Code:

```bash
git clone <YOUR_REPO_GIT_URL> /path/to/lifecycle-agent-orchestrator
```

Then inside Claude Code:
```
/plugin marketplace add /path/to/lifecycle-agent-orchestrator
/plugin install lifecycle-agent-orchestrator@lifecycle-agent-orchestrator
```

### Option C: Manual Install via settings.json (no `/plugin` needed)

If the `/plugin` command is unavailable, doesn't resolve your repo, or the marketplace
isn't registered — you can configure everything directly in `settings.json`.

**1. Clone the repo:**
```bash
git clone <YOUR_REPO_GIT_URL> /path/to/lifecycle-agent-orchestrator
```

**2. Edit `~/.claude/settings.json`** (user-level) or `.claude/settings.json` (project-level):
```json
{
  "extraKnownMarketplaces": {
    "lifecycle-agent-orchestrator": {
      "source": {
        "source": "directory",
        "path": "/path/to/lifecycle-agent-orchestrator"
      }
    }
  },
  "enabledPlugins": {
    "lifecycle-agent-orchestrator@lifecycle-agent-orchestrator": true
  }
}
```

> If your repo is on a Git host accessible via HTTPS/SSH and you don't want a local
> clone, use the `"git"` source type instead (same URL you would use for `git clone`):
> ```json
> "source": {
>   "source": "git",
>   "url": "<YOUR_REPO_GIT_URL>"
> }
> ```

**3. Reload:** Run `/reload-plugins` inside Claude Code, or restart the session.

### Private repositories

For a **private** repo on github.com, `/plugin marketplace add owner/repo` only works if the machine running Claude Code can fetch that repo (SSH agent, HTTPS credential helper, or `gh auth` as appropriate for your setup). If shorthand install fails or you prefer not to rely on it, use **Option B** (local clone after `git clone`) or **Option C** with a `"git"` source using an SSH URL (`git@github.com:owner/lifecycle-agent-orchestrator.git`) or HTTPS with credentials your environment already provides.

### Cursor

This plugin also works in [Cursor](https://cursor.com). The skills are shared —
no separate content to maintain.

**Option A: Cursor Plugin Manager (GitHub)**

```
/plugin marketplace add sandeep-mewara/lifecycle-orchestrator
/plugin install lifecycle-agent-orchestrator@lifecycle-agent-orchestrator
```

**Option B: Manual Install via Cursor Settings**

Clone the repo, then add to Cursor settings (Settings > Plugins):

```json
{
  "extraKnownMarketplaces": {
    "lifecycle-agent-orchestrator": {
      "source": { "source": "directory", "path": "/path/to/lifecycle-agent-orchestrator" }
    }
  },
  "enabledPlugins": {
    "lifecycle-agent-orchestrator@lifecycle-agent-orchestrator": true
  }
}
```

Restart Cursor after installing.

### Verify and Test

After installing via any method (Claude Code or Cursor):

```
/plugin list
```

You should see `lifecycle-agent-orchestrator` listed and enabled. Then run a dry-run:

```
/lao-dry-run
```

This simulates the full 9-phase lifecycle pipeline against a bundled sample requirement
without making any real changes (no files, no git, no Jira, no PRs). You can also
provide a custom requirement:

```
/lao-dry-run Add a user notification preferences API endpoint
```

### Optional: Structural Validation

From a regular terminal, run the validation scripts:

**Validate the plugin itself:**
```bash
./plugins/lifecycle-agent-orchestrator/scripts/validate-plugin.sh
```

Runs 91 structural checks — manifest, skills, frontmatter, references, contracts,
examples, and documentation.

**Validate your project's overlays, domain files, and extra roles:**
```bash
./plugins/lifecycle-agent-orchestrator/scripts/validate-project-skills.sh skills/
```

Checks overlay directory names against known base roles, validates frontmatter on
extra roles and domain files, verifies `applies_to` values, and warns on common
mistakes (misnamed overlays, empty directories, non-`.md` files in `domain/`).

**Validate a config-based project:**
```bash
./plugins/lifecycle-agent-orchestrator/scripts/validate-project-skills.sh --config lao.config.yaml
```

Parses the config file, verifies all mapped paths exist, checks overlay keys match
base roles, validates frontmatter on domain and extra role files, and expands globs.

**Scan a project for potential skill files:**
```bash
./plugins/lifecycle-agent-orchestrator/scripts/validate-project-skills.sh --scan /path/to/project/
```

Scans the project for markdown files that look like overlays or domain context and
suggests how to connect them.

**Cross-reference consistency check:**
```bash
./plugins/lifecycle-agent-orchestrator/scripts/check-consistency.sh
```

Verifies that skill counts, names, role lists, and manifest names stay in sync
across the README, validation scripts, and orchestrator SKILL.md.

**Run test suite** (requires [bats-core](https://github.com/bats-core/bats-core): `brew install bats-core`):
```bash
bats plugins/lifecycle-agent-orchestrator/tests/
```

21 tests covering both validation scripts with fixture-based scenarios (valid
project, misnamed overlays, missing frontmatter, invalid `applies_to`, etc.).

## Quick Start

### 0. Set Up Project Skills (Recommended)

Run the interactive setup to connect your project's existing docs to the orchestrator:

```
/lao-setup
```

This scans your project for architecture docs, coding standards, domain knowledge, and
other skill-like files, then helps you choose between config-based mapping
(`lao.config.yaml`) or convention-based directory structure. It generates the chosen
structure and validates it.

> **Tip:** You can skip this step — the orchestrator works with base skills alone. If you
> jump straight to `/lao`, it will detect that no project skills are
> connected, show any potential files it finds, and suggest running
> `/lao-setup`.

### 1. Use the Orchestrator

```bash
# Full lifecycle pipeline from a Jira ticket
/lao Work on PROJ-1234

# Full lifecycle pipeline from a raw requirement
/lao Add a user notification preferences API endpoint

# Full lifecycle pipeline from a PRD
/lao Here's the PRD, tickets already exist: ...
```

Or just describe what you want — Claude auto-invokes the orchestrator when it detects
lifecycle-relevant intent (e.g., "implement this requirement", "build this feature",
"take this to PR").

**What happens:** The orchestrator starts with a **preview** — simulating each phase
and presenting checkpoints without making any real changes. You review scope, design,
and plan. Once satisfied, say "proceed with implementation" and the real execution
begins, carrying forward all preview decisions. Human approvals remain active during
execution.

### 2. Use Individual Skills Directly

Every lifecycle skill is also independently invocable:

```bash
# Standalone architecture review
Invoke architecture skill to review this PR for architectural alignment

# Standalone code review
Invoke code-review skill to review these changes

# Standalone intake
Invoke intake skill to extract scope from PROJ-5678
```

### 3. Create Project Skills (Optional)

Two ways to connect project-specific skills to the orchestrator:

**Option A: Config file** — create `lao.config.yaml` at your project root
and map paths to your existing files. Best for projects with established
directory structures. See [Configuration](#configuration) below.

**Option B: Convention** — create files directly in `skills/` following the
directory convention below. Best for new projects or teams starting fresh.

If `lao.config.yaml` exists, it takes precedence and the convention directory
is not scanned.

#### Convention directory layout

```
your-project/
└── skills/
    ├── architecture/PROJECT.md        # Overlay on base architecture skill
    ├── coding-standards/PROJECT.md    # Overlay on base coding-standards skill
    ├── testing-conventions/PROJECT.md # Overlay on base testing-conventions skill
    ├── code-review/PROJECT.md         # Overlay on base code-review skill
    ├── shipping/PROJECT.md            # Overlay on base shipping skill
    ├── compliance-review/SKILL.md     # Extra project role (standalone)
    └── domain/                        # Cross-cutting domain context
        ├── auth-system.md
        └── data-model.md
```

- `<role>/PROJECT.md` — overlay on a base skill (project rules take precedence on conflict)
- `<role>/SKILL.md` — standalone project-defined role (no corresponding base skill)
- `domain/<topic>.md` — domain knowledge injected across phases based on frontmatter

Only create files for roles and domains that need project-specific additions. If no
overlay exists, the base skill operates standalone.

## Configuration

### `lao.config.yaml`

An optional config file at your project root that maps existing project files to
orchestrator roles. Use this when your project already has architecture docs, coding
guidelines, or domain knowledge and you don't want to move or duplicate them.

```yaml
# Required — used in manifest presentation and logging
project_name: my-app

# Optional — project languages (python, java, csharp, react). Omit for auto-detection.
# List format for multi-language projects:
languages:
  - python
  - react
# Or single string (backward compatible): language: python

# Overlays — map base role names to your existing files
# Keys must match base role directory names (architecture, coding-standards, etc.)
overlays:
  architecture: docs/architecture/standards.md
  coding-standards: .cursor/rules/coding.md
  code-review: docs/review-checklist.md

# Domain context — list of paths or glob patterns
# Each file must have YAML frontmatter (name, description, applies_to)
domain:
  - docs/domain/*.md
  - src/payments/DESIGN.md

# Extra roles — project-specific roles not in the base plugin
# Keys must NOT match base role names
# Each file must have YAML frontmatter (name, description, applies_to)
extra_roles:
  compliance-review: tools/compliance/SKILL.md
```

**Rules:**

- All paths are relative to the project root (where `lao.config.yaml` lives)
- Only `project_name` is required; all other sections are optional
- Glob patterns (e.g., `docs/domain/*.md`) are expanded at pipeline start
- Globs and explicit paths can be mixed in the `domain` list
- Overlay keys must match a base role name (`architecture`, `coding-standards`, etc.)
- Extra role keys must NOT match a base role name
- Extra role files must include `applies_to` in frontmatter (warns if missing)

### When to use config vs convention

| Situation | Recommended |
| --- | --- |
| New project, starting fresh | Convention — zero config, just create the directories |
| Existing project with established docs | Config — map your existing files, no restructuring |
| Monorepo with multiple services | Config per service root — each has its own `lao.config.yaml` |
| Domain knowledge scattered across the project | Config — explicit paths or globs reach any location |
| Simple project, few overlays | Either works — convention is slightly less ceremony |

### Suggestion scan

At pipeline start, the orchestrator also scans the project for markdown files that
look like potential skill content but aren't connected (by filename patterns and
frontmatter presence). If found, it suggests adding them to `lao.config.yaml` or
moving them to the convention directory. This helps teams discover what they already
have.

## Project Skill Conventions

### Role Overlays

#### Directory Structure

```
<project-root>/skills/<role>/PROJECT.md
```

Where `<role>` matches a directory name in `plugins/lifecycle-agent-orchestrator/skills/`. All base
roles support overlays:
- `product-management`
- `intake`
- `experience-design`
- `architecture`
- `coding-standards`
- `testing-conventions`
- `code-review`
- `security`
- `acceptance-validation`
- `shipping`

#### Overlay Precedence

The project overlay is the domain authority. On conflict, the overlay wins.

- **Additive:** project patterns, tools, frameworks — applied alongside the base.
- **Narrowing:** stricter rules (e.g., stricter linting) — the stricter version applies.
- **Contradicting:** if the overlay relaxes or reverses a base rule, the overlay wins.
  Add an `## Overrides` section with a rationale so the orchestrator can surface it at
  the checkpoint. The override applies regardless, but the rationale helps the human
  understand why.

#### What Goes in an Overlay

**DO include:**
- Project-specific frameworks, libraries, and patterns
- Project-specific security requirements
- Project-specific test infrastructure
- Project-specific CI/CD and deployment targets
- Project-specific design system references
- Overrides of base rules that don't apply to this project (with rationale)

**DO NOT include:**
- Rules that duplicate the base skill (they're already applied)
- General best practices (those belong in the base)

#### Example Overlay

```markdown
# Architecture — My Project Overlay

## Project Stack
- FastAPI + LangGraph for agent orchestration
- Redis for session state
- LLM proxy gateway

## Project-Specific Patterns
- Order workflows use reads/writes fields for automatic dependency resolution
- Agent tools extend BaseTool, access context via config["configurable"]["agent_context"]
- Auth headers passed via extra_headers on every LLM call (IAM, not API key)

## Additional Security Requirements
- Transaction data subject to audit — design for traceability
- Secrets manager for all secrets management

## Overrides

### Bare exceptions in CLI scripts
**Base rule:** Never bare `raise Exception(...)`.
**Override:** CLI entry-point scripts in `scripts/` use bare exceptions for
quick-fail behavior. This does not apply to library or service code.
```

### Extra Project Roles

Projects may define roles beyond the base skills. These are standalone skills
(not overlays on a base) placed at:

```
<project-root>/skills/<role-name>/SKILL.md
```

Use `SKILL.md` (not `PROJECT.md`) to signal that this is a standalone role.
Extra roles use YAML frontmatter with `name`, `description`, and `applies_to`:

```yaml
---
name: compliance-review
description: SOC2 compliance checks and audit trail verification
applies_to: [architecture, code-review, security]
---
```

- `applies_to: all` — eligible for every phase.
- `applies_to: [role1, role2, ...]` — eligible only when the current phase
  uses one of the listed roles. Values match base role directory names.
- **Missing `applies_to`** — the role is **not loaded at any phase**. The
  manifest will warn:

```
⚠ Extra role "compliance-review" has no applies_to — it will not be loaded.
  Add applies_to frontmatter to specify when it should be active.
```

Extra roles function as **additional context** during a phase, not as separate
pipeline steps. When a phase runs, the orchestrator loads any extra role whose
`applies_to` matches the current phase's base role and injects it alongside the
base skill, overlay, and domain context.

**When to create an extra role:** when your project has a concern that no base skill
covers (e.g., `compliance-review`, `accessibility-audit`, `performance-budget`).

### Domain Context (Cross-Cutting)

Domain files provide project-specific knowledge that spans multiple lifecycle phases:

```
<project-root>/skills/domain/<topic>.md
```

Each domain file has YAML frontmatter:

```yaml
---
name: auth-system
description: Authentication patterns, session handling, and IAM integration
applies_to: all
---
```

- `applies_to: all` — eligible for every phase. This is the default when omitted.
- `applies_to: [role1, role2, ...]` — eligible only when the current phase uses
  one of the listed roles. Values match directory names under `skills/`.

The orchestrator uses **two-tier loading** to keep context efficient:

1. **Index tier** — at pipeline start, reads only the frontmatter of every file in
   `domain/`. This lightweight catalog persists for the full run.
2. **Load tier** — at each phase, hard-filters by `applies_to`, then checks the
   `description` for relevance to the current task. Only files that pass both
   checks are loaded in full.

#### What Goes in a Domain File

**DO include:**
- Core domain concepts the team assumes everyone knows
- Key architectural constraints from the business domain
- Patterns, naming conventions, and terminology specific to this domain
- Compliance or regulatory constraints that affect multiple phases
- Integration patterns with external systems

**DO NOT include:**
- Full API documentation (link to it, summarize the constraints)
- Content that belongs in a role overlay (if it only affects one phase, make it an overlay)
- Frequently changing information (domain files should be stable reference material)

Keep domain files concise — 50-200 lines of constraints, patterns, and decisions.
For extensive documentation, summarize the key points and link to the full source.

#### Example Domain File

```markdown
---
name: payment-processing
description: PCI constraints, transaction patterns, and payment gateway conventions
applies_to: [architecture, coding-standards, code-review, acceptance-validation]
---

# Payment Processing Domain

## PCI Compliance Constraints
- Card numbers never stored; tokenized via Stripe
- All payment endpoints require TLS 1.2+
- Audit logging mandatory on every transaction state change

## Transaction Patterns
- Idempotency keys required on all write operations
- Two-phase: authorize then capture, never direct charge
- Refunds always async via webhook confirmation
```

## Phase Output Contract

Every phase produces a structured `PhaseOutput` object documented in
`contracts/phase-output-schema.md`. This contract enables:

- **CLI rendering** — formatted text in the terminal (current)
- **Future UI dashboard** — pipeline view with status indicators, approval buttons,
  and acceptance criteria tracking

The UI is purely a rendering layer that consumes the same PhaseOutput objects.
See `contracts/phase-output-schema.md` for the full schema and rendering format.

## Cross-Role Review Gates

Three phases have cross-review gates where other roles verify the output:

| Phase Output | Reviewed By | Focus |
|---|---|---|
| PRD (Phase 1) | XD + Architecture | UX feasibility, tech feasibility |
| XD Artifacts (Phase 2) | PM + Architecture | Requirements coverage, tech feasibility |
| System Design (Phase 3) | PM + XD (if applicable) | Requirements coverage, UX support |

Maximum 2 revision rounds per gate. If unresolved, escalates to human.

## Preview-Then-Execute Model

The orchestrator uses a two-phase approach for every run:

```
/lao Add a notification preferences API
        │
        ▼
  PREVIEW (no real changes)
    → Phases 1-6 simulated with full checkpoints
    → User reviews scope, ACs, design, cross-reviews, plan
    → User can adjust any phase output or iterate
    → Phases 7-9 shown as projected outcomes
        │
        ▼
  "Preview complete. Proceed with implementation?"
    → "Proceed" — start real execution
    → "Adjust [phase]" — revisit a phase in preview
    → "Abort" — stop, nothing was changed
        │
        ▼
  EXECUTE (real changes, context carried forward)
    → Phases 1-6 use preview decisions (no regeneration)
    → Phases 7-9 run fresh (actual code, tests, PR)
    → Human approvals active at every phase
```

**Benefits:**
- Iterate on scope and design with zero risk (nothing real happens during preview)
- Catch misalignment before any code is written
- Same token cost — preview thinking carries into execution, not duplicated
- Human stays in control during both preview and execution

**Standalone dry run:** Use `/lao-dry-run` for demos, plugin validation,
or testing overlays without any intent to execute.

## Package Contents

```
lifecycle-orchestrator/                    # Marketplace root (this repo)
├── .claude-plugin/
│   └── marketplace.json                   # Claude Code marketplace manifest
├── .cursor-plugin/
│   └── marketplace.json                   # Cursor marketplace manifest
├── plugins/
│   └── lifecycle-agent-orchestrator/      # The plugin
│       ├── .claude-plugin/
│       │   └── plugin.json                # Plugin manifest for Claude Code
│       ├── .cursor-plugin/
│       │   └── plugin.json                # Plugin manifest for Cursor
│       ├── skills/                        # All skills (shared by both platforms)
│       │   ├── lao/                       # Command: full pipeline (/lao)
│       │   ├── lao-dry-run/               # Command: simulation (/lao-dry-run)
│       │   ├── lao-setup/                 # Command: project setup (/lao-setup)
│       │   ├── product-management/        # Role: PRD and Jira ticket creation
│       │   ├── intake/                    # Role: scope extraction from Jira/requirements
│       │   ├── experience-design/         # Role: UX research, design options, specs
│       │   ├── architecture/              # Role: system design, ADRs, review
│       │   ├── coding-standards/          # Role: coding conventions
│       │   ├── testing-conventions/       # Role: test patterns and standards
│       │   ├── code-review/               # Role: PR and code review process
│       │   ├── security/                  # Role: security review and threat analysis
│       │   ├── acceptance-validation/     # Role: AC verification gate
│       │   └── shipping/                  # Role: PR creation, Jira updates
│       ├── contracts/
│       │   └── phase-output-schema.md     # Structured output contract
│       ├── docs/
│       │   └── 2026-04-04-lifecycle-agent-orchestrator-design-spec.md  # Design spec + ADRs
│       ├── examples/
│       │   ├── lao.config.yaml           # Annotated config file template
│       │   ├── reference-walkthrough.md   # End-to-end example scenarios
│       │   └── sample-requirement.md      # Bundled sample for dry-run
│       ├── scripts/
│       │   ├── check-consistency.sh       # Cross-reference consistency checks
│       │   ├── validate-plugin.sh         # Plugin structural validation (91 checks)
│       │   └── validate-project-skills.sh # Project skills validation (convention/config/scan)
│       └── tests/
│           ├── validate-plugin.bats       # Plugin validation tests
│           ├── validate-project-skills.bats # Project skills validation tests
│           └── fixtures/                  # Test data for bats tests
└── README.md                              # This file
```

**Consuming project** (your project that uses the plugin):

```
your-project/
└── skills/
    ├── architecture/PROJECT.md        # Overlay: project stack, patterns
    ├── coding-standards/PROJECT.md    # Overlay: project conventions
    ├── testing-conventions/PROJECT.md # Overlay: project test infra
    ├── code-review/PROJECT.md         # Overlay: project review checks
    ├── shipping/PROJECT.md            # Overlay: project CI/CD
    ├── compliance-review/SKILL.md     # Extra role: applies_to in frontmatter
    └── domain/                        # Cross-cutting domain context
        ├── auth-system.md             # Domain: auth patterns (all phases)
        └── payment-processing.md      # Domain: PCI constraints (scoped)
```

## Built-in Phase Workflows

Phases 6-9 (Plan, Implement, Validate, Ship) use standalone workflows built into
the plugin — no external dependencies required. These workflows include:

- **Phase 6 (Plan):** TDD task decomposition with no-placeholder rule, exact code in every step, self-review checklist
- **Phase 7 (Implement):** Strict TDD (red-green-refactor with verification), two-stage review (spec compliance + code quality), systematic debugging protocol
- **Phase 8 (Validate):** Evidence-based verification gate — no completion claims without fresh proof
- **Phase 9 (Ship):** Pre-ship test verification, structured completion options (PR, merge, keep, discard)

See `skills/lao/references/phase-workflows.md` for the complete workflow definitions.

### Design: Role Skills vs. Execution Workflows

The plugin uses two kinds of phase implementations — a deliberate split, not an
inconsistency:

**Phases 1-5: Role skills.** Each embodies a persona (PM, Designer, Architect)
whose judgment varies by project. A fintech architecture review looks different
from a game studio's. Customized via **project overlays**.

**Phases 6-9: Execution workflows.** Mechanical processes (decompose tasks, run
the TDD cycle, verify evidence, ship a PR). These are the orchestrator's own
engine — tightly coupled (plan structure dictates implement structure, implement
results feed validate checks) and universal by default.

The built-in workflows work out of the box for most teams. But everything is
overridable — add a `workflows` section in `lao.config.yaml` to replace any
phase's workflow with your own:

```yaml
workflows:
  implement: docs/workflows/our-bdd-process.md   # BDD instead of TDD
  ship: docs/workflows/our-release-process.md     # custom release flow
```

Workflow overrides **replace** the built-in workflow for that phase (not additive),
because methodology changes are substitutions, not layers. Omitted phases use the
built-in default.

See the [design spec](plugins/lifecycle-agent-orchestrator/docs/2026-04-04-lifecycle-agent-orchestrator-design-spec.md)
§ 2.4 for the full rationale.

## Distribution

This repo is structured as a Claude Code marketplace, so it's ready for distribution
as-is. Push to any Git host and share the install commands from the Installation section.

### Future: Submit to claude-plugins-official

The official Anthropic marketplace at `github.com/anthropics/claude-plugins-official`
accepts community plugins. Submission would make the plugin installable as:
```bash
/plugin install lifecycle-agent-orchestrator@claude-plugins-official
```

See the [claude-plugins-official repo](https://github.com/anthropics/claude-plugins-official)
for contribution guidelines.

## Available Skills

After installation, 13 skills are available in two categories:

### Commands (user-invoked)

These are the entry points you interact with directly:

| Command | Description |
|---|---|
| `/lao` | Full lifecycle pipeline — drives requirements through to PR (`/lifecycle-agent-orchestrator` is the canonical full command) |
| `/lao-dry-run` | Simulates the pipeline without making changes |
| `/lao-setup` | Interactive project setup — scan, configure, validate |

### Roles (orchestrator-managed)

These are invoked automatically by the orchestrator at the appropriate phase.
You rarely need to invoke them directly.

| Role | Phase(s) | Description |
|---|---|---|
| `product-management` | 1, cross-review | PRD creation and Jira ticket generation |
| `intake` | 4 | Jira story reader and scope extractor with acceptance criteria |
| `experience-design` | 2, cross-review | UX research, design options, and design specifications |
| `architecture` | 3, 5, cross-review | System design, tech design, ADRs, and architectural review |
| `coding-standards` | 7 | Coding conventions and standards enforcement (Python, Java, C#, React/TS) |
| `testing-conventions` | 7 | Test patterns, quality, and coverage standards (Python, Java, C#, React/TS) |
| `code-review` | 7 | PR and code review with severity classification (language-aware) |
| `security` | 7 | Security standards for auth, secrets, data protection, and compliance (language-aware) |
| `acceptance-validation` | 8 | Acceptance criteria verification gate |
| `shipping` | 9 | PR creation, Jira updates, and ship workflow |

## Multi-Language Support

Four skills — `coding-standards`, `testing-conventions`, `code-review`, and `security` — support
language-specific conventions via bundled **language packs**. Each skill has a two-layer structure:

- **Universal base** (`SKILL.md` + `references/checklist.md`) — language-agnostic principles
  (naming patterns, error handling strategy, test pyramid, security posture)
- **Language packs** (`references/<language>/`) — language-specific checklists, code examples,
  and tooling configuration

Supported languages: **Python**, **Java**, **C#**, **React/TypeScript**.

### How languages are detected

1. If `lao.config.yaml` has a `languages:` list → use it
2. Else if `language:` string is present → treat as single-item list (backward compatible)
3. Else auto-detect from project files — **all** rules are checked and every match
   is collected (a full-stack repo can match both `python` and `react`):
   - `pyproject.toml` / `setup.py` / `requirements.txt` → Python
   - `pom.xml` / `build.gradle` → Java
   - `*.csproj` / `*.sln` → C#
   - `package.json` with `react` dependency / `next.config.*` → React/TypeScript
4. If no match → ask the user

When multiple languages are detected, all packs are loaded. The agent applies
each pack to files of its language (e.g., Python standards to `.py` files,
React/TS standards to `.tsx`/`.ts` files).

### Configuration

Add the optional `languages` list (or `language` string) to `lao.config.yaml`:

```yaml
# Multi-language project (recommended for full-stack repos)
project_name: my-app
languages:
  - python
  - react

# Single language (backward compatible)
project_name: my-app
language: python
```

### What each language pack includes

| Skill | Universal | Per-Language Pack |
|---|---|---|
| `coding-standards` | Naming, error handling, logging, project structure | Checklist, code examples, tooling config (build, CI, Dockerfile) |
| `testing-conventions` | Test pyramid, naming, mocking strategy, coverage | Framework-specific checklist (pytest / JUnit / xUnit / Vitest+RTL) |
| `code-review` | Review modes, severity, output format | Language-specific code standards |
| `security` | Secret management, auth, OWASP, compliance | Framework-specific checklist and code examples |

**Bundled language packs:** Python, Java, C#, React/TypeScript.

### Adding a new language

To add support for another language (e.g., Go, Rust, TypeScript):

**Step 1 — Create language pack directories and files** in each of the 4 language-aware skills:

| Skill | Files to create under `references/<language>/` |
|---|---|
| `coding-standards` | `checklist.md`, `examples.md`, `tooling-config.md` |
| `testing-conventions` | `checklist.md` |
| `code-review` | `code-standards.md` |
| `security` | `checklist.md`, `examples.md` |

Use existing language packs (e.g., `references/python/`) as templates — match the
structure, headings, and level of detail. Each file should cover the language's
idiomatic patterns for that skill's domain (naming, error handling, test framework,
security libraries, build tooling, CI pipeline).

**Step 2 — Update detection and validation:**

- `lao/SKILL.md` — add detection rules for the new language's build files
  (e.g., `go.mod` → Go, `Cargo.toml` → Rust)
- `lao-setup/SKILL.md` — add the same detection to the project scan
- `validate-project-skills.sh` — add the language to the `VALID_LANGUAGES` list
- `validate-plugin.sh` — add the new `references/<language>/` paths to `EXPECTED_REFS`

**Step 3 — Document:**

- Update this README's "Supported languages" list and the "What each language pack
  includes" table
- Update the design spec § 9.3 "Supported languages" line

No changes needed to the universal `SKILL.md` files or checklists — those are
language-agnostic by design.

## Roadmap

- **Autonomous mode** — reduce human checkpoints for simple stories as skills harden
- **UI dashboard** — web UI rendering the PhaseOutput contract as a pipeline view with approval controls
- **Official marketplace submission** — publish to claude-plugins-official for one-command installation

## Design Document

Full design spec: `plugins/lifecycle-agent-orchestrator/docs/2026-04-04-lifecycle-agent-orchestrator-design-spec.md`
