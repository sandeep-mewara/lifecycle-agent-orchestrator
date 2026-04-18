---
name: python-testing
description: >
  Enforces Python testing standards when writing unit tests, integration tests, or agent evaluation
  tests. Covers pytest patterns (fixtures, markers, async testing, mocking), test directory structure
  mirroring source layout, conftest.py conventions (unit vs integration scoping), FastAPI TestClient
  setup with gateway auth headers, agent evaluation with LLM-as-judge scoring, tox configuration,
  and coverage reporting. Use this skill when writing Python tests, creating test files, setting up
  pytest fixtures, mocking services, testing FastAPI endpoints, writing agent evaluation tests,
  configuring tox or pytest, or reviewing test code for standards compliance.
---

# Python Testing Standards

Standards for Python testing across your services. Tests follow a layered strategy: fast unit tests for isolated logic, integration tests for service interactions, and agent evaluation tests for LLM quality gates in CI/CD.

**Bundled references** (read when you need the checklist):
- `references/checklist.md` — Test review checklist

See PROJECT.md for the service-specific test directory structure, test commands, evaluation dataset details, tox configuration, and CI pipeline integration.

---

## Test Directory Structure

Tests mirror the source layout and live under `test/` (or `app/test/`):

```
test/
    unit/
        conftest.py              # Minimal fixtures (settings, anyio_backend)
        <module_dirs>/           # Mirror source directory structure
            test_<module>.py
    integration/
        conftest.py              # Richer: TestClient, eval config, session-scoped
        test_<feature>.py
```

Key rules:
- File naming: `test_{module_name}.py` — mirrors the source file it tests
- Directory structure mirrors the source tree — e.g., `app/service/my_service.py` → `test/unit/service/test_my_service.py`
- Unit tests in `test/unit/`, integration tests in `test/integration/`
- `testpaths` in `pyproject.toml` should default to unit tests

---

## Pytest Configuration

```toml
[tool.pytest.ini_options]
markers = [
    "integration: mark a test as an integration test.",
    "unit: mark a test as a unit test.",
    "agent_evaluation: mark a test for agent evaluation during CI/CD.",
]
pythonpath = [".", "app"]
testpaths = ["test/unit"]
```

Three markers drive the test pyramid:
- `@pytest.mark.unit` — fast, isolated, no external dependencies
- `@pytest.mark.integration` — needs running services or mocked infrastructure
- `@pytest.mark.agent_evaluation` — LLM-based evaluation, excluded from regular runs (`-m "not agent_evaluation"`)

See PROJECT.md for any additional project-specific markers.

---

## Conftest Conventions

### Unit conftest — minimal, no external deps

```python
# test/unit/conftest.py
import pytest

@pytest.fixture(autouse=True)
def anyio_backend():
    return "asyncio"

@pytest.fixture
def settings():
    """Minimal config — metrics disabled, no external service connections."""
    return ServiceSettings(expose_metrics=False)
```

- `anyio_backend` is autouse — every test gets async support
- Settings fixture creates a minimal config with external integrations disabled

### Integration conftest — session-scoped, richer fixtures

```python
# test/integration/conftest.py
@pytest.fixture(scope="session")
def settings():
    return ServiceSettings(expose_metrics=False)

@pytest.fixture(scope="session")
def app(settings, mock_secrets, mock_authz):
    with patch.dict("os.environ", {"APP_ENV": "local"}):
        from app.service import create_app
        return create_app()

@pytest.fixture(scope="session")
def client(app, settings):
    return TestClient(app, headers={"X-Forwarded-Port": str(settings.gateway_port)})
```

Key differences from unit:
- **Session-scoped** — expensive setup (app creation, external clients) happens once
- **Gateway auth headers** — TestClient includes `X-Forwarded-Port` to pass gateway auth
- **Mocked infrastructure** — secrets and auth mocked before app creation
- **Cleanup** — use `yield` fixtures for clients that need shutdown (e.g., `client.shutdown()`)

See PROJECT.md for the specific fixture implementations and mock targets.

---

## Unit Test Patterns

### Async testing with pytest-asyncio

```python
@pytest.mark.asyncio
async def test_invoke_success(mock_request, mock_context):
    mock_request.app.state.graph.ainvoke = AsyncMock(
        return_value={"messages": [MagicMock(content="test response")]}
    )
    content, trace_id = await invoke_agent(mock_request, mock_context)
    assert content == "test response"
```

### Error mapping tests — test each exception type independently

