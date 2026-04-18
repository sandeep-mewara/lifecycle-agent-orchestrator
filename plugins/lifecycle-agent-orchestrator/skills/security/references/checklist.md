# Security Standards — Universal Checklist

Use this checklist when writing new code, reviewing PRs, or assessing deployment readiness. For language-specific items, see `<language>/checklist.md`.

## 1. Secret Management
- [ ] Secrets stored as references (vault paths, secret names) in settings, not literal values
- [ ] Runtime retrieval via secrets manager client — never direct reads from config
- [ ] No secrets in environment variables, container layers, config files, or source code
- [ ] Secrets pre-warmed during startup to fail fast
- [ ] Dependency lock file committed and consistent

## 2. Encryption
- [ ] All external communication over HTTPS/TLS (service mesh or gateway enforced)
- [ ] No plain HTTP endpoints exposed
- [ ] Auth tokens in headers only — never in query parameters or request bodies
- [ ] No local file storage of sensitive domain payloads

## 3. Authentication & Authorization
- [ ] Every new endpoint behind API gateway (or equivalent) auth
- [ ] Auth check enforced — only health/actuator routes exempt
- [ ] Auth headers validated via schema model with validators
- [ ] No endpoint returns data for a user other than the authenticated user
- [ ] Auth tokens never appear in log messages or error responses
- [ ] Auth failure mapped to 401 via centralized handler

## 4. OWASP / Secure Coding
- [ ] All external input validated via schema models at system boundaries
- [ ] No raw string interpolation into LLM prompts — use named template variables
- [ ] User input in message content only, never in system prompt templates
- [ ] LLM output parsed and validated before use (structure + consistency checks)
- [ ] No user-controlled URL pass-through without validation (SSRF prevention)
- [ ] Guard clauses + early returns for error handling

## 5. Dependencies & Vulnerabilities
- [ ] Dependencies pinned in manifest file
- [ ] Automated dependency update tool enabled (Dependabot, Renovate, etc.)
- [ ] Container image scanning in CI pipeline
- [ ] Container runs as non-root user
- [ ] Package registry configured appropriately

## 6. API Security
- [ ] Request schema validated — required fields fail fast with 400/422
- [ ] Machine-readable error codes used — no opaque error codes
- [ ] Error responses contain type + message only — no PII, stack traces, or internal state
- [ ] Rate limit errors from upstream caught and mapped appropriately
- [ ] Centralized error handlers cover all custom exception types

## 7. Sensitive Data Protection
- [ ] No PII or highly sensitive values in logs (payment details, account balances, government IDs, tokens)
- [ ] No PII in LLM observability traces or error messages
- [ ] Only allowlisted fields in log output
- [ ] Structured logging with field redaction configured for production
- [ ] Full sensitive payloads never logged (debug-level tracing only in local dev)

## 8. Compliance
- [ ] Session-scoped data has TTL auto-expiry
- [ ] No indefinite retention of user data at the application layer
- [ ] No cross-user data access — resources scoped to authenticated session
- [ ] Response metadata supports consumer-side disclaimer rendering
- [ ] Prefer processing within your infrastructure — document any third-party data egress
