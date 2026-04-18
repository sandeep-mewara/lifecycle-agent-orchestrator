# Python Standards — Checklist

Use this checklist when writing new code, reviewing PRs, or setting up new projects.

## When Writing or Modifying Code

### Naming
- [ ] Functions and methods use `snake_case` with descriptive verb-first names (`get_`, `check_`, `build_`, `create_`)
- [ ] Async variants prefixed with `a` (e.g., `ainvoke_agent`)
- [ ] Private/internal functions use single leading underscore (`_helper_method`)
- [ ] Classes use `PascalCase`
- [ ] Exception classes suffixed with `Error` or `Exception` (`AuthorizationError`, `AgentInvokeException`)
- [ ] Variables use `snake_case` — descriptive names (`user_id` not `uid`)
- [ ] Booleans prefixed with `is_`, `has_`, `enable_`
- [ ] Constants use `UPPER_SNAKE_CASE`
- [ ] Enum keys `UPPER_SNAKE_CASE`, values `snake_case`
- [ ] Filenames use `snake_case.py` — no hyphens

### Error Handling
- [ ] Domain-specific typed exception classes — no bare `raise Exception(...)`
- [ ] `ErrorCode(StrEnum)` with machine-readable `snake_case` values — never opaque codes like `err-1064`
- [ ] `register_error_handlers(app)` centralizes all exception-to-HTTP mappings
- [ ] `except` blocks catch specific exceptions first, generic `Exception` last as safety net
- [ ] Always log before re-raising exceptions
- [ ] `raise ... from ex` to preserve exception chains
- [ ] Engine-layer uses typed errors (`CalculatorError`, `ValidationError`, `StrategyError`, `ExtractionError`) — not bare `Exception`
- [ ] Calculator validation failures → retry once → degrade confidence (never crash)
- [ ] Promotion failures → log and skip → continue with remaining promotions
- [ ] Tool boundary: catch engine errors → log detail → return user-safe message to agent
- [ ] Tracked errors carry `transaction_id`, `error_type`, `order_id`, `customer_id` — no PII

### Structured Logging
- [ ] `structlog` as the standard; `JSONRenderer` in production, `ConsoleRenderer` in local dev
- [ ] `logger.exception()` inside `except` blocks (auto-includes traceback)
- [ ] `logger.warning()` in error handlers (expected/handled conditions)
- [ ] `logger.info()` for operational lifecycle events
- [ ] `logger.debug()` for detailed computation tracing
- [ ] No `print()` in production code
- [ ] `bind_contextvars()` at engine entry points with `order_id`, `order_year`
- [ ] Log at operation boundaries: entry/exit of `engine.analyze()`, each promotion, each calculator call
- [ ] Langfuse `trace_id` included in structured context when available
- [ ] No PII in log messages — see **Security skill** for the allowlist

### Data Models
- [ ] Pydantic `BaseModel` for all data classes — not `@dataclass`
- [ ] `Field(default_factory=...)` for mutable defaults
- [ ] Type hints on all function signatures
- [ ] `Annotated[str, AfterValidator()]` for inbound header / token validation

### Imports
- [ ] Three groups separated by blank lines: stdlib → third-party → internal
- [ ] `isort` with `black` profile enforces this automatically

## When Setting Up a New Project

### Configuration
- [ ] Environment-based settings hierarchy: `SvcSettings` → `PreProdSettings` / `ProdSettings`
- [ ] `ENV_SETTINGS_MAP` dict mapping `APP_ENV` values to settings classes
- [ ] `settings_factory()` with `@lru_cache(maxsize=1)` — returns singleton per environment
- [ ] Secrets resolved via environment variables or a vault/secrets-manager client — never committed to source control
- [ ] Never hardcode secrets — use env vars, secret references, or runtime injection from your platform

### Project Structure
- [ ] `app/service/` — server.py, config.py, auth.py, agent_service.py, error_handling.py
- [ ] `app/models/` — agent_context.py, agent_headers.py, agent_request.py
- [ ] `app/adapters/` — external service clients
- [ ] `app/evaluation/` — Eval 2.0 logic (same container as serving)
- [ ] `app/utils/` — secrets_utils.py, auth_utils.py
- [ ] `common/` — common_config.py, identity/, logging_helper.py
- [ ] `test/unit/` and `test/integration/`
- [ ] `scripts/`, `package/` (entry.sh, nginx.conf)

### Tooling (pyproject.toml)
- [ ] Python `>=3.11,<3.13`
- [ ] PyPI (or your private package registry) as primary Poetry source
- [ ] `[tool.black]` line-length = 88, target-version py312
- [ ] `[tool.isort]` profile = "black"
- [ ] `[tool.mypy]` with `pydantic.mypy` plugin, `check_untyped_defs = true`
- [ ] `[tool.pytest.ini_options]` with markers: unit, integration, agent_evaluation
- [ ] Dependency groups: `api`, `agentic`, `evaluation`, `dev`, `test`
- [ ] Commit `poetry.lock`

### App Initialization
- [ ] `AsyncExitStack` for resource lifecycle management
- [ ] Graceful degradation — optional features (AuthZ, Langfuse, optional upstream clients) fail without crashing startup
- [ ] `transaction_id` middleware propagates correlation ID through request lifecycle
- [ ] LangGraph graph compiled and attached to `app.state.graph`

### LangGraph Agent
- [ ] `StateGraph(MessagesState)` with assistant and tools nodes
- [ ] `RunnableConfig` enriched with `agent_context`, `thread_id`, Langfuse metadata
- [ ] Tools extend `BaseTool`, access context via `config["configurable"]["agent_context"]`
- [ ] Checkpoint saver: `MemorySaver` (local) / `AsyncRedisSaver` (prod)
