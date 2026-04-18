---
name: lifecycle-agent-orchestrator-dry-run
aliases: [lao-dry-run]
description: >
  Dry-run mode for the lifecycle agent orchestrator. Simulates the full 9-phase pipeline against
  a sample or custom requirement without making any real changes — no files, no git,
  no Jira, no PRs. Use this to validate the orchestrator workflow, demonstrate the
  pipeline to new users, or test overlay integration. Trigger when the user says
  "dry run", "simulate the lifecycle", "test the orchestrator", or "show me how the
  pipeline works".
---

# Lifecycle Agent Orchestrator — Dry Run

You are running the lifecycle agent orchestrator in **dry-run mode**. This validates the full
workflow end-to-end by simulating every phase and producing PhaseOutput at each
checkpoint — without making any actual changes.

## Hard Rules

- **NO file creation or modification** — do not write code, create plans, or save documents
- **NO git operations** — do not create branches, make commits, or push
- **NO Jira operations** — do not create tickets, transition statuses, or add comments
- **NO PR creation** — do not push or create pull requests
- **SIMULATED OUTPUT ONLY** — every phase produces a realistic PhaseOutput as if the work
  was done, but nothing actually happens

## Input

If the user provided a requirement, use that.
Otherwise, read the bundled sample at `examples/sample-requirement.md` and use its requirement.

## Process

Read the orchestrator skill at `skills/lao/SKILL.md` and follow its
phase pipeline exactly, but at each phase:

1. **Announce the phase** — state which phase is running, which skill would be invoked
2. **Simulate the work** — describe what the skill would do (don't actually do it)
3. **Produce PhaseOutput** — render a realistic PhaseOutput per `contracts/phase-output-schema.md`
   using the CLI rendering format. Include realistic but simulated content.
4. **Present the checkpoint** — show the checkpoint to the user (combined checkpoints where
   the orchestrator would combine them)
5. **Wait for approval** — the user approves or requests changes, just like the real workflow
6. **Proceed to next phase** — on approval, move to the next phase

## What to Simulate at Each Phase

**Phase 1 — Product Management:**
- Simulate: PRD analysis, user story extraction, Jira ticket creation
- Cross-review: XD (UX feasibility) + Architecture (tech feasibility)
- Output: 2-3 user stories with acceptance criteria, ticket summary

**Phase 2 — Experience Design, PRD Level (if UX needed):**
- Simulate: Complete experience design across all tickets — journeys, screens, interactions, states
- Cross-review: PM (requirements coverage) + Architecture (tech feasibility)
- Output: Design deliverables summary with cross-review feedback

**Phase 3 — Architecture, System Design:**
- Simulate: System-level design, component boundaries, ADRs, dependency analysis, ticket ordering
- Cross-review: PM (AC coverage) + XD (design support, if Phase 2 ran)
- Output: System design summary + execution order recommendation

**Phase 4 — Intake:**
- Simulate: Scope extraction, AC numbering
- Output: Scope summary with numbered ACs

**Phase 5 — Tech Design:**
- Simulate: Low-level technical approach within system architecture
- Output: Design summary (no cross-review — purely technical)

**Phase 6 — Plan:**
- Simulate: Task breakdown
- Output: 3-5 task summaries (no actual plan file)

**Phase 7 — Implement:**
- Simulate: TDD execution, spec review, quality review per task
- Output: Task results table with all tasks passed

**Phase 8 — Validate:**
- Simulate: AC verification against "implemented" code
- Output: AC status table (all pass with simulated evidence), test results

**Phase 9 — Ship:**
- Simulate: PR description, Jira transition
- Output: Simulated PR summary and Jira update

## Checkpoint Collapsing

Apply the same collapsing rules as the real orchestrator:
- If the requirement produces a single backend ticket: 3 combined checkpoints (Phases 4-9)
- If UX is involved: Phase 1, Phase 2 (XD), Phase 3 (system design), then per-ticket checkpoints
- If complex with multiple tickets: full phase-by-phase checkpoints
- All cross-reviews happen in Phases 1-3, per-ticket phases have no cross-review gates

## At Completion

After all phases, print:

```
=== Dry Run Complete ===

Phases simulated: {N}
Checkpoints presented: {N}
Entry point detected: {A/B/C/D}
Phases skipped: {list or "None"}
Cross-reviews simulated: {N}

The lifecycle agent orchestrator workflow validated successfully.
No files were created, no branches, no Jira tickets, no PRs.
```

## Why This Exists

This standalone dry run serves three purposes:
1. **Validate the plugin** — confirm all skills, contracts, and the orchestrator flow work
2. **Demonstrate the workflow** — show users what the lifecycle pipeline looks like before using it on real work
3. **Test overlay integration** — if project overlays exist, the dry run shows how they're composed with base skills

**Note:** This is separate from the orchestrator's built-in preview phase. When you use
`/lao` on real work, it automatically starts with a preview before executing.
This standalone `/lao-dry-run` is for demos, validation, and testing — it
never transitions to real execution.
