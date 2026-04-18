---
name: python-standards
description: Enforces Python coding standards when writing or modifying Python code. Covers naming conventions (snake_case functions, PascalCase classes, UPPER_SNAKE_CASE constants), exception and error handling (typed exception hierarchies, centralized error handlers, structured logging), project structure (FastAPI + LangGraph + Poetry layout), code quality tooling (black, isort, mypy, pytest), environment-based configuration hierarchy, secrets management (environment variables or a vault client), request header propagation, LangGraph agent patterns, async-first design, graceful degradation, and PyPI packaging. Use this skill whenever writing Python code in your repository, creating new Python files or modules, defining classes or functions, adding error handling, setting up project scaffolding, building LangGraph agents or tools, configuring deployment, or reviewing Python code for standards compliance. Also use when the user asks about Python conventions for production services, starter patterns, or engineering best practices.
---

# Python Coding Standards

Standards drawn from production service patterns. The goal is consistency — any engineer should read any Python service in your repository and immediately understand the patterns.

**Bundled references** (read when you need detailed configs or complete code examples):
- `references/checklist.md` — Pre-commit and code review checklist
- `references/tooling-config.md` — Complete pyproject.toml, Dockerfile, CI/CD, environment settings hierarchy
- `references/examples.md` — Full code examples for every pattern below

## Naming Conventions

| What | Convention | Example |
|------|-----------|---------|
| Functions/methods | `snake_case`, verb-first | `get_order_data()`, `ainvoke_agent()`, `validate_request()` |
| Async variants | prefix with `a` | `ainvoke()` for async invoke |
| Private functions | single leading underscore | `_validate_request()` |
| Classes | `PascalCase` | `AgentContext`, `SvcSettings`, `AuthorizationError` |
| Exception classes | suffix `Error` or `Exception` | `AuthorizationError`, `AgentInvokeException` |
| Variables | `snake_case`, descriptive | `user_id` not `uid`, `thread_id` not `tid` |
| Booleans | prefix `is_`/`has_`/`enable_` | `enable_langfuse`, `is_authenticated` |
| Constants | `UPPER_SNAKE_CASE` | `AUTH_EXEMPT_ROUTES`, `ORDER_API_TIMEOUT` |
| Enum keys/values | `UPPER_SNAKE_CASE` / `snake_case` | `BAD_REQUEST = "bad_request"` |
| Files | `snake_case.py` | `agent_service.py`, `error_handling.py` |

## Exception and Error Handling

Three-layer pattern: **define typed exceptions → catch specific → centralized handlers**.

**1. Typed exception hierarchy** — never bare `raise Exception(...)`:

```python
from enum import StrEnum
from fastapi import HTTPException

class ErrorCode(StrEnum):
    """Machine-readable codes — snake_case, never opaque like 'err-1064'."""
    BAD_REQUEST = "bad_request"
    REQUEST_VALIDATION_ERROR = "request_validation_error"

class AuthorizationError(Exception): pass
class AgentInvokeException(Exception): pass
class ClientException(HTTPException): pass
```

**2. Catch specific first**, generic `Exception` last. Always log before re-raising:

```python
try:
    output = await request.app.state.graph.ainvoke({"messages": messages}, config=config)
except AuthenticationError as ex:
    logger.exception(f"Client Error: {ex}")
    raise AuthorizationError(ex)
except RateLimitError as ex:
    logger.exception(f"Client Error: {ex}")
    raise ClientException(ex.status_code, ex.message)
except Exception as ex:
    logger.exception(f"Unknown Error: {ex}")
    raise AgentInvokeException(ex)
```

**3. Centralized handlers** — all error-to-HTTP mappings in one place:

```python
def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AuthorizationError)
    async def handle_auth_error(request: Request, error: AuthorizationError):
        logger.warning(f"Rejecting request: {error}")
        return JSONResponse(content={"message": str(error)}, status_code=401)
```

**Engine-layer typed errors:** Define domain-specific error classes for each failure mode (e.g., calculator failures, validation failures, strategy failures). Each error type has a defined behavior: retry-then-degrade, log-and-skip, or fail-fast. See PROJECT.md for the service-specific error classification.

