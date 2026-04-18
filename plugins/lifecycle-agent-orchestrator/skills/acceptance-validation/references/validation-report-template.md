# Validation Report Template

Use this template when producing the validation phase output.

---

## Validation Report

**Ticket:** {PROJ-XXXX}
**Date:** {YYYY-MM-DD}
**Implementation branch:** {branch_name}

### Acceptance Criteria Status

| AC | Criterion | Status | Verification Method | Evidence |
|----|-----------|--------|-------------------|----------|
| AC1 | {text} | Pass / Fail | Test / Code Inspection / Runtime / Manual | {details} |

### Test Suite Results

| Metric | Value |
|--------|-------|
| Total tests | {N} |
| Passed | {N} |
| Failed | {N} |
| Skipped | {N} |
| Coverage | {N%} (if available) |

**Failed tests (if any):**
- `{test_path}::{test_name}` — {error message}

### Validation Scripts

| Script | Status | Notes |
|--------|--------|-------|
| {script_name} | Pass / Fail | {brief output} |

### Overall Verdict

**{PASS / FAIL}**

{If PASS: "All acceptance criteria met. Full test suite passing. Ready for shipping."}
{If FAIL: "The following items need resolution before shipping: [list]"}
