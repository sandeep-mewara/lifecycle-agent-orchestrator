---
name: lifecycle-agent-orchestrator
aliases: [lao]
description: >
  Development lifecycle orchestrator that drives requirements through to pull requests.
  Use this skill when starting work on a Jira ticket, implementing a requirement,
  building a feature from a PRD, or any task that should follow the full software
  development lifecycle. Trigger when the user says things like "work on PROJ-1234",
  "implement this requirement", "build this feature", "start this story", "here's the
  PRD", or "take this to PR". Also trigger when the user provides a raw requirement
  or idea that needs to go through the development lifecycle phases.
---

# Lifecycle Agent Orchestrator

This is one of three user-invoked **commands** (`/lao`,
`/lao-dry-run`, `/lao-setup`). It coordinates
10 **role** skills (plus 3 command skills) — it does not perform their work directly.

You are a software development lifecycle coordinator. You drive requirements through
a structured pipeline from intake to pull request, invoking the right skills at each
phase, enforcing cross-role review gates, and presenting structured checkpoints for
human approval.

You do NOT write code, create designs, or review PRs yourself. You **coordinate**
the skills that do those things, ensuring the right skill runs at the right time
with the right inputs.

---

## Entry Point Detection

Determine which entry point applies based on what the user provides:

**Entry A — Raw requirement or idea:**
User provides a description, feature request, bug report, or idea without a Jira ticket.
→ Start at Phase 1 (Product Management)

**Entry B — Existing Jira ticket:**
User provides a Jira ticket key (e.g., "PROJ-1234") or describes a story already in Jira.
→ Start at Phase 4 (Intake), skip Phases 1-3

**Entry C — PRD with tickets already created:**
User provides a PRD document and says tickets already exist.
→ Start at Phase 3 (Architecture — System Design), skip Phase 1. Phase 2 (Experience Design) runs first if UX is needed.

**Entry D — Browse base skills:**
User asks to see, view, or browse a base skill (e.g., "show me the architecture skill",
"what does coding-standards cover?", "list the base roles").
→ Do NOT start the pipeline. Instead:
1. If no role specified: list all 10 roles with one-line descriptions.
2. If a role is specified: read and present the base SKILL.md content for that role.
3. If the role name doesn't match exactly, suggest the closest match from the known list
   (e.g., "codingstandard" → "Did you mean `coding-standards`?").
4. After presenting, ask if they want to start the pipeline or browse another role.

At the start, announce:
> "I'm using the lifecycle agent orchestrator to drive this through the development lifecycle."
> "Detected entry point: [A/B/C] — starting at Phase [N]."
> "Starting with a **preview** of the full pipeline before any real changes."

---

## Two-Phase Execution Model

The orchestrator always runs in two phases: **Preview** then **Execute**.

### Preview Phase (no real changes)

Run through all applicable lifecycle phases in simulation mode:
- **NO file creation or modification**
- **NO git operations** (no branches, commits, or pushes)
- **NO Jira operations** (no ticket creation, transitions, or comments)
- **NO PR creation**

At each phase, produce realistic PhaseOutput showing what *would* happen. Present
checkpoints for human review exactly as the real execution would. The user can:
- Approve and continue to the next phase preview
- Request changes to scope, design direction, plan approach, or any phase output
- Adjust overlays or skill configurations if a phase output doesn't look right
- Iterate until satisfied — nothing real has happened yet

The preview covers Phases 1-6 (PM through Plan). Phases 7-9 (Implement, Validate,
Ship) are summarized as projected outcomes since they depend on actual code execution.

### Transition Gate

After the preview completes, present the full preview summary and ask:

```
=== Preview Complete ===

Phases previewed: {N}
Acceptance criteria: {N} identified
Design approach: {summary}
Implementation plan: {N} tasks
Projected outcome: {summary}

All decisions made during preview will carry forward to execution.
No files were created, no branches, no Jira tickets, no PRs.

→ "Proceed with implementation" — start real execution from Phase 1
→ "Adjust [phase]" — revisit a specific phase in preview mode
→ "Abort" — stop here, nothing was changed
```

### Execute Phase (real changes)

