# Python Standards — Detailed Examples

## Table of Contents
1. [Environment-Based Configuration](#environment-based-configuration)
2. [App Initialization with Lifespan](#app-initialization-with-lifespan)
3. [Exception Hierarchy and Handlers](#exception-hierarchy-and-handlers)
4. [Secrets Management](#secrets-management)
5. [Request Header Models with Validators](#request-header-models-with-validators)
6. [Agent Context Construction](#agent-context-construction)
7. [LangGraph Agent Definition](#langgraph-agent-definition)
8. [Adapter Pattern (Async Singleton)](#adapter-pattern-async-singleton)
9. [ContextVar Logging](#contextvar-logging)
10. [Transaction ID Middleware](#transaction-id-middleware)
11. [Structured Logging with structlog](#structured-logging-with-structlog)
12. [Engine-Layer Error Patterns](#engine-layer-error-patterns)
13. [Error Tracking Integration](#error-tracking-integration)
14. [Tool Definition Pattern](#tool-definition-pattern)
15. [Test Patterns](#test-patterns)
16. [pyproject.toml Complete Example](#pyprojecttoml-complete-example)
17. [Dockerfile Multi-Stage Build](#dockerfile-multi-stage-build)

---

## Environment-Based Configuration

The full settings hierarchy from `common/common_config.py`:

```python
import os
import logging
from functools import lru_cache
from pydantic_settings import BaseSettings

logger = logging.getLogger(__name__)


class SvcSettings(BaseSettings):
    """Base settings shared across all environments."""

    app_name: str = "my-service"
    app_id: str = ""
    app_secret: str = ""  # Reference only — load from env or secrets manager

    # Server
    host: str = "0.0.0.0"
    port: int = 8080
    gateway_port: int = 443

    # Langfuse
    enable_langfuse: bool = False
    langfuse_host: str = ""
    langfuse_public_key: str = ""  # e.g. from LANGFUSE_PUBLIC_KEY
    langfuse_secret_key: str = ""  # e.g. from LANGFUSE_SECRET_KEY

    # LLM
    llm_base_url: str = ""
    llm_model_id: str = ""


class PreProdSettings(SvcSettings):
    """Shared pre-production defaults."""
    enable_langfuse: bool = True
    llm_base_url: str = "https://llm-api-preprod.example.com"


class LocalSettings(PreProdSettings):
    """Local dev — hot-reload, relaxed auth."""
    pass


class CISettings(PreProdSettings):
    """CI pipeline."""
    pass


class ProdSettings(SvcSettings):
    """Production base."""
    enable_langfuse: bool = True
    llm_base_url: str = "https://llm-api-prod.example.com"


ENV_SETTINGS_MAP = {
    "local": LocalSettings,
    "ci": CISettings,
    "staging": PreProdSettings,
    "production": ProdSettings,
}


@lru_cache(maxsize=1)
def settings_factory() -> SvcSettings:
    env = os.getenv("APP_ENV", "local")
    settings_class = ENV_SETTINGS_MAP.get(env, LocalSettings)
    return settings_class()
```

## App Initialization with Lifespan

```python
# app/service/__init__.py
import logging
import uuid
from contextlib import AsyncExitStack, asynccontextmanager

from fastapi import FastAPI, Request
from starlette.responses import Response

from app.service.agent.agent import initialize_agent
from app.service.error_handling import register_error_handlers
from common.common_config import settings_factory

logger = logging.getLogger(__name__)


async def on_startup(app: FastAPI) -> None:
    app.state.config = settings_factory()
    app.state.async_exit_stack = AsyncExitStack()

    # Graceful degradation: optional features don't crash startup
    try:
        app.state.authz_client = await app.state.async_exit_stack.enter_async_context(
            make_authz_client(app.state.config)
        )
    except Exception:
        logger.exception("AuthZ client init failed — continuing without it")
        app.state.authz_client = None

    # Initialize LangGraph agent
    app.state.graph = await initialize_agent(app.state.config)


async def on_shutdown(app: FastAPI) -> None:
    await app.state.async_exit_stack.aclose()


def create_app() -> FastAPI:
    app = FastAPI(title="My Service")
    register_error_handlers(app)

    @app.middleware("http")
    async def inject_transaction_id(request: Request, call_next) -> Response:
        transaction_id = request.headers.get("transaction_id", str(uuid.uuid4()))
        request.state.transaction_id = transaction_id
        response = await call_next(request)
        response.headers["transaction_id"] = transaction_id
        return response

    return app
```

## Exception Hierarchy and Handlers

```python
# app/service/error_handling.py
import logging
from enum import StrEnum

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)


class ErrorCode(StrEnum):
    BAD_REQUEST = "bad_request"
    REQUEST_VALIDATION_ERROR = "request_validation_error"
    UNAUTHORIZED = "unauthorized"
    RATE_LIMITED = "rate_limited"
    UPSTREAM_TIMEOUT = "upstream_timeout"
    AGENT_INVOKE_ERROR = "agent_invoke_error"
    INTERNAL_ERROR = "internal_error"


class AuthorizationError(Exception):
    pass

class AgentInvokeException(Exception):
    pass

class PartnerApiError(Exception):
    pass

class UpstreamServiceException(Exception):
    pass

class ClientException(HTTPException):
    pass


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AuthorizationError)
    async def handle_authorization_error(request: Request, error: AuthorizationError):
        logger.warning(f"Rejecting request: {str(error)}")
        return JSONResponse(
            content={"message": str(error)},
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    @app.exception_handler(AgentInvokeException)
    async def handle_agent_invoke_exception(request: Request, ex: AgentInvokeException):
        logger.warning(f"Rejecting request: {str(ex)}")
        return JSONResponse(
            content={"message": str(ex)},
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    @app.exception_handler(ClientException)
    async def handle_client_exception(request: Request, ex: ClientException):
        logger.warning(f"Rejecting request: {str(ex)}")
        return JSONResponse(
            content={"message": str(ex)},
            status_code=ex.status_code,
        )
```

## Secrets Management

```python
# app/utils/secrets_utils.py
import logging
import os
from functools import lru_cache

logger = logging.getLogger(__name__)

_secret_cache: dict[str, str] = {}


@lru_cache(maxsize=1)
def _vault_client():
    """Optional: return a client for HashiCorp Vault, AWS Secrets Manager, etc."""
    # return VaultClient.from_settings(...)
    return None


def get_secret(name: str) -> str:
    """Resolve a secret from your secrets manager."""
    if name in _secret_cache:
        return _secret_cache[name]

    client = _vault_client()
    if client is not None:
        value = client.read_secret(name)
        _secret_cache[name] = value
        return value

    raise RuntimeError(f"Secret {name!r} is not configured")
```

## Request Header Models with Validators

```python
# app/models/agent_headers.py
import re
from typing import Annotated, Optional

from pydantic import AfterValidator, BaseModel


def validate_positive_integer_id(v: str) -> str:
    if not re.match(r"^[1-9][0-9]*$", v):
        raise ValueError(f"Must be a positive integer, got: {v}")
    return v


def validate_auth_token(v: str) -> str:
    if not re.match(r"^(?![._+=\-])[a-zA-Z0-9._+=\-]+(?<![._+\-])$", v):
        raise ValueError("Invalid auth token format")
    return v


UserId = Annotated[str, AfterValidator(validate_positive_integer_id)]
AuthToken = Annotated[str, AfterValidator(validate_auth_token)]


class AuthContext(BaseModel):
    user_id: UserId
    auth_token: AuthToken
    realm_id: Optional[str] = None


class RequestHeaders(BaseModel):
    transaction_id: str
    auth_context: AuthContext
    experience_id: Optional[str] = None
    originating_asset_alias: Optional[str] = None
    agent_interaction_id: Optional[str] = None
    interaction_group_id: Optional[str] = None
```

## Agent Context Construction

```python
# app/router/agent_router_helper.py
from app.models.agent_context import AgentContext
from app.models.agent_headers import AuthContext, RequestHeaders


def construct_agent_context(request, agent_input_request) -> AgentContext:
    auth_context = AuthContext(
        user_id=request.headers.get("x-user-id", ""),
        auth_token=request.headers.get("x-auth-token", ""),
        realm_id=request.headers.get("x-realm-id"),
    )
    request_headers = RequestHeaders(
        transaction_id=request.headers.get("transaction_id", ""),
        auth_context=auth_context,
        experience_id=request.headers.get("x-experience-id"),
        originating_asset_alias=request.headers.get("x-originating-asset-alias"),
        agent_interaction_id=request.headers.get("x-agent-interaction-id"),
        interaction_group_id=request.headers.get("x-interaction-group-id"),
    )
    return AgentContext(
        input=agent_input_request.agent_input.content[0].text,
        request_headers=request_headers,
        metadata=agent_input_request.metadata,
    )
```

## LangGraph Agent Definition

```python
# app/service/agent/agent.py
import logging
from langchain_openai import ChatOpenAI
from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import StateGraph, MessagesState, START, END
from langgraph.prebuilt import ToolNode, tools_condition

logger = logging.getLogger(__name__)


async def initialize_agent(config):
    llm = ChatOpenAI(
        base_url=f"{config.llm_base_url}/{config.llm_model_id}/",
        model=config.llm_model_id,
        temperature=0,
    )

    tools = [...]  # Loaded dynamically from config
    llm_with_tools = llm.bind_tools(tools)

    async def assistant_node(state: MessagesState):
        system_message = get_system_prompt()
        response = await llm_with_tools.ainvoke(
            [system_message] + state["messages"]
        )
        return {"messages": [response]}

    graph_builder = StateGraph(MessagesState)
    graph_builder.add_node("assistant", assistant_node)
    graph_builder.add_node("tools", ToolNode(tools=tools))
    graph_builder.add_edge(START, "assistant")
    graph_builder.add_conditional_edges("assistant", tools_condition)
    graph_builder.add_edge("tools", "assistant")

    checkpointer = MemorySaver()  # Use AsyncRedisSaver in prod
    return graph_builder.compile(checkpointer=checkpointer)
```

## Adapter Pattern (Async Singleton)

```python
# app/adapters/conversation_history_client.py
import asyncio
import logging
from typing import Optional

import aiohttp

logger = logging.getLogger(__name__)


class ConversationHistoryClient:
    session: Optional[aiohttp.ClientSession] = None
    _lock: asyncio.Lock = asyncio.Lock()

    @classmethod
    async def get_session(cls) -> aiohttp.ClientSession:
        async with cls._lock:
            if cls.session is None:
                timeout = aiohttp.ClientTimeout(total=60)
                cls.session = aiohttp.ClientSession(timeout=timeout)
            return cls.session

    @classmethod
    async def fetch_history(cls, thread_id: str, headers: dict) -> list:
        session = await cls.get_session()
        try:
            async with session.get(
                f"{BASE_URL}/v1/conversations/{thread_id}",
                headers=headers,
            ) as response:
                response.raise_for_status()
                data = await response.json()
                return data.get("interactions", [])
        except Exception as ex:
            # Graceful degradation — continue without history
            logger.exception(f"Failed to fetch conversation history: {ex}")
            return []
```

## ContextVar Logging

```python
# common/logging_helper.py
import logging
import contextvars
from contextlib import contextmanager

_logging_context: contextvars.ContextVar[frozenset] = contextvars.ContextVar(
    "logging_context", default=frozenset()
)


@contextmanager
def logging_context(**kwargs):
    current = _logging_context.get()
    token = _logging_context.set(current | frozenset(kwargs.items()))
    try:
        yield
    finally:
        _logging_context.reset(token)


class RequestFormatter(logging.Formatter):
    def format(self, record):
        ctx = dict(_logging_context.get())
        record.context = " ".join(f"{k}={v}" for k, v in ctx.items()) if ctx else ""
        return super().format(record)
```

## Transaction ID Middleware

```python
import uuid
from fastapi import Request
from starlette.responses import Response


@app.middleware("http")
async def inject_transaction_id(request: Request, call_next) -> Response:
    # Use existing transaction_id or generate one
    transaction_id = request.headers.get("transaction_id", str(uuid.uuid4()))
    request.state.transaction_id = transaction_id
    response = await call_next(request)
    response.headers["transaction_id"] = transaction_id
    return response
```

## Structured Logging with structlog

**Configure logging with environment-based renderer:**

```python
# common/logging_helper.py (target state — replaces current RequestFormatter approach)
import logging
import structlog

def configure_logger(log_level: str, environment: str = "local") -> None:
    """Configure structlog with JSON output for prod, console for local."""

    shared_processors = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]

    if environment in ("staging", "production"):
        renderer = structlog.processors.JSONRenderer()
    else:
        renderer = structlog.dev.ConsoleRenderer()

    structlog.configure(
        processors=shared_processors + [
            structlog.stdlib.ProcessorFormatter.wrap_for_formatter,
        ],
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

    formatter = structlog.stdlib.ProcessorFormatter(
        processors=[
            structlog.stdlib.ProcessorFormatter.remove_processors_meta,
            renderer,
        ],
    )

    handler = logging.StreamHandler()
    handler.setFormatter(formatter)

    root = logging.getLogger()
    for h in root.handlers[:]:
        root.removeHandler(h)
    root.addHandler(handler)
    root.setLevel(getattr(logging, log_level.upper()))
```

**Bind context at engine entry points:**

```python
# app/engine/order_processing_engine.py
import structlog

logger = structlog.get_logger()

async def analyze(self, order_data, order_id=None, user_id=None):
    structlog.contextvars.bind_contextvars(
        order_id=order_id,
        order_year=order_data.order_year,
        order_status=order_data.order_status,
    )
    logger.info("analysis_started")
    # ... all downstream logs automatically include order_id, order_year, order_status
```

**Promotion executor — bind promotion_id per iteration:**

```python
# app/engine/strategies/executor.py
for promotion in ordered_promotions:
    structlog.contextvars.bind_contextvars(promotion_id=promotion.promotion_id)
    try:
        result = promotion.evaluate(order_details, calculator)
        logger.info("promotion_applied", eligible=result.applicable)
    except Exception:
        logger.exception("promotion_failed")
    finally:
        structlog.contextvars.unbind_contextvars("promotion_id")
```

**Calculator — bind attempt during retry:**

```python
# app/engine/calculator/llm_calculator.py
for attempt in range(_MAX_RETRIES + 1):
    structlog.contextvars.bind_contextvars(calculator_attempt=attempt + 1)
    result = await self._invoke_llm(prompt)
    errors = self._validate_consistency(result, order_year)
    if not errors:
        logger.info("computation_valid")
        return result
    logger.warning("consistency_errors", errors=errors)
```

**Production JSON output example:**
```json
{"event": "promotion_applied", "order_id": "abc-123", "order_year": "2024", "promotion_id": "loyalty_rewards", "eligible": true, "level": "info", "timestamp": "2026-04-14T10:30:00Z", "logger": "app.engine.strategies.executor"}
```

**Local console output example:**
```
2026-04-14 10:30:00 [info] promotion_applied  order_id=abc-123 order_year=2024 promotion_id=loyalty_rewards eligible=True
```

---

## Engine-Layer Error Patterns

**Typed exception definitions:**

```python
# app/engine/errors.py
class EngineError(Exception):
    """Base for all engine-layer errors."""

class CalculatorError(EngineError):
    """LLM call failed or returned unparseable response."""

class ValidationError(EngineError):
    """Consistency check failed after all retries."""

class StrategyError(EngineError):
    """Individual promotion evaluation failed."""

class ExtractionError(EngineError):
    """Document parsing/extraction failed."""
```

**Promotion executor — catch, log, skip, continue:**

```python
# app/engine/strategies/executor.py
import structlog
from app.engine.errors import StrategyError

logger = structlog.get_logger()

for promotion in ordered_promotions:
    try:
        result = promotion.evaluate(order_details, calculator)
        results.append(result)
    except StrategyError:
        logger.exception("promotion_failed_skipping", promotion_id=promotion.promotion_id)
    except Exception:
        logger.exception("unexpected_promotion_error", promotion_id=promotion.promotion_id)
```

**Calculator — retry with feedback, then degrade:**

```python
# app/engine/calculator/llm_calculator.py
import structlog
from app.engine.errors import CalculatorError, ValidationError

logger = structlog.get_logger()

async def compute_order_total(self, order_state, order_year, order_status):
    prompt = self._build_prompt(order_state, order_year, order_status)

    for attempt in range(_MAX_RETRIES + 1):
        try:
            response = await self._llm.ainvoke(prompt)
            json_data = self._extract_json(response.content)
            result = OrderState(**json_data)
        except Exception as ex:
            raise CalculatorError(f"LLM call failed: {type(ex).__name__}") from ex

        errors = self._validate_consistency(result, order_year)
        if not errors:
            return OrderTotalResult(order_state=result, confidence=0.95)

        logger.warning("validation_failed", errors=errors, attempt=attempt + 1)
        if attempt < _MAX_RETRIES:
            prompt += self._retry_suffix.format(errors="; ".join(errors))

    logger.warning("returning_degraded_result", attempts=_MAX_RETRIES + 1)
    return OrderTotalResult(order_state=result, confidence=0.5)
```

**Tool boundary — catch engine error, return user-safe message:**

```python
# app/service/agent/tools/order_processing_tool/order_processing_tool.py
import structlog
from app.engine.errors import EngineError

logger = structlog.get_logger()

async def _arun(self, ..., config: RunnableConfig) -> str:
    try:
        result = await self._engine.analyze(order_data)
        return self._format_result(result)
    except EngineError as ex:
        # Log full detail for debugging
        logger.exception("engine_error", error_type=type(ex).__name__)
        # Return safe message for agent to relay to user
        return "I encountered an issue processing your order. The results may be incomplete."
```

---

## Error Tracking Integration

**Convention-based pattern (tool-agnostic — applies to Sentry, Datadog, or equivalent):**

```python
# app/service/error_tracking.py
import structlog

logger = structlog.get_logger()

def capture_error(ex: Exception, *, severity: str = "p2", **context):
    """Capture an error for tracking/alerting. Tool-agnostic interface.

    Replace internals when error tracking SDK is selected.
    NOTE: str(ex) can leak PII if exception messages contain user data.
    Engine-layer typed exceptions should use safe messages (error type + metadata, no values).
    """
    logger.error(
        "tracked_error",
        error_type=type(ex).__name__,
        error_message=str(ex),
        severity=severity,
        **context,
    )
    # Future: sentry_sdk.capture_exception(ex) or equivalent
```

**Usage at tracked boundaries:**

```python
from app.service.error_tracking import capture_error

# Order total calculator: all retries exhausted
if all_retries_failed:
    capture_error(
        ValidationError("Consistency check failed after all retries"),
        severity="p2",
        order_id=order_id,
        customer_id=customer_id,
    )

# Promotion: module load failure (affects all users)
except Exception as ex:
    capture_error(
        ex,
        severity="p1",
        module=module_name,
    )

# Auth: infrastructure failure
except AuthzInitialisationFailed as ex:
    capture_error(ex, severity="p1")
```

**Severity guide:**

| Severity | Pages on-call? | Examples |
|---|---|---|
| **P1** | Yes | Auth infrastructure down, all calculator calls failing, promotion module won't load |
| **P2** | No (creates ticket) | Individual validation failure after retries, single promotion error for one user |

---

## Tool Definition Pattern

```python
# app/service/agent/tools/retriever_tool/retriever_tool.py
from langchain_core.tools import BaseTool
from langchain_core.runnables import RunnableConfig


class RetrieverTool(BaseTool):
    name: str = "knowledge_retriever"
    description: str = "Retrieves relevant documents from the knowledge base."

    async def _arun(self, query: str, config: RunnableConfig) -> str:
        agent_context = config["configurable"]["agent_context"]
        headers = agent_context.get_header()

        # Call RAG API with auth headers
        results = await self.rag_api.retrieve(
            query=query,
            headers=headers,
            max_results=5,
        )
        return self._format_results(results)

    def _format_results(self, results: list) -> str:
        return "\n\n".join(
            f"**{r['title']}**\n{r['content']}" for r in results
        )
```

## Test Patterns

### Unit test conftest

```python
# test/unit/conftest.py
import pytest
from common.common_config import SvcSettings


@pytest.fixture
def default_settings():
    return SvcSettings(expose_metrics=False)


@pytest.fixture
def anyio_backend():
    return "asyncio"
```

### Integration test conftest

```python
# test/integration/conftest.py
import pytest
from contextlib import asynccontextmanager
from unittest.mock import patch

from fastapi.testclient import TestClient


@asynccontextmanager
async def mock_make_authz_client(settings):
    yield None


@pytest.fixture(scope="session")
def app(settings):
    with patch.dict("os.environ", {"APP_ENV": "local"}):
        with patch("common.identity.dependency.make_authz_client", mock_make_authz_client):
            from app.service import create_app
            return create_app()


@pytest.fixture(scope="session")
def client(app, settings):
    return TestClient(
        app,
        headers={"X-Forwarded-Port": str(settings.gateway_port)},
    )
```

### Async test example

```python
# test/unit/test_agent_service.py
import pytest
from unittest.mock import AsyncMock, MagicMock

from app.service.agent_service import ainvoke_agent
from app.service.error_handling import AgentInvokeException, AuthorizationError


@pytest.mark.asyncio
async def test_ainvoke_agent_success():
    mock_request = MagicMock()
    mock_request.app.state.graph.ainvoke = AsyncMock(
        return_value={"messages": [MagicMock(content="test response")]}
    )
    content, trace_id = await ainvoke_agent(mock_request, mock_agent_context)
    assert content == "test response"


@pytest.mark.asyncio
async def test_ainvoke_agent_auth_error():
    from openai import AuthenticationError
    mock_request.app.state.graph.ainvoke.side_effect = AuthenticationError("bad key")
    with pytest.raises(AuthorizationError):
        await ainvoke_agent(mock_request, mock_agent_context)
```

## pyproject.toml Complete Example

```toml
[tool.poetry]
name = "my-service"
version = "0.1.0"
description = "Example FastAPI + LangGraph agent service"
authors = ["Maintainers <maintainers@example.com>"]
package-mode = false

[tool.poetry.dependencies]
python = ">=3.11,<3.13"
pydantic = ">=2.10.6"
pydantic-settings = ">=2.8.1"

[tool.poetry.group.api.dependencies]
fastapi = ">=0.115.11"
uvicorn = {version = ">=0.34.0", extras = ["standard"]}

[tool.poetry.group.agentic.dependencies]
langgraph = "^0.2.70"
langchain-openai = "^0.3.4"
langchain-core = "^0.3.34"
langfuse = "^3.10"

[tool.poetry.group.dev.dependencies]
black = "^25.1.0"
isort = "^6.0.1"
mypy = ">=1.15.0"

[tool.poetry.group.test.dependencies]
pytest = ">=8.3.5"
pytest-mock = "*"
pytest-cov = ">=6.0.0"
pytest-asyncio = ">=0.14.0"
httpx = "*"

[[tool.poetry.source]]
name = "pypi"
url = "https://pypi.org/simple/"
priority = "primary"

[tool.black]
line-length = 88
target-version = ['py312']

[tool.isort]
profile = "black"

[tool.mypy]
warn_unused_configs = true
warn_redundant_casts = true
warn_unused_ignores = true
strict_equality = true
extra_checks = true
check_untyped_defs = true
plugins = ["pydantic.mypy"]

[tool.pytest.ini_options]
markers = [
    "integration: mark a test as an integration test.",
    "unit: mark a test as a unit test.",
    "agent_evaluation: mark a test for agent evaluation during CI/CD.",
]
pythonpath = [".", "app"]
testpaths = ["test/unit"]

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"
```

## Dockerfile Multi-Stage Build

```dockerfile
# Stage 1: Base image
FROM debian:11-slim AS base
RUN apt-get update && apt-get install -y nginx python3 python3-pip

# Stage 2: Install dependencies with Poetry
FROM base AS venv
WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN pip install poetry && \
    poetry config virtualenvs.in-project true && \
    poetry install --no-root --without dev,test --with api,agentic,evaluation

# Stage 3: Run tests
FROM venv AS test
COPY . .
RUN poetry install --no-root && \
    poetry run tox && \
    python -m app.scripts.generate_openapi

# Stage 4: Final runtime
FROM venv AS build
COPY . .
RUN useradd -m appuser
USER appuser
EXPOSE 8080
CMD ["python", "-m", "uvicorn", "app.service:create_app", "--factory", "--host", "0.0.0.0", "--port", "8080"]
```
