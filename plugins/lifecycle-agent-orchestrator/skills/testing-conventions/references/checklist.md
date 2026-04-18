# Python Testing — Checklist

## When Writing Unit Tests

- [ ] File named `test_{module}.py` mirroring the source file path
- [ ] `@pytest.mark.asyncio` on all async test functions
- [ ] Each error type tested independently (not one big test)
- [ ] `AsyncMock` for async method mocking, `MagicMock` for sync
- [ ] `pytest.raises()` for exception assertion — check the message too
- [ ] Fixtures for repeated setup (mock requests, contexts, configs)
- [ ] No hardcoded secrets or real API keys in test code
- [ ] `monkeypatch` for simple overrides, `@patch` for module-level replacements
- [ ] Tests are independent — no ordering dependencies between tests
- [ ] Coverage for both success and error paths

## When Writing Integration Tests

- [ ] Session-scoped fixtures for expensive setup (app, TestClient, external clients)
- [ ] TestClient includes gateway auth headers (e.g., `X-Forwarded-Port`)
- [ ] Secrets and auth mocked before app creation
- [ ] `APP_ENV=local` patched in environment
- [ ] Cleanup in yield fixtures for clients that need shutdown
- [ ] Tests marked with `@pytest.mark.integration`

See PROJECT.md for the specific mock targets and fixture implementations.

## When Writing Agent Evaluation Tests

- [ ] Marked with `@pytest.mark.agent_evaluation` (excluded from regular pytest runs)
- [ ] Uses golden dataset for test cases (prompts + reference answers)
- [ ] Evaluation config JSON with judges, thresholds, and primary metric
- [ ] `record_property()` for CI metrics reporting (JUnit XML)
- [ ] Quality gate threshold configured (default 0.7)
- [ ] Test dataset has at minimum 5 prompts with reference answers
- [ ] Handles edge cases: no traces, no results, no scores → UNKNOWN status

See PROJECT.md for the specific evaluation platform, dataset, judges, and CI pipeline.

## Conftest Conventions

- [ ] Unit conftest: minimal — `anyio_backend` (autouse) + `settings` fixture
- [ ] Integration conftest: session-scoped — `app`, `client`, `settings`, external client fixtures
- [ ] Mock infrastructure (secrets, auth) before app creation in integration conftest
- [ ] No imports from `app.service` at module level in integration conftest (import inside fixture after patching)

## Tox & CI

- [ ] `tox.ini` has `lint` and Python version environments
- [ ] Regular pytest excludes agent_evaluation: `-m "not agent_evaluation"`
- [ ] Coverage reports: HTML + terminal + XML (`coverage/coverage.xml`)
- [ ] Lint checks: isort (black profile), black
- [ ] Agent eval runs separately in CI (see PROJECT.md for trigger conditions)