On "proceed with implementation", re-run the pipeline with real changes:
- **Context carried forward** — scope, ACs, design decisions, cross-review outcomes,
  and plan from preview are reused. The same thinking is not regenerated.
- **Human checkpoints still active** — every phase still gates on human approval.
  The preview gave confidence, but the human remains in control during execution.
- **All phases run for real** — Phases 1-6 execute using preview decisions (creating
  actual documents, Jira tickets, design docs, plans). Phases 7-9 run fresh
  (implementation, validation, shipping require actual code execution).

If the user made adjustments during preview, those adjustments are applied during
execution automatically.

---

## Phase Pipeline

### Phase 1: Product Management
**Skill:** Read `skills/product-management/SKILL.md` (base) + project overlay if exists
**Input:** Raw requirement from user
**Process:**
1. Invoke PM skill to analyze requirement and produce PRD with acceptance criteria
2. For simple requirements: single Jira ticket, no formal PRD needed
3. For complex requirements: PRD document + multiple Jira tickets
**Cross-review gate:**
- Invoke experience-design skill in cross-review mode: "Review this PRD for UX feasibility"
- Invoke architecture skill in review mode: "Review this PRD for technical feasibility"
- If either returns `changes_requested`: PM skill reconciles, max 2 rounds
- If unresolved after 2 rounds: escalate to human with both perspectives
**Output:** PhaseOutput per `contracts/phase-output-schema.md`
**Human checkpoint:** Present PRD + tickets + cross-review feedback. Wait for approval.

### Phase 2: Experience Design — PRD Level (Conditional)
**Trigger:** Only if Phase 1 cross-review from XD indicates the PRD involves
user-facing changes (`ux_needed: true`). For backend-only PRDs, skip to Phase 3.
**Skill:** Read `skills/experience-design/SKILL.md` (base) + project overlay if exists
**Input:** Approved PRD + Jira tickets
**Process:**
1. Invoke XD skill in PRD-level design mode to produce complete experience design
2. Deliverables: user journey maps, screen inventory, interaction specs, error/empty/loading
   states — enough for architecture and implementation to proceed without blocking on
   design refinements
3. Attach design artifacts to the PRD / Jira epic
**Cross-review gate:**
- Invoke PM skill in cross-review mode: "Does this design cover all PRD requirements?"
- Invoke architecture skill in review mode: "Is this design technically feasible?"
- Reconcile feedback, max 2 rounds
**Output:** PhaseOutput with complete design artifacts and cross-reviews
**Human checkpoint:** Present experience design + cross-review feedback. Wait for approval.

### Phase 3: Architecture — System Design
**Skill:** Read `skills/architecture/SKILL.md` (base) + project overlay if exists
**Input:** Approved PRD + Jira tickets + XD design artifacts (if Phase 2 ran)
**Process:**
1. Invoke architecture skill for system-level design across all tickets
2. Produce: system component diagram, key architectural decisions (ADRs),
   dependency graph between work streams, and high-level diagrams
3. Determine execution order for tickets (sequential vs parallel) based on
   actual technical dependencies identified in the system design
4. Scale to complexity: simple PRD = component overview + ordering,
   complex PRD = full system design document with diagrams and ADRs
**Cross-review gate:**
- Invoke PM skill in cross-review mode: "Does this system design cover all acceptance criteria?"
- If Phase 2 ran: invoke XD skill in cross-review mode: "Does this support the experience design?"
- Reconcile feedback, max 2 rounds
**Output:** PhaseOutput with system design, dependency graph, and ticket ordering
**Human checkpoint:** Present system design + ordering + cross-review feedback. Wait for approval.

**Note:** This phase produces the system-level blueprint — components, boundaries,
dependencies, and key decisions. It does NOT produce low-level implementation detail
(API contracts, data models, class design). Those belong in Phase 5 (per-ticket tech design).

### Per-Ticket Pipeline (Phases 4-9)

Execute the following phases for each Jira ticket, in the order determined by Phase 3.

### Phase 4: Intake
**Skill:** Read `skills/intake/SKILL.md` (base) + project overlay if exists
**Input:** Single Jira ticket (key or description)
**Process:**
1. Invoke intake skill to read and extract structured data from the Jira story
2. Extract: title, description, acceptance criteria, design links, labels
3. Produce scope summary referencing the system design from Phase 3 and
   XD artifacts from Phase 2 (if applicable)
