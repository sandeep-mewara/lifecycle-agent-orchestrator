# Testing Standards — Universal Checklist

## When Writing Unit Tests

- [ ] Test file mirrors the source file path and naming convention
- [ ] Each error type tested independently (not one big test)
- [ ] Appropriate async mocks used for async method testing
- [ ] Fixtures for repeated setup (mock requests, contexts, configs)
- [ ] No hardcoded secrets or real API keys in test code
- [ ] Tests are independent — no ordering dependencies between tests
- [ ] Coverage for both success and error paths
- [ ] Test names describe scenarios: `<method>_<scenario>_<expected>`

## When Writing Integration Tests

- [ ] Session/class-scoped fixtures for expensive setup (app, client)
- [ ] External infrastructure mocked before app creation
- [ ] Test client includes necessary auth headers
- [ ] Cleanup in teardown for clients that need shutdown
- [ ] Tests marked with integration category/marker

## When Writing Agent Evaluation Tests

- [ ] Marked with agent evaluation category (excluded from regular test runs)
- [ ] Uses golden dataset for test cases (prompts + reference answers)
- [ ] Evaluation config JSON with judges, thresholds, and primary metric
- [ ] Quality gate threshold configured (default 0.7)
- [ ] Test dataset has at minimum 5 prompts with reference answers
- [ ] Handles edge cases: no traces, no results, no scores

## General Test Quality

- [ ] Tests verify behavior, not just execution — assertions are meaningful
- [ ] Mocks at boundaries only (external services, databases) — not internal logic
- [ ] One mock assertion per concept — verify behavior, not call counts
- [ ] Line coverage >=85% for new code
- [ ] No test interdependency — each test can run in isolation
