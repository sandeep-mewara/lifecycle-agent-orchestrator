---
name: intake
description: >
  Reads a Jira story or user-provided requirement and produces a structured scope summary
  with numbered acceptance criteria. Use this skill at the start of working on any ticket
  to establish what needs to be built, what the success criteria are, and whether UX changes
  are involved. Trigger when given a Jira ticket key, a story description, or when the
  orchestrator needs to extract structured requirements from an unstructured input.
---

# Intake — Scope Extraction

You extract structured requirements from Jira stories or user-provided descriptions.
Your output is the foundation that every downstream phase builds on — especially the
acceptance criteria, which are tracked through validation.

---

## Process

### 1. Read the Source

**If Jira ticket provided:**
- Read the ticket via Jira MCP (or ask the user to paste the content)
- Extract: title, description, acceptance criteria, story points, priority, labels, linked issues, attachments

**If user-provided description:**
- Read the description as-is
- Extract requirements and acceptance criteria from the text

### 2. Produce Structured Scope Summary

Output format (see `references/scope-summary-template.md`):

```
## Scope Summary

**Ticket:** {ticket_key} (or "User-provided requirement")
**Title:** {title}
**Priority:** {priority}
**Story Points:** {points} (if available)

### Description
{cleaned-up description — preserve intent, clarify ambiguities}

### Acceptance Criteria
- AC1: {criterion — specific, testable, measurable}
- AC2: {criterion}
- AC3: {criterion}

### UX Assessment
- UX changes needed: {yes/no}
- Reason: {why}

### Dependencies
- {any linked tickets, blocked-by relationships, or prerequisites}

### Design References
- {links to existing design docs, mockups, Figma files, if any}

### Open Questions
- {anything ambiguous in the story that needs clarification}
```

### 3. Derive Acceptance Criteria

If the Jira story has explicit acceptance criteria, use them. If not, derive them from the description:

- Each AC must be **specific** — not "the feature works" but "when user submits X, system responds with Y"
- Each AC must be **testable** — someone (or a script) can verify pass/fail
- Each AC must be **independent** — one AC failing doesn't automatically mean others fail
- Number them sequentially: AC1, AC2, AC3...

If you derive ACs that weren't in the original story, note that explicitly:
> "The following acceptance criteria were derived from the story description (not explicitly listed in the ticket):"

### 4. Determine UX Involvement

Check for signals that UX design is needed:
- Story mentions UI components, screens, forms, modals, or user-facing flows
- Story has labels like "frontend", "UI", "UX", "design-needed"
- Story references Figma files or design mockups
- Story describes user-visible behavior changes (not just API/backend)

If any signal is present: `ux_needed: true`
If all changes are backend, API, infrastructure, or data: `ux_needed: false`

### 5. Flag Open Questions

If anything is ambiguous, unclear, or missing from the story:
- List it explicitly in the Open Questions section
- Do not make assumptions — surface the ambiguity for the human to resolve

---

## Output

Produce a PhaseOutput per `contracts/phase-output-schema.md`:

- `phase_name`: "intake"
- `status`: "completed"
- `summary`: One-line summary of the ticket and AC count
- `artifacts`: [scope_summary document]
- `acceptance_criteria`: List of ACs with status "pending"
- `metadata`: {ticket_key, ux_needed, story_points, priority}
- `approval_needed`: false (typically combined with later phases)
- `next_phase`: "experience_design" if ux_needed, else "tech_design"
