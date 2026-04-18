# The Lifecycle Is the Product: Turning Your Dev Process Into a Portable Engine

Walk into any engineering org today and you'll find two camps doing the same work differently.

One still does it by hand. The PM writes a PRD in a wiki. The designer hands off Figma links over Slack. The architect scribbles a diagram on a whiteboard. The engineer reads a Jira ticket, codes, opens a PR, and hopes the reviewer remembers what the spec said. Each role has a playbook; each plays it in its own silo.

The other camp has started leveraging AI for role-specific work. The PM runs a skill that drafts the PRD. The architect asks Claude to review a PR. The security lead has a skill that sweeps for auth and secret-handling issues. Role work has gotten faster. The silos have not.

The first camp will eventually join the second — the leverage is too obvious to ignore. A well-tuned role skill is a step-change in individual output. A PM drafts a PRD in a fraction of the time. An architect does a structured review in minutes. That's the jumpstart, and it's real.

But the jumpstart lands each team at the same wall the AI-early-adopters hit months earlier, and it's the same wall: **the skills are portable, the lifecycle around them is not.**

The PRD still lives in its own tab. The design review still happens in Slack. The architect still sees the PRD *after* engineering has started, when it's expensive to change. Acceptance criteria still drift between the ticket, the tests, and the PR description. "Ship" still means "status set to done" rather than "every criterion proven." Each role has become faster in its silo, and the handoffs between silos have only gotten more painful because the bottleneck moved there.

