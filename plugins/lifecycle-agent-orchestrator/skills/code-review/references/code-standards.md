# Code Standards Quick Reference

This is the consolidated reference for coding conventions during code reviews. For language-specific standards, see `<language>/code-standards.md`.

---

## Formatting and Tooling

Every project must have:
- **Formatter** — enforced via pre-commit hook + CI. If formatting is wrong in a PR, the CI pipeline catches it. Don't spend review time on these.
- **Static analysis** — linter and/or type checker configured in CI.
- **Coverage** — >=85% required for new code, reported in CI.

---

## Code Style (Universal)

### Functions and Types
- **Type annotations on all function signatures.** No exceptions for "simple" functions.
- **Sync for pure functions, async for I/O-bound operations.** Never use sync calls inside async functions without offloading.
- **Schema models** for all data contracts — request/response types, API boundaries. No raw dictionaries/maps for structured data.
- **Structured input/output** — functions take structured inputs and return structured outputs.

### Naming
- **Files and directories:** Follow the language convention consistently.
- **Variables:** Descriptive with auxiliary verbs (`isActive`, `hasPermission`, `canGenerateReport`).
- **Functions:** Verb-noun for actions (`fetchCustomerProfile`, `calculateCartTotals`).
- **Constants:** Language-appropriate constant convention.
- If you need a comment to explain what a variable holds, the variable needs a better name.

### Error Handling
- **Guard clauses first.** Handle errors and edge cases at function start, happy path last.
- **Early returns** over deeply nested if/else.
- **No bare catch-all.** Catch specific exceptions. If you must catch broadly, log and re-raise or return a meaningful error.
- **Custom error types** for consistent error handling across the service.

---

## Project Structure

The codebase should follow a consistent layout. New code should match these patterns:

```
<root>/
├── router/          # Route definitions only — no business logic
├── service/         # Business logic, orchestration
├── models/          # Data transfer objects, request/response schemas
├── adapters/        # External service clients
├── persistence/     # State storage
├── utils/           # Shared utilities
└── test/
    ├── unit/        # Unit tests (default test path)
    └── integration/ # Integration tests
```

**Key conventions:**
- Routes in router, logic in service. Never mix them.
- Models live in the models layer, not scattered across service files.
- Reuse utilities — don't duplicate logic across services.

---

## Testing Standards

- **Coverage threshold: >=85%** for new code.
- **Test markers/categories:** Every test is categorized (unit, integration, agent evaluation).
- **Test names describe the scenario:** `test_fetch_profile_returns_none_when_user_not_found` — not `test_fetch_1`.
- **Mock external dependencies, not internal logic.** Mock APIs, databases, and third-party services. Don't mock the function you're testing.
- **Assertions verify behavior, not execution.** "The function was called" is weak. "The response contains the expected order_id and line totals" is strong.
- **Commit messages** must describe *why*, not just *what*.

---

## Security Conventions

These are non-negotiable in reviews — violations are blockers, not suggestions.

- **No PII or sensitive data in logs, traces, or error messages.** Use field allowlists.
- **Secrets from a secrets manager only.** No hardcoded keys, tokens, or passwords.
- **Auth on every endpoint.** No unauthenticated access.
- **Input validation at system boundaries** via schema models. No raw string interpolation into prompts.
- **Dependencies pinned.** **Containers run as non-root user.**

For full security conventions, checklist, and code examples, see the **Security skill** (`skills/security/`).

---

## Observability Conventions

- **Tracing** for request execution paths. Spans follow the request lifecycle hierarchy.
- **Structured logging** with correlation ID.
- **Log levels:** Error for failures needing attention, Warning for degraded behavior, Info for lifecycle events, Debug for development details.
- **Service metrics** for request rate, error rate, and latency.
- **Health checks** test real dependencies, not just return 200.

---

## CI/CD Quality Gates

The pipeline enforces these — code that fails them won't merge:

1. **Formatting:** Formatter check
2. **Static analysis:** Linter and/or type checker
3. **Tests:** Test suite with coverage >= 85%
4. **Build:** Container/artifact build includes test stage that must pass
5. **Security scan:** Container image and dependency scanning
