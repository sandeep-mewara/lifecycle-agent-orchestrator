# Phase Workflows

Standalone workflows for Phases 6-9 of the lifecycle pipeline. These are the
orchestrator's built-in execution engine — no external plugins required.

Phases 1-5 are driven by their respective base skills (product-management,
experience-design, architecture, intake). Phases 6-9 follow the workflows below.

---

## Phase 6: Plan

### Input
Approved tech design from Phase 5.

### Process

#### Step 1: Map the file structure

Before defining tasks, map every file that will be created or modified:

```
Files:
  Create: app/service/notifications.py — notification preference logic
  Create: app/models/notification_prefs.py — Pydantic request/response models
  Create: app/router/notification_routes.py — API endpoints
  Modify: app/service/server.py:45-50 — register new router
  Create: test/unit/service/test_notifications.py — unit tests
  Create: test/integration/test_notification_api.py — integration tests
```

Design units with clear boundaries and one responsibility per file. Files that
change together should live together — split by responsibility, not by layer.

#### Step 2: Decompose into tasks

Each task is a self-contained, testable change completable in 2-10 minutes.
A single task follows this rhythm:

1. Write the failing test — one step
2. Run it, confirm it fails correctly — one step
3. Implement minimal code to pass — one step
4. Run tests, confirm green — one step
5. Commit — one step

Use this template for every task:

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

  ```python
  def test_specific_behavior():
      result = function(input)
      assert result == expected
  ```

- [ ] **Step 2: Run test to verify it fails**

  Run: `pytest tests/path/test.py::test_name -v`
  Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

  ```python
  def function(input):
      return expected
  ```

- [ ] **Step 4: Run test to verify it passes**

  Run: `pytest tests/path/test.py::test_name -v`
  Expected: PASS

- [ ] **Step 5: Commit**

  ```bash
  git add tests/path/test.py src/path/file.py
  git commit -m "feat: add specific feature"
  ```
```

#### Step 3: No placeholders

Every step must contain actual content. These are plan failures — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" (show the actual error handling code)
- "Write tests for the above" (show the actual test code)
- "Similar to Task N" (repeat the code — the implementer may read tasks out of order)
- Steps that describe what to do without showing how (code blocks required)
- References to types, functions, or methods not defined in any task

#### Step 4: Define execution order

Order tasks so each builds on the previous. Mark tasks that can run in parallel.
Note dependencies explicitly.

#### Step 5: Write the plan document

Save as `docs/plans/YYYY-MM-DD-<feature-name>.md` (or the project's preferred
location). The plan must include:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]
**Architecture:** [2-3 sentences about approach]
**Tech Stack:** [Key technologies/libraries]

---

## File Structure
[File map from Step 1]

## Tasks
[Task list from Step 2]

## Verification
Run: [full test suite command]
Expected: [all tests passing, N new tests added]
```

#### Step 6: Self-review

After writing the complete plan, review it:

1. **Spec coverage** — skim each requirement from the tech design. Can you point to
   a task that implements it? List any gaps.
2. **Placeholder scan** — search for any of the patterns from the no-placeholders
   rule. Fix them.
3. **Type consistency** — do types, method signatures, and property names used in
   later tasks match what's defined in earlier tasks?

If you find issues, fix them inline. If you find a requirement with no task, add it.

### Output
PhaseOutput with the plan file path and task count.

---

## Phase 7: Implement

### Input
Approved plan from Phase 6.

### Process

#### Step 1: Set up workspace

Create a feature branch from the base branch:
```
git checkout -b feature/<ticket-id>-<short-description>
```

#### Step 2: Execute tasks

For each task in the plan, follow the TDD cycle strictly.

##### Test-Driven Development (TDD)

The iron rule: **no production code without a failing test first.**

If you wrote code before the test, delete it. Start over with the test. No exceptions.

**RED — Write the failing test:**
- One test, one behavior
- Clear name that describes the expected behavior
- Use real code, not mocks, unless mocking is unavoidable (external services)

**Verify RED — Watch it fail:**
- Run the test. Confirm it fails.
- Confirm it fails for the *right reason* (missing function, not a typo or import error).
- If the test passes immediately, you're testing existing behavior — fix the test.
- If the test errors (not fails), fix the error and re-run until it fails correctly.

**GREEN — Write minimal code:**
- Simplest code that makes the test pass. Nothing more.
- Don't add features the test doesn't demand.
- Don't refactor yet.

**Verify GREEN — Watch it pass:**
- Run the test. Confirm it passes.
- Run the full relevant test suite. Confirm no regressions.
- If the test fails, fix the code (not the test).

**REFACTOR — Clean up (only after green):**
- Remove duplication, improve names, extract helpers.
- Keep tests green throughout. Don't add behavior.

**Commit:**
- Descriptive message referencing the task number.
- One commit per task (squash if the TDD cycle produced multiple).

##### Two-Stage Review (per task)

After each task's TDD cycle, run two review passes before moving to the next task:

**Stage 1 — Spec compliance review:**

Ask: "Does this implementation match exactly what the task specified?"

Check:
- Every requirement in the task spec is implemented
- Nothing extra was added beyond the spec (no "while I'm here" additions)
- Types, method signatures, and return values match the plan

If issues found → fix → re-check spec compliance. Do not proceed until clean.

**Stage 2 — Code quality review:**

Ask: "Is this implementation well-built?"

Check:
- No unused imports, dead code, or debug prints
- Proper error handling for edge cases and external calls
- No hardcoded values that should be configuration
- No secrets, tokens, or PII in code or comments
- Naming is clear and consistent
- No commented-out code

