---
name: testing-conventions
description: Enforces testing standards when writing unit tests, integration tests, or agent evaluation tests. Covers test directory structure, naming conventions, fixture and setup patterns, mocking strategy, async testing, coverage requirements, and LLM-as-judge evaluation. Language-specific conventions (Python/pytest, Java/JUnit, C#/xUnit, React/Vitest) are loaded from bundled reference packs. Use this skill when writing tests, creating test files, setting up fixtures, mocking services, or reviewing test code for standards compliance.
---

# Testing Standards

Standards for testing across your services. Tests follow a layered strategy: fast unit tests for isolated logic, integration tests for service interactions, and agent evaluation tests for LLM quality gates in CI/CD.

**Bundled references** (read when you need the checklist):
- `references/checklist.md` — Universal test review checklist
- `references/<language>/checklist.md` — Language-specific test checklist

Where `<language>` is `python`, `java`, `csharp`, or `react` — determined by the project's `lao.config.yaml` or auto-detected at pipeline start. Multi-language projects load all detected packs; apply each to files of its language.

See PROJECT.md for service-specific test directory structure, test commands, evaluation dataset details, and CI pipeline integration.

---

## Test Directory Structure

Tests mirror the source layout and are separated by type:

```
test/ (or tests/)
    unit/
        <module_dirs>/           # Mirror source directory structure
            test_<module>.*      # One test file per source module
    integration/
        test_<feature>.*         # Feature-level integration tests
```

**Key rules:**
- File naming mirrors the source file it tests
- Directory structure mirrors the source tree
- Unit tests and integration tests in separate directories
- Test configuration specifies default test path (usually unit tests)

---

## Test Markers / Categories

Three categories drive the test pyramid:

| Category | Purpose | Speed | External Deps |
|---|---|---|---|
| **Unit** | Isolated logic, no external dependencies | Fast (ms) | None |
| **Integration** | Service interactions, mocked infrastructure | Medium (s) | Mocked or containerized |
| **Agent Evaluation** | LLM-based quality assessment | Slow (min) | LLM API access |

Agent evaluation tests are excluded from regular test runs and execute separately in CI.

See `references/<language>/checklist.md` for how to mark tests in your language's framework.

---

## Fixture and Setup Conventions

### Unit test fixtures — minimal, no external deps

- Create minimal configuration with external integrations disabled
- Fixtures provide pre-built objects (mock requests, contexts, configs)
- Each test is independent — no ordering dependencies between tests

### Integration test fixtures — session-scoped, richer setup

- Expensive setup (app creation, client initialization) happens once per test session
- Infrastructure (secrets, auth) mocked before app creation
- Cleanup via teardown hooks for clients that need shutdown

See PROJECT.md for specific fixture implementations and mock targets.

---

## Unit Test Patterns

### Async testing

- Use the language's async test support for testing async/await code
- Mock async method calls appropriately (async mocks, not sync mocks)
- Verify async error propagation paths

### Error mapping tests

Each external error type gets its own test verifying it maps to the correct domain exception. Don't combine multiple error types into one test.

### Mocking strategy

- **Mock at boundaries** — external services, databases, third-party APIs
- **Don't mock internal logic** — if you need to mock the function you're testing, the design needs refactoring
- **Prefer fakes over mocks** for complex dependencies (in-memory database, fake HTTP server)
- **One mock assertion per concept** — don't verify every method call, verify the behavior you care about

### Test naming

Tests describe the scenario, not the implementation:

```
Good: test_report_generation_fails_when_data_missing
      createOrder_emptyItems_throwsBadRequest
      ProcessOrderAsync_ValidRequest_ReturnsOrderWithId

Bad:  test_report_1
      testMethod3
      Test1
```

Pattern: `<method>_<scenario>_<expected result>`

---

## Integration Test Patterns

### API endpoint testing

- Start the application in test mode with mocked external dependencies
- Send real HTTP requests through the test client
- Verify response status codes, body structure, and headers
- Test both success and error paths

### Auth testing

- Verify that authenticated endpoints reject unauthenticated requests
- Verify that authorization scoping works (user A can't access user B's data)
- Test the gateway/middleware auth flow, not just the endpoint logic

---

## Agent Evaluation Testing

LLM-as-a-judge evaluation integrated into CI/CD. This is a standard pattern for measuring agent quality.

### How it works

1. **Golden dataset** — test cases with prompts and reference answers
2. **Agent invocation** — run the agent against each test case
3. **Multi-judge evaluation** — LLM judges score responses on configurable dimensions (correctness, hallucination, tool usage)
4. **Quality gates** — pass/fail based on configurable thresholds
5. **Metrics reporting** — results published for tracking over time

### Evaluation config

```json
{
  "dataset_name": "agent-golden-dataset",
  "agent_name": "my-agent",
  "eval_mode": "offline",
  "judges": [
    {"type": "llm", "name": "correctness", "prompt": "CORRECTNESS_PROMPT", "threshold": 0.7},
    {"type": "llm", "name": "hallucination", "prompt": "HALLUCINATION_PROMPT", "threshold": 0.8},
    {"type": "code", "name": "tool_call", "function": "tool_call_evaluator"}
  ],
  "primary_metric": "WEIGHTED_AVG",
  "pm_quality_acceptance_threshold": 0.7
}
```

### Test dataset format

```csv
prompt,reference,tools_called
"What is the product?","The product is...","[]"
"How do I perform action X?","Go to Settings > Action X","[""knowledge_retriever""]"
```

See PROJECT.md for the specific dataset, judges, thresholds, and CI pipeline integration for agent evaluation.

---

## Coverage Requirements

- **Line coverage:** >=85% for new code
- **Branch coverage:** measured and reported alongside line coverage
- **Coverage is not a goal in itself** — test quality matters more than coverage percentage
- Tests should verify behavior, not just execute code paths
- Assertions must be meaningful — not just "it didn't crash"

---

Before committing tests, consult `references/checklist.md` and `references/<language>/checklist.md` for the verification checklist.
