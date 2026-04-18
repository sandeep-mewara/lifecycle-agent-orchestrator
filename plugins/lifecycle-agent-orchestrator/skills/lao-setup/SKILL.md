---
name: lifecycle-agent-orchestrator-setup
aliases: [lao-setup]
description: >
  Interactive setup for connecting project-specific skills to the lifecycle agent orchestrator.
  Scans the project for existing architecture docs, coding standards, domain knowledge,
  and other skill-like files, then helps the user choose between config-based mapping
  (lao.config.yaml) or convention-based directory structure. Generates the chosen
  structure and validates it. Trigger when the user says "set up the orchestrator", "configure
  project skills", "bootstrap the orchestrator", "connect my project", or
  "lao-setup".
---

# Lifecycle Agent Orchestrator — Project Setup

You are running the interactive project setup for the lifecycle agent orchestrator. Your job
is to scan the user's project, help them connect their existing files to the
orchestrator, and validate the result.

## Process

Follow these steps in order. Present clear output at each step and wait for
human confirmation before proceeding to the next.

### Step 1 — Scan the project

Scan the project root for files that look like potential skill content.

**Language detection:** Detect the project's languages by checking **all**
rules and collecting every match (a project can match more than one):
- `pyproject.toml`, `setup.py`, or `requirements.txt` → `python`
- `pom.xml`, `build.gradle`, or `build.gradle.kts` → `java`
- `*.csproj` or `*.sln` → `csharp`
- `package.json` with `react` in dependencies, or `next.config.*` → `react`
- If no match → ask the user during Step 3

Include the detected languages in the scan results summary:

**Overlay candidates:** Markdown files whose names contain lifecycle-relevant keywords
(`architecture`, `coding-standards`, `testing-conventions`, `code-review`,
`shipping`, `design`, `conventions`, `standards`, `patterns`, `intake`,
`acceptance`, `product-management`). Search common locations:
- `docs/`, `wiki/`, `.cursor/rules/`, project root
- Exclude `node_modules/`, `.git/`, `vendor/`, `build/`, `dist/`

**Domain candidates:** Markdown files with YAML frontmatter containing both
`name` and `description` fields. These could be domain context files.

**Extra role candidates:** Markdown files with YAML frontmatter containing both
`name` and `description` that don't match any base role keyword.

Present findings in a clear summary:

```
=== Project Scan Results ===

Detected languages: python (from pyproject.toml), react (from package.json)

Potential overlays (files that could customize base roles):
  docs/architecture/standards.md → architecture
  .cursor/rules/coding.md → coding-standards
  docs/review-checklist.md → code-review

Potential domain context (cross-cutting knowledge):
  docs/domain/auth-system.md (has frontmatter: name, description, applies_to)
  docs/domain/data-model.md (has frontmatter: name, description)
  src/payments/DESIGN.md (has frontmatter: name, description)

Potential extra roles:
  tools/compliance/SKILL.md (name: compliance-review)

No matches:
  (Files that looked promising but didn't have the right structure)
```

If the project already has a `lao.config.yaml`, report it:
```
Found existing lao.config.yaml — this project is already configured.
Run /lao to start the pipeline, or continue to re-scan and update.
```

If a convention directory (`skills/`) already exists with role subdirectories, report it:
```
Found convention directory: skills/
This project already uses convention-based discovery.
Continue to review and validate, or switch to config-based setup.
```

### Step 2 — Choose discovery method

Present the two options and ask the user which to use:

```
How would you like to connect these files?

Option A: Config file (lao.config.yaml)
  Maps your existing files wherever they are. No moving or copying.
  Best for: existing projects, established directory structures, monorepos.

Option B: Convention directory (skills/)
  Creates a standard directory and copies/symlinks files.
  Best for: new projects, teams starting fresh, simple layouts.

Which option? (A/B)
```

If the scan found nothing, say so and still offer both options — the user might
want to create files from scratch.

### Step 3 — Gather details

**If Option A (config):**

1. Ask for the project name (suggest based on directory name or package.json)
2. Confirm the detected languages (or ask if detection found none):
   ```
   Detected languages: python, react. Correct? (y/n)
   ```
   If user says no, ask which languages apply (any combination of
   `python`, `java`, `csharp`, `react`, or omit for auto-detection).
3. Walk through each scan finding and ask whether to include it:
   ```
   Include docs/architecture/standards.md as architecture overlay? (y/n)
   Include docs/domain/auth-system.md as domain context? (y/n)
   ```
4. Ask if there are additional files not found by the scan that should be included
5. For domain files without `applies_to` frontmatter, note they'll default to `all`

**If Option B (convention):**

1. For each overlay candidate: ask whether to create the overlay directory under
   `skills/` and copy the content, or create an empty `PROJECT.md` template to fill in later
2. For domain candidates: ask whether to copy into `skills/domain/` or create templates
3. For extra roles: ask whether to include; confirm `applies_to` scoping for each

### Step 4 — Generate

**If Option A (config):**

Generate `lao.config.yaml` at the project root with the confirmed mappings.
Use the annotated format from `examples/lao.config.yaml` as reference. Include
only sections that have entries (omit empty `overlays:`, `domain:`, `extra_roles:`).

**If Option B (convention):**

