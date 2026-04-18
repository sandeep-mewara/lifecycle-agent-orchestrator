# Coding Standards — Universal Checklist

Use this checklist when writing new code, reviewing PRs, or setting up new projects. For language-specific items, see `<language>/checklist.md`.

## When Writing or Modifying Code

### Naming
- [ ] Functions/methods use verb-first descriptive names in the language's convention
- [ ] Classes use descriptive nouns
- [ ] Variables are descriptive — no single-letter names outside loops, no abbreviations
- [ ] Booleans prefixed with `is`/`has`/`can`/`enable`
- [ ] Constants use the language's constant convention
- [ ] Exception/error classes use `Error` or `Exception` suffix
- [ ] File names follow the language's convention and match the primary type

### Error Handling
- [ ] Domain-specific typed exception classes — no generic exceptions
- [ ] Machine-readable error codes (descriptive, never opaque codes)
- [ ] Centralized error-to-HTTP-response mapping
- [ ] Catch blocks ordered: specific exceptions first, generic last as safety net
- [ ] Always log before re-raising exceptions
- [ ] Exception chains preserved (cause attached)
- [ ] Engine/domain errors → retry-then-degrade, log-and-skip, or fail-fast per type
- [ ] Service boundary: catch engine errors → log detail → return user-safe message
- [ ] Tracked errors carry correlation ID, error type, relevant identifiers — no PII

### Structured Logging
- [ ] Structured logging framework used (not print statements)
- [ ] JSON renderer in production, human-readable in local dev
- [ ] Log levels match the decision matrix (ERROR/WARNING/INFO/DEBUG)
- [ ] No print statements in production code
- [ ] Context binding at entry points with correlation ID
- [ ] Log at operation boundaries: entry/exit of key operations
- [ ] No PII in log messages — see Security skill for allowlist

### Data Models
- [ ] Schema validation framework used for all data contracts
- [ ] Type annotations on all function signatures
- [ ] Validated models for inbound requests and external responses

### Imports / Dependencies
- [ ] Import groups separated: standard library → third-party → internal
- [ ] No unused imports
- [ ] No circular dependencies

## When Setting Up a New Project

### Configuration
- [ ] Environment-based settings hierarchy (base → pre-prod/prod → local/CI)
- [ ] Settings factory returns singleton per environment
- [ ] Secrets resolved via secrets manager — never hardcoded
- [ ] Never put secrets in environment variables or source control

### Project Structure
- [ ] Separation of concerns: router / service / models / adapters / persistence
- [ ] Test directories mirror source layout (unit + integration)
- [ ] Configuration isolated in its own module/package

### Tooling
- [ ] Formatter configured and enforced in CI
- [ ] Linter / static analysis configured and enforced in CI
- [ ] Type checker configured (enforced or IDE-integrated)
- [ ] Test runner with coverage reporting
- [ ] Dependency lock file committed

### App Initialization
- [ ] Required dependencies initialized first
- [ ] Optional features use graceful degradation — fail without crashing startup
- [ ] Resource cleanup on shutdown via lifecycle management
- [ ] Correlation ID middleware/filter propagates through request lifecycle
