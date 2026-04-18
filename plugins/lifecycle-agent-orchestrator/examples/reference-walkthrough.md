# Reference Walkthrough: Lifecycle Agent Orchestrator End-to-End

This walkthrough shows the full orchestrator flow for two scenarios:
1. **Simple:** Single Jira ticket, backend-only — 3 combined checkpoints
2. **Complex:** Raw requirement — PRD — multiple tickets — full pipeline

---

## Scenario 1: Simple Backend Story (Single Jira — PR)

**User:** "Work on PROJ-1234"

### Orchestrator Response:
> I'm using the Lifecycle Agent Orchestrator to drive this through the development lifecycle.
> Detected entry point: B (existing Jira ticket) — starting at Phase 4 (Intake).

### Checkpoint 1: Scope + Design + Plan (Combined)

```
=== Checkpoint: Scope, Design, and Plan ===

--- Phase: Intake (Phase 4 of 9) ---
Status: Completed

SUMMARY:
  PROJ-1234: Update rate limiting thresholds for 2026.
  3 acceptance criteria. Backend only.

ACCEPTANCE CRITERIA (tracked):
  AC1: Default rate limit per API key = 1,000 req/min .. pending
  AC2: Premium tier rate limit = 10,000 req/min ........ pending
  AC3: Burst allowance updated to 2x base limit ........ pending

--- Phase: Tech Design (Phase 5 of 9) ---
Status: Completed

SUMMARY:
  Update RATE_LIMITS config in rate_limiter.py for 2026.
  Add 2026 entry to tier-specific constants. No new models,
  no API changes, no new dependencies.

--- Phase: Plan (Phase 6 of 9) ---
Status: Completed

SUMMARY:
  3 tasks: update limiter constants, update test expectations,
  run validation scripts.

ARTIFACTS:
  - [plan] docs/plans/2026-04-09-rate-limits-update.md

→ Approve all to proceed to implementation, or request changes to a specific phase.
```

**User:** "Looks good, proceed"

### Checkpoint 2: Implement + Validate (Combined)

```
=== Checkpoint: Implementation and Validation ===

--- Phase: Implement (Phase 7 of 9) ---
Status: Completed

SUMMARY:
  3/3 tasks complete. All tests passing. Spec + quality reviews passed.

TASK RESULTS:
  ✅ Task 1: Update RATE_LIMITS in rate_limiter.py
     Spec: passed | Quality: passed
     Files: app/engine/middleware/rate_limiter.py
  ✅ Task 2: Update test expectations
     Spec: passed | Quality: passed
     Files: app/test/unit/engine/middleware/test_rate_limiter.py
  ✅ Task 3: Run validation
     Spec: passed | Quality: passed
     Files: (no changes — validation only)

--- Phase: Validate (Phase 8 of 9) ---
Status: Completed

SUMMARY:
  3/3 acceptance criteria verified. 65/65 tests passing.

ACCEPTANCE CRITERIA (tracked):
  AC1: Default rate limit per API key = 1,000 req/min .. ✅ pass
       Evidence: test_rate_limiter::test_default_limit_2026
  AC2: Premium tier rate limit = 10,000 req/min ........ ✅ pass
       Evidence: test_rate_limiter::test_premium_limit_2026
  AC3: Burst allowance updated to 2x base limit ........ ✅ pass
       Evidence: test_rate_limiter::test_burst_allowance_2026

→ Approve to proceed to shipping, or request changes.
```

**User:** "Ship it"

### Checkpoint 3: Ship

```
--- Phase: Ship (Phase 9 of 9) ---
Status: Needs Approval

SUMMARY:
  PR #47 created. PROJ-1234 transitioned to "In Review."

ARTIFACTS:
  - [pr] https://github.com/org/repo/pull/47
  - [jira_ticket] PROJ-1234 — "In Review"

→ Approve PR, or request changes.
```

**User:** "Approved"

> Pipeline complete. PROJ-1234 shipped as PR #47.

---

## Scenario 2: Complex Requirement (Raw Idea — Multiple Tickets — PRs)

**User:** "We need to add document upload support — users should be able to upload files and we extract structured data automatically to populate their profile."

### Orchestrator Response:
> I'm using the Lifecycle Agent Orchestrator to drive this through the development lifecycle.
> Detected entry point: A (raw requirement) — starting at Phase 1 (Product Management).

### Phase 1 Checkpoint: PRD

```
--- Phase: Product Management (Phase 1 of 9) ---
Status: Needs Approval

SUMMARY:
  PRD created: "Document Upload & Extraction." 3 user stories, 3 Jira tickets.

ARTIFACTS:
  - [prd] docs/prd/2026-04-09-document-upload.md
  - [jira_ticket] PROJ-200: Upload endpoint for documents
  - [jira_ticket] PROJ-201: Document extraction pipeline
  - [jira_ticket] PROJ-202: Profile population from extracted data

CROSS-REVIEWS:
  - XD: Approved with notes — "Upload UX needs drag-and-drop, not just file picker"
  - Architecture: Approved — "Extraction pipeline is feasible as in-process library"

→ Approve PRD and tickets, or request changes.
```

**User:** "Approved"

### Phase 2 Checkpoint: Experience Design

```
--- Phase: Experience Design (Phase 2 of 9) ---
Status: Needs Approval

SUMMARY:
  Upload UX designed: drag-and-drop with progress indicator, file type validation,
  extraction status display, and profile field mapping confirmation screen.

CROSS-REVIEWS:
  - PM: Approved — all 3 user stories have corresponding UX flows
  - Architecture: Approved — design is technically feasible

→ Approve experience design, or request changes.
```

**User:** "Approved"

### Phase 3 Checkpoint: System Design + Ticket Ordering

```
--- Phase: Architecture — System Design (Phase 3 of 9) ---
Status: Needs Approval

SUMMARY:
  Execution order: PROJ-201 first (extraction pipeline — foundation),
  then PROJ-200 (upload endpoint — depends on extraction),
  then PROJ-202 (profile population — depends on both).

CROSS-REVIEWS:
  - PM: Approved — all acceptance criteria addressable in this architecture
  - XD: Approved — design supports the upload and mapping UX flows

ARTIFACTS:
  - [dependency_graph] PROJ-201 → PROJ-200 → PROJ-202

→ Approve system design and ticket sequence, or request changes.
```

**User:** "Approved"

### Per-Ticket: PROJ-201 (Extraction Pipeline)

The orchestrator runs phases 4-9 for PROJ-201, then PROJ-200, then PROJ-202.
Each follows the same pattern as Scenario 1, with the appropriate number of
combined checkpoints based on complexity and whether UX is involved.

---

## Key Takeaways

1. **Same phases, different presentation.** Simple stories get 3 checkpoints. Complex stories get more.
2. **Acceptance criteria track through the pipeline.** From intake (pending) through validation (pass/fail).
3. **Cross-reviews catch issues early.** XD caught a UX gap in the PRD before any code was written.
4. **Human is always in control.** Every checkpoint allows approval, changes, or expansion.
5. **Structured output is consistent.** Same PhaseOutput format whether simple or complex.
