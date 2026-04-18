# Security Standards — Checklist

Use this checklist when writing new code, reviewing PRs, or assessing deployment readiness.

## 1. Secret Management
- [ ] Secrets stored as secrets-manager references (`secrets/...` paths or vault references) in settings, not literal values
- [ ] `get_secret()` used for runtime retrieval — never direct reads of raw secret material from config
- [ ] No secrets in environment variables, Docker layers, config files, or source code
- [ ] Secrets pre-warmed during `on_startup` to fail fast
- [ ] `poetry.lock` committed and consistent with `pyproject.toml`

## 2. Encryption
- [ ] All external communication over HTTPS/TLS (service mesh or gateway enforced)
- [ ] No plain HTTP endpoints exposed
- [ ] IAM tokens in headers only — never in query parameters or request bodies
- [ ] No local file storage of sensitive domain payloads (for example full order details or health records where applicable)

## 3. Authentication & Authorization
- [ ] Every new endpoint behind API gateway (or equivalent) auth
- [ ] `check_auth_required()` enforced — only health/actuator routes in `AUTH_EXEMPT_ROUTES`
- [ ] IAM headers validated via Pydantic `Annotated[str, AfterValidator()]`
- [ ] No endpoint returns data for a user other than the authenticated user
- [ ] Auth tokens never appear in log messages or error responses
- [ ] `AuthorizationError` mapped to 401 via centralized handler

## 4. OWASP / Secure Coding
- [ ] All external input validated via Pydantic models at system boundaries
- [ ] No raw string interpolation into LLM prompts — use named template variables
- [ ] User input in message content only, never in system prompt templates
- [ ] LLM output parsed and validated before use (structure + consistency checks)
- [ ] No user-controlled URL pass-through without validation (SSRF prevention)
- [ ] Guard clauses + early returns for error handling — no deeply nested conditionals

## 5. Dependencies & Vulnerabilities
- [ ] Dependencies pinned in `pyproject.toml`
- [ ] Dependabot enabled and PRs reviewed weekly
- [ ] Container image scanning in CI pipeline
- [ ] Container runs as non-root user (`appuser`)
- [ ] Private package registry as primary package source when mirroring or vetting dependencies

## 6. API Security
- [ ] Request schema validated via Pydantic — required fields fail fast with 422
- [ ] `ErrorCode(StrEnum)` used — no opaque error codes
- [ ] Error responses contain type + message only — no PII, stack traces, or internal state
- [ ] `RateLimitError` from upstream caught and mapped to appropriate status code
- [ ] `register_error_handlers(app)` covers all custom exception types

## 7. Sensitive Data Protection
- [ ] No PII or highly sensitive domain values in logs (examples: payment details, account balances, government IDs, tokens, API keys)
- [ ] No PII in LLM observability traces or error messages
- [ ] Only allowlisted fields in log output (minimum identifiers often include `order_id`, `promotion_id`, `transaction_id`, `trace_id`; see SKILL.md §7 and PROJECT.md for domain-specific allowlists such as `order_status`, `confidence_score`, error types/codes, promotion names)
- [ ] `structlog` field redaction configured for production (when adopted)
- [ ] Full sensitive payload JSON and LLM prompt content never logged (DEBUG-level prompt tracing allowed only in local dev, never in staging/production)

## 8. Compliance
- [ ] Session-scoped data has Redis TTL auto-expiry
- [ ] No indefinite retention of user data at the application layer
- [ ] No cross-user data access — resources scoped to authenticated session
- [ ] Response metadata supports consumer-side disclaimer rendering
- [ ] Prefer processing within your infrastructure — document and control any third-party data egress