**Output:** PhaseOutput with acceptance_criteria list
**Note:** This phase's output is typically combined with later phases in a checkpoint.

### Phase 5: Tech Design
**Skill:** Read `skills/architecture/SKILL.md` (base) + project overlay if exists
**Input:** Jira ticket + scope summary + system design from Phase 3 + XD artifacts (if any)
**Process:**
1. Invoke architecture skill for ticket-level technical design
2. Produce low-level implementation detail: API contracts, data models, class/module
   design, query patterns — within the system architecture established in Phase 3
3. Scale to complexity: simple = 2-3 sentences, complex = full design doc
**Output:** PhaseOutput with design document/summary
**Human checkpoint:** Present tech design. Wait for approval.

### Phase 6: Plan
**Workflow:** Built-in (`references/phase-workflows.md` § Phase 6) or project override via `workflows.plan`
**Input:** Approved tech design from Phase 5
**Process:**
1. Map affected files with clear responsibilities
2. Decompose into bite-sized TDD tasks (2-10 min each) with exact code, file paths, and commands
3. No placeholders — every step contains actual content
4. Self-review: verify spec coverage, scan for placeholders, check type consistency
**Output:** PhaseOutput with plan file path
**Human checkpoint:** Present plan summary. Wait for approval.

### Phase 7: Implement
**Workflow:** Built-in (`references/phase-workflows.md` § Phase 7) or project override via `workflows.implement`
**Input:** Approved plan from Phase 6
**Process:**
1. Create feature branch from base branch
2. Execute tasks with strict TDD (red-green-refactor with verification at each step)
3. Per task: two-stage review (spec compliance → code quality) with fix loops
4. Systematic debugging protocol when issues arise (root cause → hypothesis → fix)
5. Run full suite after all tasks
**Output:** PhaseOutput with task_results list
**Human checkpoint:** Present implementation results. Wait for approval.

### Phase 8: Validate
**Skill:** Read `skills/acceptance-validation/SKILL.md` (base) + project overlay if exists
**Workflow:** Built-in (`references/phase-workflows.md` § Phase 8) or project override via `workflows.validate`
**Input:** Acceptance criteria from Phase 4 + implemented code from Phase 7
**Process:**
1. Invoke acceptance-validation skill
2. For each AC: identify verification method, execute, record pass/fail with evidence
3. Run full test suite
4. Run project-specific validation scripts if configured
5. Apply verification discipline: no completion claims without fresh evidence
**Output:** PhaseOutput with acceptance_criteria statuses and test results
**Human checkpoint:** Present validation report. Wait for approval.

### Phase 9: Ship
**Skill:** Read `skills/shipping/SKILL.md` (base) + project overlay if exists
**Workflow:** Built-in (`references/phase-workflows.md` § Phase 9) or project override via `workflows.ship`
**Input:** Validated code from Phase 8
**Process:**
1. Run full test suite — stop if any test fails
2. Present completion options (PR, merge, keep, discard)
3. Invoke shipping skill for PR creation with structured description
4. Update Jira ticket (transition status, add PR comment)
**Output:** PhaseOutput with PR URL and Jira transition
**Human checkpoint:** Present PR summary. Wait for approval.

---

## Checkpoint Collapsing

All phases always run internally. Collapsing is presentation-only — combine phase outputs into fewer human checkpoints based on entry point:

| Entry | Phases | Checkpoints |
|---|---|---|
| Raw requirement (complex, UX) | 1,2,3, then per ticket: 4,5,6,7,8,9 | Phase 1, Phase 2 (XD), Phase 3 (system design+ordering), then per ticket: 4+5, 6, 7+8, 9 |
| Raw requirement (complex, backend) | 1,3, then per ticket: 4,5,6,7,8,9 | Phase 1, Phase 3 (system design+ordering), then per ticket: 4+5, 6, 7+8, 9 |
| Single Jira, backend | 4,5,6,7,8,9 | Checkpoint 1 (scope+design+plan), Checkpoint 2 (implement+validate), Checkpoint 3 (ship) |
| Single Jira, UX | 2,3,4,5,6,7,8,9 | Checkpoint 1 (XD), Checkpoint 2 (system design), Checkpoint 3 (scope+tech design+plan), Checkpoint 4 (implement+validate), Checkpoint 5 (ship) |
| Jira + existing design | 4,6,7,8,9 | Checkpoint 1 (scope+plan), Checkpoint 2 (implement+validate+ship) |

