# Architecture Review Checklist

Use this when reviewing code, PRs, or designs. Not every item applies to every review — use judgment. The goal is to catch real problems, not to enforce bureaucratic completeness.

**Before diving into specifics, ask:** Is this change more complex than it needs to be? Could it be simpler and still meet the requirements?

---

## 1. Simplicity

- [ ] The design is the simplest approach that meets the requirements
- [ ] No premature abstractions, unnecessary indirection, or speculative future-proofing
- [ ] New components justify their existence with a concrete rationale

---

## 2. Single Responsibility

- [ ] Each module has one clear purpose describable in a single sentence
- [ ] Routing logic and business logic are not mixed in the same file
- [ ] Agent prompts serve a single bounded concern

**Red flags:** Classes named "Manager" or "Helper" doing too many things; a PR modifying both routing and business logic in one file.

---

## 3. Security

- [ ] No PII or financial data in logs, error messages, or traces
- [ ] New endpoints enforce Authz checks
- [ ] Secrets come from a secrets manager (no hardcoded credentials)
- [ ] External inputs validated at system boundaries via Pydantic models
- [ ] No raw string interpolation into prompts, queries, or commands

For comprehensive security conventions and code examples, see the **Security skill** (`skills/security/`).

---

## 4. Resiliency

- [ ] External API calls have timeouts and retry policies
- [ ] Tool failures don't crash the entire agent workflow
- [ ] Degraded responses are meaningful, not generic 500 errors

---

## 5. Observability

- [ ] New agent workflows and tool calls are covered by Langfuse tracing
- [ ] Trace spans fit the existing hierarchy (router → agent service → agent → tool → external API)
- [ ] Key metrics are emitted (latency, success/failure, token usage where applicable)
- [ ] Logs use structured format with `transaction_id` correlation
- [ ] No PII or financial data leaks into traces, metrics, or logs
- [ ] Health checks test real dependencies, not just return 200

Only flag observability gaps for components on critical paths or those handling user data. A utility helper doesn't need custom metrics.

---

## 6. Scalability

- [ ] No in-process mutable state that breaks with multiple replicas
- [ ] No blocking calls in the async event loop
- [ ] Agent context windows are right-sized for the task

Only flag scalability concerns if the change introduces a pattern that has a hard scaling ceiling. Don't flag hypothetical scale issues at current load.

---

## 7. Code Quality

- [ ] Follows project conventions (Black, isort, mypy, Pydantic models)
- [ ] Self-documenting names (no comments needed to explain variable purpose)
- [ ] Consistent with existing patterns in `app/models/`, `app/service/`, `app/router/`
- [ ] Tests cover the happy path and key failure modes

---

## 8. Multi-Agent Design (when applicable)

- [ ] Splitting into multiple agents has a clear rationale (not just "it feels cleaner")
- [ ] Each agent's responsibility, contract, and failure mode are documented
- [ ] Agent failures are isolated — one agent's failure doesn't cascade

---

## Severity Guide

| Severity | When to use | Examples |
|----------|-------------|---------|
| **Blocker** | Must fix before merge | Security vulnerabilities, PII leaks, broken contracts |
| **Warning** | Should fix or track as follow-up | Missing timeouts, unclear naming, no fallback |
| **Suggestion** | Author's discretion | Alternative patterns, readability tweaks |

---

## Review Output

```
## Summary
[1-2 sentences: what changed, overall assessment]

## Blockers
- [file:line] — [issue and why it's a blocker]

## Warnings
- [file:line] — [issue and recommendation]

## Suggestions
- [file:line] — [suggestion]

## What's Good
- [Reinforce good patterns]
```
