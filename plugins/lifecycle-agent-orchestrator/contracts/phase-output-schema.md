# Phase Output Contract

Every lifecycle phase produces a `PhaseOutput` — a structured object that the CLI renders as formatted text and a future UI would render as a pipeline dashboard.

## Schema

### PhaseOutput

| Field | Type | Required | Description |
|---|---|---|---|
| `phase_name` | string | Yes | Phase identifier. One of: `product_management`, `experience_design`, `architecture_system_design`, `intake`, `tech_design`, `plan`, `implement`, `validate`, `ship` |
| `phase_number` | integer | Yes | Phase number (1-9) for ordering |
| `status` | string | Yes | One of: `completed`, `needs_approval`, `blocked`, `skipped` |
| `summary` | string | Yes | Human-readable summary, 1-3 lines |
| `artifacts` | list[Artifact] | No | Files, links, documents produced by this phase |
| `acceptance_criteria` | list[AC] | No | Tracked from intake (phase 4) through validation (phase 8) |
| `cross_reviews` | list[Review] | No | Feedback from reviewing roles (phases 1, 2, 3) |
| `task_results` | list[TaskResult] | No | Per-task implementation breakdown (phase 7) |
| `approval_needed` | boolean | Yes | Whether this phase gates on human approval |
| `next_phase` | string | Yes | Phase name of next step in pipeline |
| `metadata` | dict | No | Phase-specific extras (ticket_key, pr_url, branch_name, etc.) |

### Artifact

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string | Yes | One of: `file`, `jira_ticket`, `pr`, `design_doc`, `plan`, `prd`, `mockup` |
| `path_or_url` | string | Yes | File path or URL to the artifact |
| `description` | string | Yes | What this artifact is |

### AC (Acceptance Criterion)

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | Yes | Identifier, e.g., `AC1`, `AC2` |
| `text` | string | Yes | The acceptance criterion text |
| `status` | string | Yes | One of: `pending`, `pass`, `fail` — updated in phase 8 |
| `evidence` | string | No | How it was verified — populated in phase 8 |

### Review

| Field | Type | Required | Description |
|---|---|---|---|
| `reviewer_role` | string | Yes | One of: `pm`, `xd`, `architecture` |
| `verdict` | string | Yes | One of: `approved`, `approved_with_notes`, `changes_requested` |
| `feedback` | string | Yes | The review content |

### TaskResult

| Field | Type | Required | Description |
|---|---|---|---|
| `task_id` | string | Yes | Identifier, e.g., `task_1` |
| `description` | string | Yes | What the task implements |
| `status` | string | Yes | One of: `completed`, `failed`, `skipped` |
| `spec_review` | string | Yes | One of: `passed`, `failed_then_fixed` |
| `quality_review` | string | Yes | One of: `passed`, `failed_then_fixed` |
| `files_changed` | list[string] | Yes | Files created or modified by this task |

## CLI Rendering Format

When rendering a PhaseOutput in the CLI, use this format:

```
--- Phase: {phase_name} (Phase {phase_number} of 9) ---
Status: {status}

SUMMARY:
  {summary}

ARTIFACTS:                              # Omit section if empty
  - [{type}] {path_or_url} — {description}

CROSS-REVIEWS:                          # Omit section if empty
  - {reviewer_role}: {verdict} — {feedback}

ACCEPTANCE CRITERIA (tracked):          # Omit section if not phase 4 or 8
  {id}: {text} .............. {status}

TASK RESULTS:                           # Omit section if not phase 7
  {status_icon} Task {task_id}: {description}
    Spec: {spec_review} | Quality: {quality_review}
    Files: {files_changed}

→ {next action prompt based on status}
```

Status icons: ✅ = completed, ❌ = failed, ⏭ = skipped

## Combined Checkpoint Rendering

When multiple phases are presented in a single checkpoint, render each phase's output sequentially under a combined header:

```
=== Checkpoint: {checkpoint_description} ===

--- Phase: {phase_1_name} (Phase {n} of 9) ---
{phase_1_output}

--- Phase: {phase_2_name} (Phase {n} of 9) ---
{phase_2_output}

→ Approve all to proceed, or request changes to a specific phase.
```

## Future UI Consumption

A UI dashboard would consume PhaseOutput objects to render:

- **Pipeline view**: Horizontal or vertical list of phases with status indicators (completed/active/pending/skipped)
- **Phase detail panel**: Expandable view showing summary, artifacts, cross-reviews
- **AC tracker**: Visual tracker showing acceptance criteria status across the pipeline lifecycle (pending → pass/fail)
- **Approval controls**: Approve / Request Changes buttons per phase or per combined checkpoint
- **Timeline**: When each phase started, completed, and how long review loops took

The UI is purely a rendering layer — it reads the same PhaseOutput objects. No separate API is needed.