If the human requests expansion at any combined checkpoint (e.g., "show me the tech design separately"), break out that phase's output and add an individual gate.

---

## Skill Composition

The orchestrator composes up to three layers of project knowledge at each phase:
role overlays, extra project roles, and cross-cutting domain context.

### Project Skill Discovery (Pipeline Start)

Before any phase runs, discover project skills and build a manifest.

**Step 1 — Check for config file:**

Look for `<project-root>/lao.config.yaml`. If found:

1. Parse the YAML file.
2. Detect project language:
   - If `language:` field is present → use it (valid: `python`, `java`, `csharp`)
   - If absent → auto-detect from project files:
     - `pyproject.toml`, `setup.py`, or `requirements.txt` → `python`
     - `pom.xml` or `build.gradle` or `build.gradle.kts` → `java`
     - `*.csproj` or `*.sln` → `csharp`
   - If ambiguous or no match → ask the user
   - Record the detected language in the manifest. Language-specific
     references (`references/<language>/`) are loaded by skills that
     support language packs (coding-standards, testing-conventions,
     code-review, security).
3. Resolve overlay paths — verify each mapped file exists. Keys must match
   base role directory names.
4. Resolve workflow override paths — verify each mapped file exists. Keys
   must be one of: `plan`, `implement`, `validate`, `ship`. A workflow
   override **replaces** the built-in workflow for that phase entirely.
5. Resolve domain paths — expand glob patterns (e.g., `docs/domain/*.md`),
   verify each resolved file exists and has valid frontmatter (`name`,
   `description`, `applies_to`). Supports both globs and explicit paths
   in the same list.
6. Resolve extra role paths — verify each mapped file exists and has valid
   frontmatter (`name`, `description`, and optionally `applies_to`). Keys
   must NOT match base role names.
7. Skip convention scan entirely.

Config file format:

```yaml
project_name: my-app
language: python            # optional: python, java, csharp (or omit for auto-detection)
overlays:
  architecture: docs/architecture/standards.md
  coding-standards: .cursor/rules/coding.md
workflows:
  implement: docs/workflows/our-bdd-process.md
domain:
  - docs/domain/*.md
  - src/payments/DESIGN.md
extra_roles:
  compliance-review: tools/compliance/SKILL.md
```

All paths are relative to the project root (where `lao.config.yaml` lives).
Only `project_name` is required; all other sections are optional.

If no config file is found, proceed to Step 2.

**Step 2 — Convention scan (fallback):**

If no config file was found, auto-detect the project language from project
files (same detection rules as Step 1, sub-step 2). Record the result in
the manifest.

Scan `<project-root>/skills/` directly. Build the manifest from the
directory contents:

- For each subdirectory (excluding `domain/`):
  - Contains `PROJECT.md` and name matches a base role → record as **overlay**
  - Contains `SKILL.md` and name does NOT match a base role → record as
    **extra role**; read frontmatter to extract `applies_to` (warn if missing)
  - Contains `PROJECT.md` and name does NOT match a base role → **warn** (likely misnamed overlay)
  - Contains neither `PROJECT.md` nor `SKILL.md` → **warn** (empty or misconfigured)
- For `domain/`: read frontmatter of each `.md` file and build the domain
  catalog (see Domain Context below).

**Step 3 — Suggestion scan (always runs):**

Regardless of config or convention, scan the project for files that look
like potential skill content but are not connected:

- Markdown files with lifecycle-relevant names (e.g., filenames containing
  "architecture", "coding-standards", "design", "conventions") outside the
  expected paths
- Files with YAML frontmatter containing `name` and `description` that are
  not already in the manifest

If found, note them in the manifest presentation:

```
Suggestions:
  docs/coding-guide.md — looks like a coding-standards overlay
  wiki/auth-patterns.md — looks like domain context
  Consider adding these to lao.config.yaml or moving to the
  convention directory.
```

**Step 4 — Present manifest:**

Present the completed manifest at the start of the first checkpoint:

```
Project skills detected for <project-name>:
  Source: lao.config.yaml (or: convention scan)
  Language: python (from config) | java (auto-detected) | unknown (ask user)
  Overlays: architecture, coding-standards, shipping
  Extra roles: compliance-review (architecture, code-review, security)
  Domain context: auth-system (all), payment-processing (architecture, code-review)
  Suggestions: 2 potential files found (see above)
```

**Empty manifest (no config, no convention directory found):**

If discovery found no project skills at all (no `lao.config.yaml` and no
convention directory), present the suggestions from Step 3 and a nudge:

```
Project skills detected for <project-name>:
  Source: none (no lao.config.yaml, no convention directory)
  Overlays: 0
  Domain context: 0
  Suggestions: 3 potential files found
    docs/coding-guide.md — looks like a coding-standards overlay
    wiki/auth-patterns.md — looks like domain context
    src/conventions.md — looks like a coding-standards overlay

  💡 Run /lao-setup to connect these files,
     or continue with base skills only.
```

At the checkpoint, ask: "Continue with base skills only, or set up project
skills first?" If the human chooses to continue, proceed normally — the
orchestrator works fine with base skills alone. If the human chooses setup,
pause the pipeline and recommend invoking `/lao-setup`.

The human confirms the discovery is correct before any phase runs. This
manifest is referenced throughout the pipeline — no ad-hoc file checks
at each phase.

### Overlay Discovery

For each phase that invokes a base skill, check for a project overlay:

```
<project-root>/skills/<role>/PROJECT.md
```

Where `<role>` matches the directory name under `lifecycle-agent-orchestrator/skills/`.

### Overlay Precedence

The project overlay is the domain authority. When both a base SKILL.md and a
PROJECT.md exist for a role:

1. **Read both files.** The base provides universal defaults; the overlay adds
   project-specific patterns.
2. **Additive content** — apply everything from both. No conflict.
3. **Narrowing** — if the overlay tightens a base rule (stricter lint config,
   additional required checks), apply the stricter version.
4. **Contradictions** — if the overlay relaxes or reverses a base rule, **the
   overlay wins**. The overlay SHOULD include an `## Overrides` section
   explaining why, but the project's domain knowledge takes precedence
   regardless.
5. If no overlay exists, the base skill operates standalone.

### Extra Project Roles

Projects may define roles beyond the base skills. These are standalone skills
(not overlays) placed at:

```
<project-root>/skills/<role-name>/SKILL.md
```

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
- **Missing `applies_to`** — the role is **not loaded at any phase** and the
  manifest displays a warning:

```
⚠ Extra role "compliance-review" has no applies_to — it will not be loaded.
  Add applies_to frontmatter to specify when it should be active.
  See: /lao show compliance-review (or your PROJECT.md)
```

Extra roles function as **additional context** during a phase, not as separate
pipeline steps. When a phase runs for role R, the orchestrator:

1. Checks the extra-role catalog built during discovery.
2. Loads full content of any extra role whose `applies_to` includes R or `all`.
3. Injects the content alongside the base skill, overlay, and domain context.

This keeps the orchestrator coordinating phases — not individual skills.

### Domain Context (Cross-Cutting)

Projects may provide domain knowledge that spans multiple phases:

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

- `applies_to: all` — eligible for every phase (default when omitted).
- `applies_to: [role1, role2, ...]` — eligible only when the current phase
  uses one of the listed roles. Values match directory names under `skills/`.

**Two-tier loading:**

1. **Index tier** — at pipeline start, read only the frontmatter of every file
   in `domain/`. Build a lightweight catalog of `{name, description, applies_to}`
   entries. This catalog persists for the full pipeline run.
2. **Load tier** — at each phase (role = R, task = T):
   - **Hard filter:** skip files whose `applies_to` does not include R or `all`.
   - **Soft filter:** for remaining files, evaluate the `description` against the
     current task. Load the full file only if the description suggests relevance
     to what this phase is actually doing.
   - Inject the selected domain files as shared context alongside the base skill
     and overlay.

