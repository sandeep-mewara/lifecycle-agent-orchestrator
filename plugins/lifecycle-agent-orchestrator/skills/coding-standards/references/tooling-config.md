# Python Standards — Tooling & Configuration

Complete reference configurations for pyproject.toml, Dockerfile, and CI/CD.

## Table of Contents
1. [pyproject.toml](#pyprojecttoml)
2. [Environment-Based Settings](#environment-based-settings)
3. [Dockerfile Multi-Stage Build](#dockerfile-multi-stage-build)
4. [Container Entry Point](#container-entry-point)
5. [Nginx Config](#nginx-config)
6. [agents_and_tools.yaml](#agents_and_toolsyaml)

---

## pyproject.toml

Complete production-ready configuration:

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
langgraph-sdk = "^0.1.51"
langchain = "^0.3.18"
langfuse = "^3.10"
httpcore = "^1.0.7"
redis = "^5.2.1"

[tool.poetry.group.evaluation.dependencies]
openevals = "^0.1.0"

[tool.poetry.group.dev.dependencies]
black = "^25.1.0"
isort = "^6.0.1"
mypy = ">=1.15.0"

[tool.poetry.group.test.dependencies]
pytest = ">=8.3.5"
pytest-mock = "*"
pytest-cov = ">=6.0.0"
pytest-xdist = ">=3.6.1"
pytest-asyncio = ">=0.14.0"
httpx = "*"

# PyPI as primary index; add a private package registry source only if you need internal wheels
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

[[tool.mypy.overrides]]
module = "langfuse.*"
ignore_missing_imports = true

[[tool.mypy.overrides]]
module = "langgraph.*"
ignore_missing_imports = true

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

## Environment-Based Settings

The full hierarchy from `common/common_config.py`:

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
    host: str = "0.0.0.0"
    port: int = 8080
    gateway_port: int = 443
    enable_langfuse: bool = False
    langfuse_host: str = ""
    langfuse_public_key: str = ""  # e.g. from LANGFUSE_PUBLIC_KEY
    langfuse_secret_key: str = ""  # e.g. from LANGFUSE_SECRET_KEY
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


class StagingSettings(ProdSettings):
    pass


ENV_SETTINGS_MAP = {
    "local": LocalSettings,
    "ci": CISettings,
    "staging": StagingSettings,
    "production": ProdSettings,
}


@lru_cache(maxsize=1)
def settings_factory() -> SvcSettings:
    env = os.getenv("APP_ENV", "local")
    settings_class = ENV_SETTINGS_MAP.get(env, LocalSettings)
    return settings_class()
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

# Stage 4: Final runtime image
FROM venv AS build
COPY . .
LABEL app="my-service" app-scope="runtime"
RUN useradd -m appuser
USER appuser
EXPOSE 8080
CMD ["python", "-m", "uvicorn", "app.service:create_app", "--factory", \
     "--host", "0.0.0.0", "--port", "8080"]
```

## Container Entry Point

`package/entry.sh` routes based on `APP_WORKLOAD_TYPE`:

```bash
#!/bin/bash
set -e

case "${APP_WORKLOAD_TYPE:-webservice}" in
  webservice)
    exec uvicorn app.service:create_app --factory \
      --host 0.0.0.0 --port "${APP_PORT:-8080}" \
      --workers "${APP_WORKERS:-1}" --loop uvloop
    ;;
  event-driven)
    exec python -m app.service.event_handler
    ;;
  cronjob)
    exec python -m app.service.cron_job
    ;;
esac
```

## Nginx Config

`package/nginx.conf` — reverse proxy to uvicorn:

```nginx
upstream app {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## agents_and_tools.yaml

Example agent and tool registry:

```yaml
registry_schema: "1.0.0"
agents:
  - name: my-agent
    framework: langgraph
    tools:
      - knowledge_retriever
    environments:
      staging:
        url: https://my-service-staging.example.com/v1/invoke
      production:
        url: https://my-service.example.com/v1/invoke

tools:
  - name: knowledge_retriever
    scope: private
    response_type: sync
    categories:
      - retrieval
```
