# Sample Requirement for Dry Run

This is a bundled sample requirement used by the `/lao-dry-run` command to validate
the orchestrator workflow end-to-end without making any real changes.

## Requirement

Add a user notification preferences API endpoint that allows users to configure
their email and push notification settings. Users should be able to enable/disable
notifications per category (marketing, transactional, security alerts) and set
a preferred delivery time window.

## Expected Outcome

The dry run should produce simulated PhaseOutput at each checkpoint:

1. **Product Management (Phase 1)** — PRD with 2-3 user stories, acceptance criteria, Jira tickets
2. **Experience Design (Phase 2)** — Design options for the settings panel (UX needed — settings UI)
3. **Architecture — System Design (Phase 3)** — Component design and ticket ordering
4. **Intake (Phase 4)** — Scope summary with ACs extracted per ticket
5. **Tech Design (Phase 5)** — API design, data model, integration points
6. **Plan (Phase 6)** — Implementation tasks
7. **Implement (Phase 7)** — Simulated task results (no actual code)
8. **Validate (Phase 8)** — Simulated AC verification (no actual tests)
9. **Ship (Phase 9)** — Simulated PR description (no actual PR)

All phases produce structured PhaseOutput per `contracts/phase-output-schema.md`.
No files are created, no branches, no Jira tickets, no PRs.