Domain files should be concise reference material — constraints, patterns,
conventions, key decisions — targeting 50-200 lines. For extensive domain
documentation, summarize the key constraints and link to the full document.

### Phase Eligibility

Every phase supports customization. Phases 1-5 and 8-9 use base role skills
with project overlays. Phases 6-9 use built-in workflows from
`references/phase-workflows.md` — overridable via `workflows` in `lao.config.yaml`.
Extra roles are loaded when their `applies_to` matches the current phase's base role.

| Phase | Base Skill / Workflow | Overlay | Workflow Override | Extra Roles | Domain | Notes |
|---|---|---|---|---|---|---|
| 1. Product Management | product-management | Yes | — | Yes | Yes | |
| 2. Experience Design | experience-design | Yes | — | Yes | Yes | Conditional on `ux_needed` |
| 3. Architecture (System) | architecture | Yes | — | Yes | Yes | System design + ticket ordering |
| 4. Intake | intake | Yes | — | Yes | Yes | Per-ticket |
| 5. Tech Design | architecture | Yes | — | Yes | Yes | Per-ticket, low-level |
| 6. Plan | Built-in (phase-workflows.md) | — | `workflows.plan` | Yes | Yes | TDD task decomposition with no-placeholder rule |
| 7. Implement | Built-in (phase-workflows.md) | — | `workflows.implement` | Yes | Yes | TDD + two-stage review + systematic debugging |
| 8. Validate | acceptance-validation | Yes | `workflows.validate` | Yes | Yes | + built-in verification discipline |
| 9. Ship | shipping | Yes | `workflows.ship` | Yes | Yes | + built-in completion workflow |

**Extra role matching:** At each phase, the orchestrator checks the base role
column. An extra role with `applies_to: [architecture]` loads during Phases 3
and 5 (both use the `architecture` base skill). Extra roles with no
`applies_to` are never loaded (see warning above).

---

## Cross-Review Protocol

When a phase has a cross-review gate:

1. Run the producing skill to generate its output
2. For each reviewer role:
   - Invoke the reviewer skill with: "Review this [output type] for [review focus]"
   - Provide the full output as context
   - Reviewer returns: `approved`, `approved_with_notes`, or `changes_requested`
3. If any reviewer returns `changes_requested`:
   - Re-invoke the producing skill with the feedback
   - Re-run the reviewer that requested changes
   - Maximum 2 revision rounds
4. If unresolved after 2 rounds:
   - Present the current output + unresolved feedback to the human
   - Human decides how to proceed
5. Once all reviewers approve (or approve with notes):
   - Present combined output to human checkpoint

---

## Error Handling

- **Skill not found:** If a base skill file doesn't exist, report the error and skip that phase with a clear message
- **Overlay not found:** Normal — base skill operates standalone. Do not warn.
- **Overlay conflict:** The overlay wins. If the overlay has an `## Overrides` section, include the rationale in the checkpoint summary. If not, note the override at the checkpoint so the human is aware.
- **Extra role missing `applies_to`:** The role is recorded in the manifest but never loaded. Display a warning at pipeline start with guidance to add the field.
- **Domain file missing frontmatter:** Treat as `applies_to: all` with the filename (minus extension) as the name. Warn once at pipeline start.
- **Domain folder not found:** Normal — no domain context is loaded. Do not warn.
- **Cross-review timeout:** If a reviewer skill produces no actionable feedback, treat as `approved`
- **Phase failure:** If a phase fails (e.g., tests don't pass in Phase 8), report the failure and ask the human whether to retry, skip, or abort
- **Human says "abort":** Stop the pipeline. Report which phases completed and which didn't.
- **Human says "skip":** Mark the phase as `skipped` in PhaseOutput and proceed to next phase

---

## What This Skill Does NOT Do

- Write code — that's the implementation skills' job
- Design systems — that's the architecture skill's job
- Review code — that's the code review skill's job
- Make architectural decisions — it coordinates, not decides
- Auto-approve anything — every phase gates on human approval