Create the `skills/` directory tree. For each confirmed item:
- Overlays: create `skills/<role>/PROJECT.md` with a starter template that includes
  an `## Overrides` section and references the base skill
- Domain files: copy the file into `skills/domain/` or create a template with proper
  frontmatter (`name`, `description`, `applies_to`)
- Extra roles: create `skills/<role>/SKILL.md` with frontmatter template including
  `applies_to` (ask user which phases/roles it applies to; warn that omitting
  `applies_to` means the role will not be loaded at any phase)

### Step 5 — Validate

Run the validation logic appropriate to the chosen method:

**Config:** Parse the generated `lao.config.yaml`, verify all paths exist,
check overlay keys match base roles, validate domain frontmatter, check extra
role keys don't match base roles. Report results in the same format as
`validate-project-skills.sh --config`.

**Convention:** Walk the generated directory, verify overlays match base roles,
check frontmatter on extra roles and domain files (including `applies_to` on
extra roles — warn if missing). Report results in the same format as
`validate-project-skills.sh`.

If validation fails, help the user fix the issues before proceeding.

### Step 6 — Next steps

Print a summary and guide the user to their next action:

```
=== Setup Complete ===

Project: <project-name>
Languages: python, react
Method: lao.config.yaml (or: convention directory)
Overlays: architecture, coding-standards, code-review
Domain context: auth-system (all), data-model (all)
Extra roles: compliance-review

Next steps:
  1. Run /lao-dry-run to test the full pipeline with your project skills
  2. Run /lao to start real work
  3. Edit your overlays/domain files to add project-specific knowledge

Validation commands (from terminal):
  ./plugins/lifecycle-agent-orchestrator/scripts/validate-project-skills.sh --config lao.config.yaml
  ./plugins/lifecycle-agent-orchestrator/scripts/validate-project-skills.sh --scan .
```

## Base Roles Reference

These are the base role names used for overlay key matching:

| Role | Description |
|---|---|
| `architecture` | System design, ADRs, architectural review |
| `coding-standards` | Coding conventions and standards enforcement |
| `testing-conventions` | Test patterns, quality, and coverage standards |
| `code-review` | PR and code review with severity classification |
| `shipping` | PR creation, Jira updates, ship workflow |
| `product-management` | PRD creation and Jira ticket generation |
| `intake` | Story reader and scope extractor |
| `experience-design` | UX research, design options, specifications |
| `security` | Security review and threat analysis |
| `acceptance-validation` | Acceptance criteria verification gate |
| `lao` | Full pipeline coordinator (rarely overlaid) |
| `lao-dry-run` | Dry-run mode (rarely overlaid) |

## Template: Overlay PROJECT.md

When generating overlay files for convention mode, use this starter template:

```markdown
---
name: <role>-overlay
description: Project-specific <role> rules for <project-name>
---

# <Role> — Project Overlay

> **Base skill:** `<role>` from lifecycle-agent-orchestrator v<version>
> **Path:** `<resolved-path-to-plugin>/skills/<role>/SKILL.md`
> **Portable:** run `/lao` and ask "show me the <role> base skill"
> Only add project-specific deltas here — the base rules apply automatically.

## Project Context

<!-- Describe your project's specific context for this role -->

## Overrides

<!-- Document any base skill rules you are overriding and why -->

## Additional Rules

<!-- Add project-specific rules not covered by the base skill -->
```

When generating this template, resolve the placeholders:
- `<version>`: read from the plugin's `.claude-plugin/plugin.json` → `version` field.
- `<resolved-path-to-plugin>`: determine the absolute filesystem path where the
  lifecycle-agent-orchestrator plugin is installed on this machine. You are currently reading
  this SKILL.md from that location — use the parent directory of `skills/` as the
  plugin root. The resolved path is machine-specific; the portable `/lao`
  fallback works on any machine.

## Template: Domain File

When generating domain context files, use this starter template:

```markdown
---
name: <topic-name>
description: <one-line description of what this domain file covers>
applies_to: all
---

# <Topic Name>

## Overview

<!-- Describe the domain concept, system, or pattern -->

## Key Decisions

<!-- Document important decisions and constraints -->

## References

<!-- Links to external docs, diagrams, or specs -->
```

## Template: Extra Role SKILL.md

When generating extra role files, use this starter template:

```markdown
---
name: <role-name>
description: <one-line description of what this role does>
applies_to: [<role1>, <role2>]
---

# <Role Name>

## Purpose

<!-- Describe what this role checks, enforces, or produces -->

## When Active

<!-- This role is loaded during phases whose base skill matches applies_to -->

## Checklist / Rules

<!-- Define the specific checks, standards, or outputs for this role -->
```

**Important:** If `applies_to` is omitted, the role will not be loaded at any
phase. Always ask the user which phases/roles this extra role is relevant to
and populate `applies_to` accordingly. Valid values: `all`, or any combination
of base role names (`product-management`, `architecture`, `code-review`, etc.).

## Hard Rules

- **Always scan before asking.** Don't ask the user to list files — find them.
- **Never overwrite existing files** without explicit confirmation.
- **Respect .gitignore** — don't scan ignored directories.
- **One method only** — if the user picks config, don't also create convention dirs (and vice versa).
- **Validate before declaring success** — always run validation in Step 5.
