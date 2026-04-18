---
name: security-standards
description: Enforces security standards when writing or reviewing code that handles authentication, secrets, sensitive data, API boundaries, or compliance concerns. Covers secrets manager integration, encryption at rest and in transit, IAM authentication and least-privilege authorization, OWASP Top 10 secure coding (including prompt injection), dependency vulnerability management, API security (auth, validation, rate limiting), PII and sensitive data protection in logs and traces, and regulatory compliance (CCPA/GDPR). Use this skill when adding endpoints, handling user data, managing secrets, reviewing for vulnerabilities, configuring auth, working with LLM prompts that accept user input, setting up deployment security, or assessing compliance. Also use when DAST findings need remediation.
---

# Security Standards

Standards for services that handle sensitive data — where security failures can expose PII, regulated or highly sensitive domain data, and authentication credentials. These are non-negotiable in code review; violations are blockers, not suggestions.

**Bundled references** (read when you need checklists or code examples):
- `references/checklist.md` — Universal security review checklist (8 sections)
- `references/<language>/checklist.md` — Language-specific security checklist
- `references/<language>/examples.md` — Language-specific code examples for key patterns

Where `<language>` is `python`, `java`, or `csharp` — determined by the project's `lao.config.yaml` or auto-detected at pipeline start.

---

## 1. Secret Management

Never hardcode secrets. Config stores secret references (managed paths or secret names); runtime retrieves actual values.

**Rules:**
- Secrets stored as references (such as vault paths, secret names, or key identifiers) in settings, never as literal values
- Runtime retrieval via a secrets manager client with lazy caching
- Pre-warm secrets during app startup to fail fast if the secrets backend is unreachable
- Never put secrets in environment variables, container layers, config files, or source code
- Dependency lock file committed for reproducible builds

See `references/<language>/examples.md` for a secrets manager client pattern.

---

## 2. Data Protection — Encryption at Rest and in Transit

**In transit:**
- All traffic over HTTPS/TLS via your service mesh or gateway — no plain HTTP endpoints
- LLM API calls go through your HTTPS proxy or a vetted egress path where required
- Auth tokens transmitted only in headers, never in query parameters or request bodies

**At rest:**
- Platform-managed encryption at rest for all data stores — application does not manage encryption keys
- Sensitive data classified accordingly — treat equivalently to PII for storage where policies apply
- No local file storage of sensitive data
- DB-backed persistence must use platform-managed encryption

**What is sensitive (minimum):**
- User authentication tokens and API keys
- Secrets manager credentials and references
- Any regulated or highly sensitive domain fields (see PROJECT.md for service-specific examples)

---

## 3. Authentication & Authorization

**Authentication — identity headers on every request:**
- Auth headers validated via schema model with validators — rejects malformed tokens at parse time
- API gateway auth enforced — explicit allowlist for unauthenticated routes (health/actuator only)
- Auth client initialized at startup; graceful degradation if unavailable

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
- Schema models validate all external input at system boundaries (API requests, tool inputs)
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
- Environment identifier drives config — misconfiguration falls back safely to dev defaults
- Debug-level logging disabled in production settings

**SSRF prevention:**
- URLs validated before server-side fetch
- No user-controlled redirect following
- No pass-through of user-provided URLs to external systems without sanitization

---

## 5. Dependency Management & Vulnerability Scanning

**Dependency hygiene:**
- Automated dependency update tool configured (Dependabot, Renovate, or equivalent)
- Dependencies pinned in the project's manifest file, lock file committed
- Use your organization's package registry when mirroring or vetting dependencies

**Container security:**
- Container image scanning in CI pipeline
- Non-root container user in Dockerfile
- Multi-stage build — dev/test dependencies excluded from runtime image

**Vulnerability response:**
- Dependency update PRs reviewed weekly — security patches prioritized over feature updates
- Lock file conflicts resolved by regenerating from the updated manifest, not by manual editing

---

## 6. API Security

**Validation:**
- Schema models enforce validation at every API boundary
- Required fields fail fast with appropriate HTTP error (400/422) if missing
- Machine-readable error codes — never opaque codes

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
- Highly sensitive domain values (e.g., payment details, account balances, government IDs)
- PII when tied to sensitive processing
- Authentication tokens and API keys
- Full request/response payloads containing sensitive data

**Enforcement:**
- Structured logging with JSON output in production enables programmatic field redaction
- Tracing tools carry correlation IDs only — not data content
- Centralized error handlers ensure error responses contain type + message only

**Monitoring stack:**
- Application metrics (request rate, error rate, latency) via your metrics system
- LLM tracing tool for prompt/completion observability
- Error tracking for production error aggregation and alerting

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

When reviewing code or writing new features, consult `references/checklist.md` and `references/<language>/checklist.md` for the complete security verification checklist.
