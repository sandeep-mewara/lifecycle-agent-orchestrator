---
name: security-standards
description: Enforces security standards when writing or reviewing code that handles authentication, secrets, sensitive data, API boundaries, or compliance concerns. Covers secrets manager integration, encryption at rest and in transit, IAM authentication and least-privilege authorization, OWASP Top 10 secure coding (including prompt injection), dependency vulnerability management, API security (auth, validation, rate limiting), PII and sensitive data protection in logs and traces, and regulatory compliance (CCPA/GDPR). Use this skill when adding endpoints, handling user data, managing secrets, reviewing for vulnerabilities, configuring auth, working with LLM prompts that accept user input, setting up deployment security, or assessing compliance. Also use when DAST findings need remediation.
---

# Security Standards

Standards for services that handle sensitive data — where security failures can expose PII, regulated or highly sensitive domain data, and authentication credentials. These are non-negotiable in code review; violations are blockers, not suggestions.

**Bundled references** (read when you need checklists or code examples):
- `references/checklist.md` — Security review checklist (8 sections)
- `references/examples.md` — Code examples for key patterns

---

## 1. Secret Management (secrets manager)

Never hardcode secrets. Config stores secret references (for example managed paths or secret names); runtime retrieves actual values.

**Rules:**
- Secrets stored as references (such as `secrets/...` paths or vault references) in settings classes, never as literal values
- `get_secret()` retrieves from your secrets manager at runtime using a lazy singleton with module-level cache
- Pre-warm secrets during app startup (`on_startup`) to fail fast if the secrets backend is unreachable
- Never put secrets in environment variables, Docker layers, config files, or source code
- `poetry.lock` committed — ensures reproducible dependency resolution without exposing secrets

**Pattern:**
```python
# In settings (the PATH or name, not the secret)
langfuse_public_key: str = "secrets/langfuse/public_key"

# At runtime
actual_key = get_secret(settings.langfuse_public_key)
```

See the `coding-standards` skill `references/examples.md` for a secrets manager client factory and `get_secret()` implementation pattern.

---

## 2. Data Protection — Encryption at Rest and in Transit

**In transit:**
- All traffic over HTTPS/TLS via your service mesh — no plain HTTP endpoints
- LLM API calls go through your internal HTTPS proxy (or a vetted egress path) where required
- IAM tokens transmitted only in headers, never in query parameters or request bodies

**At rest:**
- Platform-managed encryption at rest for all data stores — application does not manage encryption keys
- Sensitive data classified accordingly — treat equivalently to PII for storage where policies apply
- No local file storage of sensitive data
- Future DB-backed persistence must use platform-managed encryption

**What is sensitive (minimum):**
- User authentication tokens and API keys
- Secrets manager credentials and references
- Any regulated or highly sensitive domain fields (see PROJECT.md for service-specific examples such as `order_id`, `promotion_id`, `order_year`, `order_status` in e-commerce or fintech contexts)

---

## 3. Authentication & Authorization

**Authentication — IAM headers on every request:**
- IAM headers validated via Pydantic `Annotated[str, AfterValidator()]` — rejects malformed tokens at parse time
- API gateway auth enforced — explicit allowlist for unauthenticated routes (health/actuator only)
- AuthZ client initialized at startup; graceful degradation if unavailable

**Least privilege:**
- Each component receives only the credentials it needs, not the full request context
- Tokens refreshed per-call — not cached beyond a single request
- Data access scoped to authenticated session — no cross-user queries

**Error handling:**
- Auth failures → 401 via centralized handler
- Auth failures logged at `WARNING` level (expected/handled) — never `ERROR` (which implies unexpected)
- Auth tokens never included in log messages or error responses

---

## 4. OWASP Top 10 — Secure Coding Practices

**Injection prevention:**
- Pydantic models validate all external input at system boundaries (API requests, tool inputs)
- No raw string interpolation into prompts, queries, or commands — use named template variables

**Prompt injection (LLM-specific):**
- System prompts are code-defined, never user-editable
- User input goes into message content only, never into system prompt templates
- LLM output is parsed and validated before use (structure check + consistency check)

**Broken access control:**
- Every endpoint behind API gateway auth (or equivalent)
- No endpoint returns data for a user other than the authenticated user

**Security misconfiguration:**
- Environment-based settings hierarchy prevents prod config from leaking into dev
- `APP_ENV` drives config — misconfiguration falls back safely to `LocalSettings`
- Debug-level logging disabled in production settings

**SSRF prevention:**
- URLs validated before server-side fetch
- No user-controlled redirect following
- No pass-through of user-provided URLs to external systems without sanitization

---

## 5. Dependency Management & Vulnerability Scanning

**Dependency hygiene:**
- Dependabot configured for weekly pip updates (`.github/dependabot.yml`)
- Dependencies pinned in `pyproject.toml`, lock file committed (`poetry.lock`)
- Private package registry as primary Poetry source when you mirror or vet packages through an internal proxy

**Container security:**
- Container image scanning in CI pipeline
- Non-root container user (`appuser`) in Dockerfile
- Multi-stage Docker build — dev/test dependencies excluded from runtime image

**Vulnerability response:**
- Dependabot PRs reviewed weekly — security patches prioritized over feature updates
- `poetry.lock` conflicts resolved by regenerating from updated `pyproject.toml`, not by manual editing

---

## 6. API Security

**Validation:**
- Pydantic models enforce schema at every API boundary
- Required fields fail fast with 422 if missing
- `ErrorCode(StrEnum)` provides machine-readable error codes — never opaque codes

**Rate limiting:**
- Upstream rate limits caught and mapped to appropriate status codes
- Service-level rate limiting delegated to your service mesh or infrastructure, not application-level

**Error responses:**
- Centralized error handlers map all exception types to HTTP status codes
- Error messages never include PII, internal state, stack traces, or field values
- Machine-readable error codes + human-readable messages

---

## 7. Sensitive Data in Logs, Traces & Monitoring

**General principle:** Log identifiers and metadata, never values or content.

**What must never appear in logs, traces, or error messages:**
- Highly sensitive domain values (for example credit card numbers, account balances, personal addresses where applicable)
- PII when tied to sensitive processing
- Authentication tokens and API keys
- Full request/response payloads containing sensitive data

**Enforcement:**
- `structlog` with `JSONRenderer` in production enables programmatic field redaction (see Coding Standards skill for implementation)
- Tracing tools carry correlation IDs only — not data content
- Centralized error handlers ensure error responses contain type + message only

**Monitoring stack:**
- Application metrics (request rate, error rate, latency) via your metrics system
- LLM tracing tool for prompt/completion observability
- Error tracking SDK for production error aggregation and alerting — see Coding Standards skill § Error Tracking Conventions

See PROJECT.md for the service-specific log field allowlist and sensitive field inventory.

---

## 8. Compliance (CCPA/GDPR)

**Data classification:**
- Sensitive data is subject to your organization's data handling policies
- Prefer keeping regulated data within your infrastructure — document and control any third-party data egress

**Data retention:**
- Session-scoped persistence with TTL auto-expiry where applicable
- No indefinite retention of user data in application layer
- DB-backed persistence must implement explicit retention policies and deletion APIs

**User rights:**
- Session data auto-expires via TTL (supports right to deletion by design)
- No cross-user data access — data scoped to authenticated session
- Response metadata enables consumers to present required legal disclaimers

**Audit:**
- Every request traced with correlation ID
- Responses include reliability metadata for consumer-side assessment

---

When reviewing code or writing new features, consult `references/checklist.md` for the complete security verification checklist.
