# Code Standards Quick Reference

This is the consolidated reference for platform services coding conventions. Use during code reviews to check adherence. These are derived from the project's coding rules, `CONTRIBUTING.md`, `pyproject.toml`, and `tox.ini`.

---

## Formatting and Tooling

| Tool | Config | Enforcement |
|------|--------|-------------|
| **Black** | Line length 88, target Python 3.12 | Pre-commit hook + CI (tox lint) |
| **isort** | Black profile | Pre-commit hook + CI (tox lint) |
| **gitleaks** | Secret detection on staged diffs | Pre-commit hook |
| **mypy** | Strict mode: `warn_unused_configs`, `warn_redundant_casts`, `warn_unused_ignores`, `strict_equality`, `extra_checks`, `check_untyped_defs`, Pydantic plugin | Configured in pyproject.toml (currently disabled in tox — may be re-enabled) |
| **pytest** | Paths: `test/unit`, markers: `unit`, `integration`, `agent_evaluation` | CI via tox |
| **Coverage** | >=85% required, omits `*/test/*`, reports: HTML + terminal + XML | CI via tox + Cobertura |

If formatting or import ordering is wrong in a PR, the CI pipeline will catch it. Don't spend review time on these — focus on what machines can't check.

---

## Python Style

### Functions and Types
- **Type hints on all function signatures.** No exceptions for "simple" functions.
- **`def` for pure functions, `async def` for I/O-bound operations.** Never use sync calls inside async functions without offloading to a thread pool.
- **Pydantic v2 models** for all data contracts — request/response models, tool inputs/outputs. Prefer Pydantic over raw dictionaries.
- **RORO pattern** (Receive an Object, Return an Object) — functions take structured inputs and return structured outputs.

```python
# Good
async def fetch_customer_profile(request: ProfileRequest) -> ProfileResponse:
    ...

# Avoid
async def fetch_customer_profile(user_id: str, include_addresses: bool = False) -> dict:
    ...
```

### Naming
- **Files and directories:** lowercase with underscores (`routers/user_routes.py`)
- **Variables:** descriptive with auxiliary verbs (`is_active`, `has_permission`, `can_generate_report`)
- **Functions:** verb-noun for actions (`fetch_customer_profile`, `calculate_cart_totals`)
- **Agents:** named by responsibility (`order_fulfillment_agent`, not `agent_2`)
- **Constants:** UPPER_SNAKE_CASE
- If you need a comment to explain what a variable holds, the variable needs a better name.

### Error Handling
- **Guard clauses first.** Handle errors and edge cases at function start, happy path last.
- **Early returns** over deeply nested if/else.
- **No bare `except`.** Catch specific exceptions. If you must catch broadly, log the exception and re-raise or return a meaningful error.
- **HTTPException** for expected API errors, paired with ErrorResponse models.
- **Custom error types or error factories** for consistent error handling across the service.

```python
# Good — guard clause, early return
async def get_order_details(request: OrderDetailsRequest) -> OrderDetailsResponse:
    if not request.order_id:
        raise HTTPException(status_code=400, detail="order_id is required")

    if not await has_permission(request.user_id, "order:read"):
        raise HTTPException(status_code=403, detail="Insufficient permissions")

    # Happy path
    data = await fetch_order_data(request)
    return build_order_details(data)

# Avoid — nested conditions
async def get_order_details(request: OrderDetailsRequest) -> OrderDetailsResponse:
    if request.order_id:
        if await has_permission(request.user_id, "order:read"):
            data = await fetch_order_data(request)
            return build_order_details(data)
        else:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
    else:
        raise HTTPException(status_code=400, detail="order_id is required")
```

### Async Patterns
- **Never block the event loop.** Sync HTTP clients, file I/O, or CPU-heavy work inside an `async def` will stall all concurrent requests.
- **Use `asyncio.to_thread()`** for unavoidable blocking calls.
- **Connection pooling** for HTTP clients (`httpx.AsyncClient` with connection limits).
- **Caching** via Redis or `custom_lru_cache` for read-heavy data. Short TTLs for mutable user data.

---

## Project Structure

The codebase follows a consistent layout. New code should match these patterns.

```
app/
├── router/          # Route definitions only — no business logic
├── service/         # Business logic, agent orchestration
│   └── agent/       # LangGraph agent and tools
│       └── tools/   # Each tool in its own directory
├── models/          # Pydantic request/response models
├── adapters/        # External service clients
├── persistence/     # State storage (Redis, databases)
├── utils/           # Shared utilities
└── test/
    ├── unit/        # Unit tests (default pytest path)
    └── integration/ # Integration tests
common/              # Cross-cutting: config, auth, logging
```

**Key conventions:**
- Routes in `router/`, logic in `service/`. Never mix them.
- Each tool gets its own directory under `agent/tools/`.
- Models live in `models/`, not scattered across service files.
- Reuse utilities in `utils/` and `common/` — don't duplicate.

---

## Testing Standards

- **Coverage threshold: >=85%** for new code. Not negotiable per CONTRIBUTING.md.
- **Test markers:** Use `@pytest.mark.unit`, `@pytest.mark.integration`, or `@pytest.mark.agent_evaluation` on every test.
- **Test names describe the scenario:** `test_fetch_profile_returns_none_when_user_not_found` — not `test_fetch_1`.
- **Mock external dependencies, not internal logic.** Mock APIs, databases, and third-party services. Don't mock the function you're testing.
- **Assertions verify behavior, not execution.** "The function was called" is weak. "The response contains the expected order_id and line totals" is strong.
- **Branch format:** `feature/JIRA-XXXX` or `bugfix/JIRA-XXXX`.
- **Commit messages** must reference the associated Jira ticket and describe *why*, not just *what*.

---

## Security Conventions

These are non-negotiable in reviews — violations are blockers, not suggestions.

- **No PII or sensitive payment data in logs, traces, or error messages.** Use field allowlists.
- **Secrets from a secrets manager only.** No hardcoded keys, tokens, or passwords.
- **Authz on every endpoint.** No unauthenticated access.
- **Input validation at system boundaries** via Pydantic models. No raw string interpolation into prompts.
- **Dependencies pinned** in `pyproject.toml`. **Containers run as non-root** (`appuser`).

For full security conventions, checklist, and code examples, see the **Security skill** (`skills/security/`).

---

## Observability Conventions

- **Langfuse tracing** for agent execution paths. Trace spans follow: router -> agent service -> agent -> tool -> external API.
- **Structured logging** with `transaction_id` correlation.
- **Log levels:** Error for failures needing attention, Warning for degraded behavior, Info for lifecycle events, Debug for tool call details.
- **Service metrics** for request rate, error rate, and latency.
- **Health checks** test real dependencies, not just return 200.

---

## CI/CD Quality Gates

The pipeline enforces these — code that fails them won't merge:

1. **Linting:** isort check -> Black check -> (mypy when enabled)
2. **Tests:** pytest with coverage >= 85%
3. **Docker build:** Multi-stage build includes test stage that must pass
4. **API linting:** OpenAPI spec validation (when enabled)
5. **Security scan:** Container image scanning in CI

Optional gates that may be enabled:
- SonarQube analysis and enforcement
- Readiness check (for staging/pre-production)
