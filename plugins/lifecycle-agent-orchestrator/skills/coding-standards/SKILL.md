---
name: coding-standards
description: Enforces coding standards when writing or modifying code. Covers naming conventions, exception and error handling patterns, structured logging, tracing, project structure, environment-based configuration, secrets management, app initialization, async patterns, and code quality tooling. Language-specific conventions (Python, Java, C#) are loaded from bundled reference packs. Use this skill when writing code, creating new files or modules, defining classes or functions, adding error handling, setting up project scaffolding, configuring deployment, or reviewing code for standards compliance.
---

# Coding Standards

Standards drawn from production service patterns. The goal is consistency — any engineer should read any service in your repository and immediately understand the patterns.

**Bundled references** (read when you need detailed configs or complete code examples):
- `references/checklist.md` — Universal pre-commit and code review checklist
- `references/<language>/checklist.md` — Language-specific checklist
- `references/<language>/examples.md` — Full code examples for every pattern below
- `references/<language>/tooling-config.md` — Build config, Dockerfile, CI/CD, environment settings

Where `<language>` is `python`, `java`, or `csharp` — determined by the project's `lao.config.yaml` or auto-detected at pipeline start.

---

## Naming Conventions

Consistent naming makes code self-documenting. Apply the conventions of your language:

| What | Principle | Python | Java | C# |
|------|-----------|--------|------|-----|
| Functions/methods | Verb-first, descriptive | `snake_case` | `camelCase` | `PascalCase` |
| Classes | Noun, descriptive | `PascalCase` | `PascalCase` | `PascalCase` |
| Interfaces | Describe capability | N/A | `PascalCase` | `IPascalCase` |
| Variables | Descriptive, no abbreviations | `snake_case` | `camelCase` | `camelCase` |
| Constants | Immutable values | `UPPER_SNAKE_CASE` | `UPPER_SNAKE_CASE` | `PascalCase` |
| Booleans | Prefix with `is`/`has`/`can` | `is_active` | `isActive` | `IsActive` |
| Files | Match primary type | `snake_case.py` | `PascalCase.java` | `PascalCase.cs` |
| Private members | Indicate non-public scope | `_leading_underscore` | `private` keyword | `_camelCase` field |
| Exception classes | Suffix `Error`/`Exception` | `AuthorizationError` | `AuthorizationException` | `AuthorizationException` |

**Universal rules regardless of language:**
- Variable names reflect purpose, not type (`userId` not `str1`)
- Boolean names are predicate-style (`isAuthenticated`, `hasPermission`)
- No single-letter variables outside loops
- If you need a comment to explain what a variable holds, the variable needs a better name

---

## Exception and Error Handling

Three-layer pattern: **define typed exceptions → catch specific → centralized handlers**.

### 1. Typed exception hierarchy

Never throw/raise generic exceptions. Define domain-specific error types for each failure category:
- Service-level errors (auth, validation, rate limiting)
- Domain-level errors (business rule violations, calculation failures)
- Infrastructure errors (external service failures, timeouts)

Each error type has a defined behavior: **retry-then-degrade**, **log-and-skip**, or **fail-fast**.

### 2. Catch specific first, generic last

Always catch the most specific exception type first. Generic catch should be a safety net only. Always log before re-raising.

### 3. Centralized error-to-response mapping

Map all exception types to HTTP status codes in one place. Error responses contain:
- Machine-readable error code (e.g., `bad_request`, `rate_limit_exceeded`)
- Human-readable message
- Never: stack traces, internal state, PII, field values

### Error propagation

- Engine/domain layer raises typed error
- Service boundary catches, logs full detail, returns user-safe summary
- API layer surfaces structured error response — never exposes internals

### Error tracking conventions

- Track errors that affect users or reliability (retries exhausted, auth failures, infrastructure failures)
- Don't track expected/handled conditions (successful retries, cache misses)
- Context on every tracked error: correlation ID, error type, relevant identifiers, stack trace. No PII.
- Severity: **P1** (pages on-call) for infrastructure-wide failures, **P2** (creates ticket) for isolated errors

---

## Structured Logging

Use your language's structured logging framework (Python: `structlog`, Java: SLF4J+Logback, C#: Serilog).

**Log level decision matrix:**

| Level | When | Examples |
|---|---|---|
| `ERROR` | Unrecoverable failure needing attention | External service permanently unreachable, data corruption detected |
| `WARNING` | Degraded but continuing | Validation failed (retrying), resource not found (creating new) |
| `INFO` | Operational lifecycle event | Component registered, state saved, app startup |
| `DEBUG` | Detailed tracing (local dev only) | Truncated snippets, check values — **never** sensitive content in staging/production |

**Universal rules:**
- JSON output in production for machine-parseable logging
- Human-readable output in local dev
- Context binding at service entry points — inject correlation ID at minimum
- No PII in logs — log identifiers, never values. See **Security skill** for the full allowlist.
- No `print()` / `System.out.println()` / `Console.WriteLine()` in production code

---

## Tracing

Observability tracing provides visibility over request lifecycle and LLM execution paths.

- Trace ID correlates with the request's correlation ID
- Spans follow the request lifecycle hierarchy
- No PII or sensitive data content in traces — identifiers only
- Errors need a separate aggregation tool (see Error Tracking above)

See PROJECT.md for service-specific span hierarchy and tracing configuration.

---

## Project Structure

Separation of concerns — consistent layering regardless of language:

```
<root>/
    router/           # Route definitions only — no business logic
    service/          # Business logic, orchestration
    models/           # Data transfer objects, request/response schemas
    adapters/         # External service clients
    persistence/      # State storage (databases, caches)
    utils/            # Shared utilities
    config/           # Environment-based configuration
    test/
        unit/         # Fast, isolated, no external dependencies
        integration/  # Needs running services or mocked infrastructure
```

**Key principles:**
- Routes in router layer, logic in service layer. Never mix them.
- Models live in the models layer, not scattered across service files.
- External service clients are adapters — isolate them for testability.
- Configuration hierarchy based on deployment environment.

See `references/<language>/tooling-config.md` for the language-specific project layout.

---

## Configuration: Environment-Based Settings

Settings adapt per deployment stage using a hierarchy pattern:

```
BaseSettings          # All environments — shared defaults
├── PreProdSettings   # Pre-production defaults
│   ├── LocalSettings # Local dev overrides
│   └── CISettings    # CI overrides
└── ProdSettings      # Production overrides
```

**Universal rules:**
- Settings resolved from environment variables at startup
- Factory function returns the correct settings class based on environment identifier
- Singleton pattern — settings created once, cached for the process lifetime
- Secrets never stored as literal values — store references, resolve at runtime

---

## Secrets Management

Never hardcode secrets. Store references (secret paths, vault names, or key identifiers) in configuration; resolve actual values at runtime via a secrets manager.

**Rules:**
- Secrets stored as reference strings in settings, never as literal values
- Runtime retrieval via a secrets client with lazy caching
- Pre-warm secrets during app startup to fail fast if the backend is unreachable
- Never put secrets in environment variables, container layers, config files, or source code
- Lock files committed for reproducible dependency resolution

For security policy and secret-handling conventions, see the **Security skill** (`skills/security/`).

---

## App Initialization & Lifecycle

Key principle: **optional features fail softly without crashing startup**.

- Initialize required dependencies first (config, secrets, database connections)
- Optional integrations (observability, auth clients, caches) use graceful degradation — log the failure, continue without the feature
- Resource cleanup on shutdown via lifecycle management (context managers, shutdown hooks)

---

## Async Patterns

For languages/frameworks that support async I/O:

- **Never block the event loop.** Synchronous I/O or CPU-heavy work in async context stalls all concurrent requests.
- **Offload blocking work** to thread pools or background tasks.
- **Connection pooling** for HTTP clients with appropriate limits.
- **Shared resources** protected from race conditions (locks, atomic operations).
- **Singleton pattern** for expensive shared resources (HTTP sessions, database pools).

---

## Code Quality Tooling

Every project must have:

| Tool Category | Purpose | Enforcement |
|---|---|---|
| Formatter | Consistent code style | Pre-commit hook + CI |
| Linter / Static analysis | Catch bugs and anti-patterns | CI pipeline |
| Type checker | Type safety | CI pipeline (or IDE integration) |
| Test runner | Automated testing | CI pipeline |
| Dependency lock | Reproducible builds | Committed lock file |

See `references/<language>/tooling-config.md` for language-specific tool configuration.

---

Before committing or reviewing, consult `references/checklist.md` and `references/<language>/checklist.md` for the full verification checklist.