**Error propagation pattern:**
- Engine raises typed error
- Tool boundary catches, logs full detail, returns user-safe summary
- Agent surfaces conversationally — never exposes stack traces, internal field names, or computation details

**Error tracking conventions:**
- Track errors that affect users or reliability (retries exhausted, module load failures, auth failures)
- Don't track expected/handled conditions (successful retries, "not applicable" results, cache misses)
- Context on every tracked error: `transaction_id`, `error_type`, relevant identifiers, stack trace. No PII.
- Severity: **P1** (pages on-call) for infrastructure-wide failures, **P2** (creates ticket) for isolated errors
- Tool selection (Sentry/Datadog) is pending — these conventions apply regardless

## Structured Logging

**Standard: `structlog` with JSON output.**

- Production: `JSONRenderer()` for machine-parseable output (Splunk/Datadog can parse)
- Local dev: `ConsoleRenderer()` for human-readable output with colors
- Environment-based renderer selection via `configure_logger()`

**Log level decision matrix:**

| Level | When | Examples |
|---|---|---|
| `ERROR` | Unrecoverable failure needing attention | Cycle in dependencies, unrecoverable external call failure |
| `WARNING` | Degraded but continuing | Validation failed (retrying), resource not found (creating new) |
| `INFO` | Operational lifecycle event | Component registered, state saved, app startup |
| `DEBUG` | Detailed tracing (local dev only) | Truncated snippets, check values — **never** full request/response content in staging/production (see Security skill §7) |

**Context binding:** Use `structlog.contextvars.bind_contextvars()` at service entry points to inject correlation fields (`transaction_id` at minimum). See PROJECT.md for the service-specific required context fields.

**No PII in logs.** Log identifiers, never values. See **Security skill** for the full allowlist and sensitive field inventory.

## Tracing

LLM tracing tool (Langfuse) provides observability over prompt/completion pairs, token usage, and agent execution paths. It is **not** an error tracking tool.

- Trace ID correlates with `transaction_id` from the middleware
- Spans follow the request lifecycle hierarchy
- No PII or sensitive data content in traces — identifiers only
- Errors need a separate aggregation tool (see Error Tracking Conventions above)

See PROJECT.md for the service-specific span hierarchy and tracing details.

## Project Structure

```
app/
    service/
        __init__.py            # App init, lifespan, middleware
        server.py              # FastAPI app factory
        auth.py                # Auth middleware, route allowlisting
        agent_service.py       # ainvoke_agent() entry point
        error_handling.py      # Exceptions + centralized handlers
        agent/
            agent.py           # LangGraph StateGraph
            tools/             # BaseTool subclasses
    models/
        agent_context.py       # Pydantic domain models
        agent_headers.py       # RequestHeaders with Annotated validators
        agent_request.py       # AgentInput, ContentItem
    adapters/                  # External service clients
    evaluation/                # Eval 2.0 (same container)
    utils/
        secrets_utils.py       # Secrets (env vars or vault client; lazy cache)
common/
    common_config.py           # Settings hierarchy + settings_factory()
    identity/                  # AuthzClient, identity exceptions
    logging_helper.py          # ContextVar-based logging
test/
    unit/                      # pytest, minimal fixtures
    integration/               # Mocked secrets manager, AuthZ, TestClient
pyproject.toml                 # See references/tooling-config.md
Dockerfile                     # See references/tooling-config.md
ci.yml                         # CI pipeline definition
```

## Configuration: Environment-Based Settings

Environment-based settings hierarchy — settings adapt per deployment stage:

```python
class SvcSettings(BaseSettings):          # Base — all environments
class PreProdSettings(SvcSettings):       # Pre-production defaults
class LocalSettings(PreProdSettings):     # Local dev
class CISettings(PreProdSettings):        # CI
class ProdSettings(SvcSettings):          # Production

ENV_SETTINGS_MAP = {"local": LocalSettings, "ci": CISettings, "staging": PreProdSettings, "production": ProdSettings}

@lru_cache(maxsize=1)
def settings_factory() -> SvcSettings:
    env = os.getenv("APP_ENV", "local")
    return ENV_SETTINGS_MAP.get(env, LocalSettings)()
```

