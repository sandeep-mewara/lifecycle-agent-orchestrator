---
name: acceptance-validation
description: >
  Validates implemented code against the acceptance criteria established during intake.
  Use this skill after implementation is complete to systematically verify each acceptance
  criterion, run the full test suite, and produce a validation report. Trigger when the
  orchestrator reaches the validation phase, or when the user asks to verify that an
  implementation meets the original requirements.
---

# Acceptance Validation

You systematically verify that implemented code meets every acceptance criterion from
the intake phase. You are the gate between "code is written" and "code is ready to ship."

---

## Process

### 1. Load Acceptance Criteria

Retrieve the acceptance criteria list from the intake phase output. Each AC has:
- `id`: AC1, AC2, etc.
- `text`: The criterion text
- `status`: Should be "pending" at this point

### 2. Verify Each Criterion

For each acceptance criterion, determine the best verification method and execute it:

**Verification methods (in order of preference):**

1. **Test output** — A specific test exists that validates this AC. Run the test and check it passes.
   - Search test files for test names or assertions that match the AC
   - Run the specific test(s) and capture output
   - Evidence: test name, pass/fail, relevant assertion

2. **Code inspection** — The AC can be verified by examining the code directly.
   - Read the relevant source files
   - Verify the implementation matches the criterion
   - Evidence: file path, line numbers, what was verified

3. **Runtime check** — The AC requires running the application or a script to verify.
   - Run the appropriate validation script or command
   - Capture and examine the output
   - Evidence: command run, output received, how it maps to the AC

4. **Manual verification** — The AC cannot be verified automatically (e.g., "UI looks correct").
   - Flag as requiring manual verification
   - Describe what the human should check
   - Evidence: "Requires manual verification — [what to check]"

### 3. Run Full Test Suite

After individual AC verification:
1. Run the project's full test suite
2. Capture: total tests, passed, failed, skipped
3. If any tests fail, report them with details

If the project has validation scripts (e.g., `scripts/validate_*.py`), run those too.

### 4. Produce Validation Report

Output format (see `references/validation-report-template.md`):

```
## Validation Report

### Acceptance Criteria Status
| AC | Criterion | Status | Method | Evidence |
|----|-----------|--------|--------|----------|
| AC1 | {text} | Pass | Test | test_name::test_method |
| AC2 | {text} | Pass | Code inspection | file.py:45-52 |
| AC3 | {text} | Fail | Test | test_name — AssertionError |

### Test Suite Results
- Total: {N}
- Passed: {N}
- Failed: {N}
- Skipped: {N}

### Overall Verdict
{PASS — all ACs met and tests passing / FAIL — [list what failed]}
```

---

## Handling Failures

If an acceptance criterion fails:
- Report exactly what failed and why
- Include the evidence (error message, assertion failure, unexpected output)
- Do NOT attempt to fix the code — that's the implementation phase's job
- If the failure suggests the AC itself is wrong (impossible to meet), flag it

If tests fail:
- Report the failing test names and error messages
- Distinguish between: tests related to current changes vs. pre-existing failures
- If pre-existing failures exist, note them separately

---

## Output

Produce a PhaseOutput per `contracts/phase-output-schema.md`:

- `phase_name`: "validate"
- `status`: "completed" (even if some ACs failed — the validation itself completed)
- `summary`: "{N}/{total} acceptance criteria passed. {test_count} tests passing."
- `acceptance_criteria`: Updated list with status changed from "pending" to "pass" or "fail", evidence populated
- `metadata`: {test_total, test_passed, test_failed, validation_scripts_run}
- `approval_needed`: true
- `next_phase`: "ship" (if all pass) or report failure for human decision
