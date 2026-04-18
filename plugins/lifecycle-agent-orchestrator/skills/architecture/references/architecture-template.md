# Architecture Decision Record (ADR) Template

Use this template for significant architectural decisions — the ones where trade-offs are non-obvious and future team members will need to understand *why*. Not every decision needs an ADR. If the choice is straightforward and widely understood, skip the formality.

---

## ADR-[NNN]: [Title — short imperative phrase]

**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-NNN]
**Date:** [YYYY-MM-DD]
**Author(s):** [Names]

---

### Context

What problem or opportunity are we responding to? What constraints exist (technical, regulatory, timeline)? Be specific — link to Jira tickets or Confluence docs where the discussion happened.

---

### Decision

State the decision in one or two sentences. Then briefly elaborate: what approach was chosen and how it fits into the existing system architecture.

---

### Alternatives Considered

For each meaningful alternative:

**[Alternative Name]**
- What it looks like, what it does well, why it was not chosen.

Keep this proportional — two strong alternatives need documentation, five weak ones don't.

---

### Trade-offs

What are we gaining and what are we giving up?

| Dimension   | Gain                       | Cost                        |
|-------------|----------------------------|-----------------------------|
| [e.g., Simplicity] | [e.g., fewer moving parts] | [e.g., less flexibility] |

Only include dimensions that are actually relevant to this decision.

---

### Consequences

**What changes:** [What gets better, what gets harder, what follow-up work is needed]

---

### Considerations

Answer only the questions that apply to this decision — skip the rest.

- **Security:** Does this introduce new PII/financial data flows? New auth requirements? Secrets via a secrets manager?
- **Compliance / Regulatory:** Does this affect data retention, audit trails, or regulatory requirements? Are there jurisdiction-specific constraints? If uncertain, flag for human confirmation.
- **Scalability:** What's the expected load? Where are the bottlenecks? Can it scale horizontally?
- **Resiliency:** What happens when this fails? What's the blast radius? Is a fallback needed?
- **Observability:** Can we trace requests through this component? What metrics indicate health? What does "unhealthy" look like and what should alert?

---

### Component / Agent Design (if applicable)

Include a Mermaid diagram if it helps. For each new component or agent:

| Name | Responsibility | Input | Output | Failure mode |
|------|---------------|-------|--------|--------------|
| [name] | [one sentence] | [contract] | [contract] | [behavior] |

If agents are involved: state the orchestration pattern (sequential, router, parallel, supervisor) and why it fits.

---

### Checklist

Before marking Accepted:

- [ ] This is the simplest design that meets the requirements
- [ ] Each new component has a single, clear responsibility
- [ ] Security implications are addressed (if PII/financial data is involved)
- [ ] Compliance/regulatory implications are addressed or flagged for human confirmation
- [ ] Failure modes are understood (fallbacks defined where needed)
- [ ] Observability is planned (tracing, metrics, alerting for critical paths)
- [ ] Trade-offs are explicitly stated
- [ ] Decisions requiring human confirmation are clearly marked