See `references/tooling-config.md` for the full implementation.

## Secrets Management

Never hardcode secrets. Store references (env var names, vault paths, or KMS keys) in settings; resolve values at runtime:

```python
# Config: langfuse_public_key_env: str = "LANGFUSE_PUBLIC_KEY"
# Runtime: actual_key = get_secret(settings.langfuse_public_key_env)
```

Use a small module-level cache or lazy singleton. Pre-warm during startup where it improves cold-path latency. For security policy and secret-handling conventions, see the **Security skill** (`skills/security/`).

## App Initialization & Lifecycle

Key principle: **optional features fail softly without crashing startup**.

```python
async def on_startup(app):
    app.state.config = settings_factory()
    app.state.async_exit_stack = AsyncExitStack()

    try:  # Graceful degradation
        app.state.authz_client = await app.state.async_exit_stack.enter_async_context(
            make_authz_client(app.state.config))
    except Exception:
        logger.exception("AuthZ init failed — continuing without it")
        app.state.authz_client = None

    app.state.graph = await initialize_agent(app.state.config)
```

## Request Header Propagation

**Transaction ID middleware** — every request propagates `transaction_id`:

```python
@app.middleware("http")
async def inject_transaction_id(request: Request, call_next):
    transaction_id = request.headers.get("transaction_id", str(uuid.uuid4()))
    request.state.transaction_id = transaction_id
    response = await call_next(request)
    response.headers["transaction_id"] = transaction_id
    return response
```

**Header validation** — use `Annotated` with `AfterValidator`:

```python
UserId = Annotated[str, AfterValidator(validate_positive_integer_id)]
AuthToken = Annotated[str, AfterValidator(validate_auth_token)]

class AuthContext(BaseModel):
    user_id: UserId
    auth_token: AuthToken
```

## LangGraph Agent Patterns

```python
# StateGraph with assistant + tools nodes
graph_builder = StateGraph(MessagesState)
graph_builder.add_node("assistant", assistant_node)
graph_builder.add_node("tools", ToolNode(tools=tools_list))
graph_builder.add_edge(START, "assistant")
graph_builder.add_conditional_edges("assistant", tools_condition)
graph_builder.add_edge("tools", "assistant")
graph = graph_builder.compile(checkpointer=checkpointer)  # MemorySaver local, AsyncRedisSaver prod
```

**RunnableConfig** enriched with context, Langfuse callbacks, and metadata (`thread_id`, `transaction_id`, `langfuse_user_id`).

**Tools** extend `BaseTool`, access context via `config["configurable"]["agent_context"]`. Loaded dynamically from config via `create_instance(globals(), tool_name)`.

## Async Patterns

**Singleton with Lock** for shared HTTP sessions:

```python
class ExternalHttpClient:
    session: Optional[aiohttp.ClientSession] = None
    _lock: asyncio.Lock = asyncio.Lock()

    @classmethod
    async def get_session(cls) -> aiohttp.ClientSession:
        async with cls._lock:
            if cls.session is None:
                cls.session = aiohttp.ClientSession(timeout=...)
            return cls.session
```

**ContextVar logging** for per-request context — see `references/examples.md`.

## Code Quality Tooling

All configured in `pyproject.toml` (see `references/tooling-config.md` for complete config):

| Tool | Key Config |
|------|-----------|
| **Python** | `>=3.11,<3.13` |
| **Poetry source** | PyPI as primary (`https://pypi.org/simple/`) |
| **black** | `line-length = 88`, `target-version = ['py312']` |
| **isort** | `profile = "black"` |
| **mypy** | `check_untyped_defs = true`, `plugins = ["pydantic.mypy"]` |
| **pytest** | markers: `unit`, `integration`, `agent_evaluation` |
| **Dep groups** | `api`, `agentic`, `evaluation`, `dev`, `test` |

Always commit `poetry.lock`. Imports organized: stdlib → third-party → internal.

---

Before committing or reviewing, consult `references/checklist.md` for the full verification checklist.