That gap — and the opportunity inside it — is what the [Lifecycle Agent Orchestrator](https://github.com/sandeep-mewara/lifecycle-orchestrator) closes. It's a plugin for Claude Code and Cursor that ships the development lifecycle itself — requirements through pull request — as a versioned, overridable artifact. Not just the individual role skills. The stitching between them.

The framing I keep returning to: the skills are the actors, but the lifecycle is the director. A team can install a better actor in a day. Installing a director has required rebuilding scaffolding from scratch, in every project, every time. Until now.

This post is about why that shape is worth defending, and the design calls it forces.

## The Idea

Treat the lifecycle as an engine. A small, opinionated engine that:

1. Knows the phases and their order.
2. Composes universal skill content with project-specific rules at runtime, without duplication.
3. Enforces cross-role reviews where they actually prevent rework — at the front of the pipeline, not the end.
4. Produces structured outputs at every phase, so a future UI can render the pipeline without an API rewrite.
5. Runs a full preview before touching anything real.

The engine itself is portable. The project-specific pieces — your architecture patterns, your test framework, your deploy process — live in the project repo as overlays. On conflict, the project wins, because the project is the domain authority.

## First, the Actors — On Their Own

Before the orchestrator, a point worth making: every role skill in this plugin is independently invocable. You don't need `/lao` to get value out of them.

A PM who wants a PRD drafted without running the full pipeline can reach for `product-management` directly. An architect doing a one-off review of someone else's PR can invoke `architecture`. An engineer who needs a Jira ticket turned into a clean scope summary with real acceptance criteria can invoke `intake`. A security lead sweeping a change for auth and secret-handling concerns can invoke `security` on its own.

```
Invoke architecture skill to review this PR for architectural alignment
Invoke code-review skill to review these changes
Invoke intake skill to extract scope from PROJ-5678
```

This matters for two reasons. First, each role gets an immediate, low-commitment win the moment the plugin is installed — nobody has to adopt the full lifecycle to benefit. A QA lead can use `acceptance-validation` tomorrow without running a single `/lao` command. Second, it makes clear what the orchestrator is actually doing later. The director needs actors who can already perform solo; these solo invocations are those actors.

Step one is reaching for a skill when you need it. Step two is letting the orchestrator stitch them together into a lifecycle.

## A Quick Glimpse of Step Two

Once you trust the individual skills, the composition is one command inside a Claude Code or Cursor session:

```
/lao Work on PROJ-1234
```

That kicks off a preview of the nine-phase pipeline — no files written, no branches created, no Jira comments posted. You iterate on scope, design, and plan. When you're ready, you say `proceed` and the same decisions carry forward into real execution.

For an ungrounded requirement you can give it prose:

```
/lao Add a user notification preferences API endpoint
```

And for a tire-kick before committing to anything:

```
/lao-dry-run
```

## How It Works

The pipeline is nine phases, grouped into two halves with different personalities:

```
Phase 1: Product Management        ┐
Phase 2: Experience Design  (cond.) ├─ PRD-level, cross-reviewed
Phase 3: Architecture (System)      ┘

Phase 4: Intake          ┐
Phase 5: Tech Design     │
Phase 6: Plan            ├─ Per ticket, pure execution
Phase 7: Implement       │
Phase 8: Validate        │
Phase 9: Ship            ┘
```

Phases 1–3 are where the humans align. Each output is cross-reviewed by the other two roles — PM's PRD is read by XD and Architecture; XD's design is read by PM and Architecture; Architecture's system design is read by PM and XD (if XD ran). Maximum two revision rounds per gate; past that, the orchestrator escalates to the human.

Phases 4–9 run per ticket with no more cross-reviews. Alignment has already happened. What's left is execution: extract scope, design at ticket level, plan, implement, validate, ship.

Under the hood, each phase composes up to three layers of knowledge:

| Layer | Lives in | Contains |
|---|---|---|
| Base | plugin | Universal rules for the role |
| Overlay | project | Project-specific patterns, stack, conventions |
| Domain | project | Cross-cutting domain knowledge (auth, payments, compliance) |

A project looks like this once it's connected:

```
your-project/
└── skills/
    ├── architecture/PROJECT.md         # Overlay on base architecture skill
    ├── coding-standards/PROJECT.md     # Overlay on base coding skill
    ├── testing-conventions/PROJECT.md  # Overlay on base testing skill
    ├── compliance-review/SKILL.md      # Extra role: no base equivalent
    └── domain/
        ├── auth-system.md              # Domain: applies to all phases
        └── payment-processing.md       # Domain: scoped to some phases
```

If a project already has its architecture docs scattered across `docs/`, there's no need to move anything. A `lao.config.yaml` at the project root maps existing files into the engine:

```yaml
project_name: my-app
languages: [python, react]

overlays:
  architecture: docs/architecture/standards.md
  coding-standards: .cursor/rules/coding.md

domain:
  - docs/domain/*.md
  - src/payments/DESIGN.md

extra_roles:
  compliance-review: tools/compliance/SKILL.md
```

Two discovery paths — convention directory or config file — and config wins when both exist. The reason for supporting both is covered below under design decisions.

## Preview, Then Execute

The single most underrated feature is the preview mode. Every run begins in simulation. The orchestrator walks Phases 1–6 as if it were executing, produces realistic `PhaseOutput` objects, presents checkpoints, and lets you iterate. Phases 7–9 are summarized as projected outcomes because they depend on real code running.

When you're ready, you say `proceed` and the pipeline replays — but with the preview's decisions carried forward instead of regenerated:

```
/lao Add a notification preferences API
        │
        ▼
  PREVIEW (no real changes)
    → Iterate on scope, ACs, design, plan
    → Adjust any phase, or abort
        │
        ▼
  "Preview complete. Proceed with implementation?"
        │
        ▼
  EXECUTE (real changes, preview decisions reused)
    → Phases 1–6 use preview outputs (not regenerated)
    → Phases 7–9 run fresh (actual code, tests, PR)
```

The critical property: preview thinking isn't thrown away. It becomes the execution's starting point. So the cost is roughly zero and the risk of committing to the wrong plan is also roughly zero.

## Acceptance Criteria, Tracked Across Phases

Every phase emits a `PhaseOutput` — a structured object with a defined schema. The CLI renders it as text today; a dashboard could render it visually tomorrow without any change to the engine. This is why the contract exists from day one:

```
--- Phase: Tech Design (Phase 5 of 9) ---
Status: Needs Approval

SUMMARY:
  Add rate limiting middleware to API gateway.
  No new dependencies, config-driven thresholds.

ARTIFACTS:
  - [design_doc] docs/design/rate-limiting.md

ACCEPTANCE CRITERIA (tracked):
  AC1: Rate limit of 100 req/min per user .............. pending
  AC2: Returns 429 with retry-after header ............. pending
  AC3: Configurable per environment .................... pending

→ Approve to proceed to Plan, or request changes.
```

Those ACs are captured in Phase 4 (Intake) and tracked until Phase 8 (Validate), where each one must be proven with recorded evidence before shipping. No claims without fresh proof — that's the whole point of the validation gate.

## Multi-Language, Without a Fork Per Language

Four skills need to know what language they're looking at: `coding-standards`, `testing-conventions`, `code-review`, and `security`. Each has a universal base and a **language pack** for the specifics:

```
skills/coding-standards/
├── SKILL.md                  # Universal principles
└── references/
    ├── checklist.md          # Universal checklist
    ├── python/               # Language pack
    │   ├── checklist.md
    │   ├── examples.md
    │   └── tooling-config.md
    ├── java/
    ├── csharp/
    └── react/
```

Detection runs once at pipeline start: if `lao.config.yaml` lists languages, use them; otherwise scan for `pyproject.toml`, `pom.xml`, `*.csproj`, `package.json` with a React dep, and collect every match. A full-stack repo auto-detects as `[python, react]`, and both packs get loaded. The agent applies each to the right file types.

Adding a new language — Go, Rust, anything — means creating a `references/<language>/` directory in those four skills with the expected files, plus a couple of lines in detection and validation scripts. No change to the universal base. That separation is worth preserving.

## Design Decisions Worth Talking About

Portable systems live or die by the decisions no one notices until they break. A few are worth calling out.

### Role skills for Phases 1–5, execution workflows for Phases 6–9

This looks like an inconsistency on first read. It isn't. It's the most deliberate split in the design.

Phases 1–5 embody personas whose judgment varies wildly by project. A fintech architecture review emphasizes audit trails and regulatory compliance; a game studio cares about frame budgets and asset pipelines. Those differences belong in project overlays, and each role (PM, XD, Architecture, Intake) has its own skill file so overlays have somewhere to land. Architecture is the only role used in two phases — system-level in Phase 3, ticket-level in Phase 5 — which is why there are four role skills for five phases.

Phases 6–9 are the orchestrator's own engine — decompose the design into TDD tasks, run red-green-refactor, prove each AC with evidence, ship the PR. They're tightly coupled (plan structure dictates implement structure; implement results feed validate checks), and they're *universal by default*. A single workflow document in the plugin preserves that continuity instead of fragmenting it across four disconnected skill invocations.

Override paths exist for both halves — overlays for 1–5, workflow overrides for 6–9 — but they work differently, and that's intentional:

```yaml
# Override the workflow for a single phase
workflows:
  implement: docs/workflows/our-bdd-process.md   # BDD instead of TDD
  ship: docs/workflows/our-release-process.md    # custom release flow
```

Workflow overrides **replace** the built-in workflow. They're not additive. Methodology changes like TDD → BDD are substitutions, not layers. Role overlays, on the other hand, merge with the base because projects add context without throwing the universal rules away. The two override semantics reflect what each layer actually is.

### Overlay-wins precedence

When a base skill says one thing and a project overlay says another, the overlay wins. This is the project respecting itself as the domain authority — no universal skill can anticipate every team's reality.

The risk is obvious: a project could silently relax a safety rule from the base and no one would notice. The mitigation is small but important. Overlays are expected to carry an `## Overrides` section with a rationale, and the orchestrator surfaces those overrides at the human checkpoint. The override applies regardless; the rationale is for the human to see what they're approving.

I prefer this model to the alternative (base-wins or merge-refusal). The base-wins model makes the plugin a straightjacket; the merge-refusal model makes every overlay a political negotiation. Overlay-wins with visible rationale is honest about who owns what.

### Config file *and* convention

Two discovery methods is more complexity than one. It earns its keep.

A convention-only model forces every existing project to move files into `skills/<role>/PROJECT.md`, duplicate content that already lives in `docs/` or `.cursor/rules/`, or symlink its way out of the problem. That's the fastest way to make a portable tool unportable. So an optional `lao.config.yaml` lets projects map existing paths without restructuring. Globs work. Domain files can live anywhere.

If both exist, the config wins. The convention is never merged into the config. And a suggestion scan at pipeline start helps teams discover markdown files that look like overlays but aren't connected yet.

### Front-loaded cross-reviews

The earlier iteration of the design ran cross-reviews per ticket. Each story triggered its own design cycle and review rounds. It was thorough and it was awful — estimates were unreliable because design wasn't complete, architects couldn't determine ticket dependencies without seeing the full experience, and per-ticket reviews kept re-litigating alignment the team had already reached.

The current design pulls all three cross-reviews into Phases 1–3, runs them once, and lets Phases 4–9 be pure execution. XD produces the complete experience design at PRD level — not pixel-perfect, but enough for architecture and implementation to proceed. Architecture gets both PRD and XD as context for system design, which dramatically improves dependency analysis and ticket ordering.

The trade-off: Phase 2 can be heavy for UX-heavy PRDs. Mitigated by making it conditional (skipped for backend-only work) and by a clear scope ceiling: enough for engineering to proceed, not a full visual design system.

### A plugin, not a runtime agent

Early drafts considered a LangGraph-backed runtime agent with a server and a database — persistent audit trails, unattended execution, multi-user coordination. The primary use case didn't justify it. The real workload is "Jira to PR" inside a developer's Claude Code session. Git history and Jira transitions already provide the audit trail. The execution environment already exists. A runtime agent is valid future evolution for unattended workflows; it's the wrong starting point.

## What Makes This Interesting

A few patterns here generalize beyond this plugin.

**Structured output as the UI contract.** Committing to `PhaseOutput` from day one — even when the only consumer is CLI text — means a dashboard is purely additive later. No backend, no separate API; same objects, different renderer. More teams should write their internal tools this way.

**Two-tier domain loading.** Domain files have frontmatter scanned once at pipeline start (the index tier) and full content loaded only when `applies_to` and the description match the current phase's task (the load tier). Context stays proportional to relevance instead of growing linearly with documentation.

**Overrides that surface themselves.** An overlay that silently disables a base rule is dangerous. An overlay that disables it and surfaces the rationale at the next human checkpoint is honest. Small primitive, big difference in trust.

## Bringing This Into Your Project

Adoption doesn't have to be a cliff. The plugin is deliberately structured so each step is useful before the next one pays off — a land-and-expand path, not a commitment-in-advance.

**Step 1 — Install and use a single skill.** The moment the plugin is installed, any engineer on the team can invoke any role skill on their current work. No setup, no config, no lifecycle buy-in:

```
/plugin marketplace add sandeep-mewara/lifecycle-orchestrator
/plugin install lifecycle-agent-orchestrator@lifecycle-agent-orchestrator
```

From here, `Invoke architecture skill to review this PR` is a complete, useful interaction. This alone typically pays back the install cost.

**Step 2 — See the shape of the full pipeline.** `/lao-dry-run` simulates all nine phases against a bundled sample requirement — no files, no git, no Jira, no PRs. It's the cheapest possible preview of what the orchestrator feels like before running it on something real. Custom input works too: `/lao-dry-run Add a user notification preferences API endpoint`.

**Step 3 — Connect your project's existing docs.** `/lao-setup` scans your repo for architecture docs, coding standards, domain knowledge, and other skill-like files, then offers two wiring paths — `lao.config.yaml` if you want to keep your existing layout, or the convention directory if you're starting fresh. You do not rewrite your documentation to fit the plugin. The plugin adapts to what you already have.

**Step 4 — Run the full pipeline.** Once overlays are wired, the orchestrator is one command against a ticket or a raw requirement. Preview runs first, execution runs on `proceed`, and human checkpoints stay live throughout.

A team that only makes it to Step 1 still benefits — the solo skills are the backbone. A team that makes it to Step 4 gets the full lifecycle: cross-role review gates, AC tracking across phases, and a PR that ships with recorded evidence instead of a shrug. Either way, no one has to take on the whole lifecycle on day one to earn the first win.

## When to Use This, and When Not

The fit is strongest when the work looks like this: Claude Code or Cursor for coding, Jira or a PRD-driven intake, a team that cares about front-loading design and tracking ACs through to ship. Multi-language repos and monorepos are first-class — config-based discovery handles the awkward shapes.

The fit is weak when the work is ad-hoc (no tickets, no PRDs, no ACs to track), when "ship" means something the plugin doesn't model (a mobile store submission, a complex release train), or when the team genuinely wants unattended, long-running autonomous execution. The plugin is a human-in-the-loop engine. It's not trying to be an autonomous one — yet.

## What Changes When You Adopt It

The most immediate change is that the lifecycle leaves your wiki and enters your repo. It becomes a plugin you can version, test, and evolve. Updating the base skill ripples to every project that uses it. Adding a new language pack is a few files. Adding a compliance role is an `applies_to` and a markdown file.

The bigger change is structural: the handoffs stop being documents and start being gates. PM, XD, and Architecture see each other's work before any code is written. Acceptance criteria are objects, not bullet points in a ticket. Validation is a gate that demands evidence, not a status someone marks `done`. Shipping is a contract that includes what was proven.

Neither camp has to take a leap. The team still doing role work manually adopts a skill at a time, and wins immediately. The team already AI-augmented adopts the orchestrator on top, and stops paying the silo tax. The wall both camps were going to hit becomes the thing that's already handled.

I expect the next iteration of this kind of tool to assume all of that. For now, it's worth building by hand — or, more precisely, worth installing.

---

**Further reading**: the [design spec](plugins/lifecycle-agent-orchestrator/docs/2026-04-04-lifecycle-agent-orchestrator-design-spec.md) captures the ADRs — eight of them — that shaped the decisions above. The [phase output contract](plugins/lifecycle-agent-orchestrator/contracts/phase-output-schema.md) is the quiet foundation the rest of the engine builds on. Both are short, and both reward a read.