```python
@pytest.mark.asyncio
async def test_auth_error_mapping(mock_request, mock_context):
    mock_request.app.state.graph.ainvoke.side_effect = AuthenticationError("bad key")
    with pytest.raises(AuthorizationError):
        await invoke_agent(mock_request, mock_context)

@pytest.mark.asyncio
async def test_rate_limit_mapping(mock_request, mock_context):
    mock_request.app.state.graph.ainvoke.side_effect = RateLimitError("throttled")
    with pytest.raises(ClientException):
        await invoke_agent(mock_request, mock_context)
```

Each external error type gets its own test verifying it maps to the correct domain exception.

### Mocking patterns

**`@patch` for module-level replacements:**
```python
@patch("app.service.agent.agent.ChatOpenAI")
@patch("app.service.agent.agent.ToolNode")
async def test_agent_init(mock_tool_node, mock_chat, mock_config):
    ...
```

**`monkeypatch` for simpler overrides:**
```python
def test_retriever(monkeypatch):
    monkeypatch.setattr(api_module, "retrieve", lambda q: [{"title": "doc1"}])
    result = tool._run(query="test")
    assert "doc1" in result
```

**`patch.object` for class methods:**
```python
with patch.object(CacheClient, "get_session", return_value=mock_session):
    history = await CacheClient.fetch_history("thread-1", headers)
```

### Authorization/access control tests

```python
def test_external_user_blocked(mock_external_request, agent_request):
    with pytest.raises(AuthorizationError) as exc_info:
        await handle_request(mock_external_request, agent_request)
    assert "restricted to internal users" in str(exc_info.value)

def test_internal_user_allowed(mock_internal_request, agent_request):
    await handle_request(mock_internal_request, agent_request)
```

### Fixture pattern — mock request objects as inner classes

```python
@pytest.fixture
def mock_request():
    class MockRequest:
        class state:
            config = ServiceSettings()
        headers = {"x-request-id": "test-123", "X-Forwarded-Port": "443"}
    return MockRequest()
```

---

## Integration Test Patterns

### FastAPI TestClient with gateway auth

```python
def test_health_check(client):
    response = client.get("/health/full")
    assert response.status_code == 200
    assert response.json() == {"status": "Healthy"}

def test_invoke_endpoint(client, request_payload):
    response = client.post("/v1/invoke", json=request_payload)
    assert response.status_code == 200
```

### Testing docs disabled in production

```python
def test_docs_disabled_in_prod(prod_app):
    client = TestClient(prod_app)
    response = client.get("/docs")
    assert response.status_code == 404
```

---

## Agent Evaluation Testing

LLM-as-a-judge evaluation integrated into CI/CD. This is a standard pattern for measuring agent quality.

### How it works

1. **Golden dataset** — test cases with prompts and reference answers (stored in observability platform)
2. **Agent invocation** — run the agent against each test case
3. **Multi-judge evaluation** — LLM judges score responses on configurable dimensions (correctness, hallucination, tool usage)
4. **Quality gates** — pass/fail based on configurable thresholds
5. **Metrics reporting** — results published to artifact logging system for tracking over time

### Agent evaluation test

```python
@pytest.mark.agent_evaluation
def test_multi_judge_eval(record_property, eval_client, agent_task, eval_config):
    result, run_metadata = run_offline_evaluation(
        eval_client=eval_client,
        agent_task=agent_task,
        eval_config=eval_config,
        max_concurrency=5,
    )
    record_property("pass_rate", result.pass_rate)
    record_property("overall_status", "PASS" if result.passed else "FAIL")
```

### Evaluation config (JSON)

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

## Tox Configuration

```ini
[tox]
envlist = lint, python3

[testenv]
passenv = APP_ENV, AWS_*
commands_pre = {env:POETRY} install
commands = {env:POETRY} run pytest --color=yes --cov --cov-report html --cov-report term --cov-report xml:coverage/coverage.xml -m "not agent_evaluation"

[testenv:lint]
commands =
    {env:POETRY} run isort --profile black --check-only --df .
    {env:POETRY} run black --check --diff .
```

Key: regular `pytest` run excludes `agent_evaluation` tests. Those run separately in the CI evaluation stage. See PROJECT.md for exact Python version, additional passenv, and CI integration details.

---

## Test Dependencies

Standard test dependencies for Python services:

```toml
[tool.poetry.group.test.dependencies]
pytest = ">=8.3"
pytest-mock = "*"
pytest-cov = ">=6.0"
pytest-xdist = ">=3.6"         # Parallel execution
pytest-asyncio = ">=0.14"
pytest-json-report = "^1.5"    # JSON reporting for CI
httpx = "*"                     # FastAPI TestClient
tox = "^4.24"
```

See PROJECT.md for the exact pinned versions used in the service.

---

Before committing tests, consult `references/checklist.md` for the verification checklist.