Classify issues:
- **Critical** — security vulnerability, data loss risk, crash → fix immediately
- **Important** — missing error handling, poor naming, logic flaw → fix before next task
- **Minor** — style preference, potential optimization → note for later

If Critical or Important issues found → fix → re-review. Do not proceed until clean.

#### Step 3: When things go wrong — Systematic Debugging

When a test fails unexpectedly or an implementation doesn't work as designed,
follow this protocol. Do not guess at fixes.

**Phase A — Root cause investigation (before attempting ANY fix):**

1. **Read error messages carefully** — full stack traces, exact error text, line
   numbers. Don't skip past them.
2. **Reproduce consistently** — can you trigger it reliably? What are the exact steps?
3. **Check recent changes** — what changed that could cause this? `git diff` is
   your friend.
4. **Trace data flow** — where does the bad value originate? What called this
   function with bad input? Keep tracing backward until you find the source.

**Phase B — Pattern analysis:**

1. Find working examples of similar code in the same codebase.
2. Compare working vs broken. List every difference.
3. Don't assume any difference "can't matter."

**Phase C — Hypothesis testing:**

1. Form a single, specific hypothesis: "X is the root cause because Y."
2. Make the *smallest possible change* to test it. One variable at a time.
3. Did it work? → proceed. Didn't work? → form a *new* hypothesis. Don't stack
   fixes on top of each other.

**Phase D — Fix:**

1. Write a failing test that reproduces the bug.
2. Implement a single fix targeting the root cause.
3. Verify: test passes, no regressions.

**Escalation rule:** If you've tried 3+ fixes and none work, stop. This is likely
an architectural problem, not a bug. Present the evidence to the human and discuss
whether the approach needs rethinking. Do not attempt fix #4 without that conversation.

#### Step 4: After all tasks

1. Run the complete test suite. Fix any regressions.
2. Run linter/formatter. Fix any violations.
3. Run type checker (if applicable). Fix any errors.

#### Step 5: Record results

For each task, record:
- Status (completed / failed / skipped)
- Files changed
- Tests added
- Spec compliance review result (passed / fixed)
- Code quality review result (passed / fixed)
- Any deviations from the plan

### Output
PhaseOutput with task_results list (status, files changed, reviews per task).

---

## Phase 8: Validate

Phase 8 uses the `acceptance-validation` base skill. This section adds the
verification discipline that ensures claims are backed by evidence.

### The Verification Gate

Before claiming any acceptance criterion passes:

1. **Identify** — what command or action proves this criterion is met?
2. **Run** — execute the full verification command (fresh, not cached)
3. **Read** — examine the complete output, check exit codes, count failures
4. **Confirm** — does the output actually prove the claim?
   - If NO: report actual status with evidence
   - If YES: report the claim with the evidence attached

**Never claim a test passes without running it in this session.**
**Never claim "all tests pass" without the full suite output.**

### What Each Claim Requires

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output showing 0 failures | Previous run, "should pass" |
| Linter clean | Linter output showing 0 errors | Partial check, extrapolation |
| Build succeeds | Build command with exit code 0 | Linter passing, "looks good" |
| Bug fixed | Original symptom verified as resolved | "Code changed, assumed fixed" |
| Requirements met | Line-by-line checklist verified | "Tests passing" alone |

### Red Flags — Stop and Verify

If you catch yourself using any of these patterns, stop and run the verification:
- "Should work now" → run the verification
- "I'm confident" → confidence is not evidence
- "Just this once" → no exceptions
- "Linter passed" → linter is not the compiler
- Expressing satisfaction before verification ("Great!", "Done!", "Perfect!")
- Using "probably", "seems to", "should" about test results

### Verification Sequence

```
1. Run full test suite — record output and exit code
2. Run linter/formatter — record any violations
3. Run type checker (if applicable) — record any errors
4. For each acceptance criterion:
   a. Map to specific test(s) or manual verification step
   b. Execute and record evidence
   c. Mark pass/fail with evidence reference
5. Summarize: N/M criteria verified, test suite status, known gaps
```

### Output
PhaseOutput with acceptance_criteria statuses, each backed by evidence.

---

## Phase 9: Ship

Phase 9 uses the `shipping` base skill. This section adds the structured
completion workflow.

### Pre-Ship Verification

Before creating the PR:

1. **Run the full test suite** — if any test fails, stop. Fix before proceeding.
2. **Check branch status** — confirm all changes are committed, no uncommitted files.
3. **Confirm base branch** — verify the target branch (usually `main` or `master`).

### Completion Options

Present these options to the human:

```
Implementation complete. Tests passing. What would you like to do?

1. Push and create a Pull Request
2. Merge back to <base-branch> locally
3. Keep the branch as-is (I'll handle it later)
4. Discard this work
```

#### Option 1: Push and Create PR
Follow the shipping base skill's PR template. Ensure the description includes:
- Link to the Jira ticket (if applicable)
- Summary of changes
- Acceptance criteria status (from Phase 8 validation report)
- Test evidence summary

#### Option 2: Merge Locally
```
git checkout <base-branch>
git pull
git merge <feature-branch>
# Run tests on merged result
git branch -d <feature-branch>
```

#### Option 3: Keep As-Is
Report branch name and location. No cleanup.

#### Option 4: Discard
Require explicit confirmation before deleting:
```
This will permanently delete branch <name> and all commits.
Type 'discard' to confirm.
```

### Post-Completion
1. Update Jira ticket status (if applicable)
2. Report the final status (PR URL, merge result, or branch name)

### Output
PhaseOutput with PR URL (or merge/keep/discard status), Jira transition, and summary.
