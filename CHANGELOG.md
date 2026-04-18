# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2026-04-18

### Added
- **Multi-language project support**: `languages:` list in `lao.config.yaml` for full-stack projects (e.g., `[python, react]`)
- Auto-detection now collects **all** matches (a repo with `pyproject.toml` + `package.json` with react → `[python, react]`)
- React/TypeScript language pack for all 4 language-aware skills (`coding-standards`, `testing-conventions`, `code-review`, `security`)
- React-specific references: component patterns, hooks, error boundaries, Vitest/React Testing Library, ESLint/Prettier/TypeScript config, XSS prevention, auth token handling, protected routes
- Detection heuristic: `package.json` with `react` dependency or `next.config.*` → `react`
- React/TS column added to coding-standards naming conventions table

### Changed
- Config accepts both `languages: [python, react]` (list) and `language: python` (backward compatible string)
- `validate-project-skills.sh` parses both `languages:` list and `language:` string formats
- `validate-plugin.sh` EXPECTED_REFS expanded from 35 to 42 entries (+ 7 React pack files)
- All 4 language-aware SKILL.md files updated: multi-language guidance ("apply each pack to files of its language")
- Manifest display changed from `Language:` to `Languages:` to reflect multi-language support
- README, design spec, and config examples updated for multi-language and React/TypeScript support

## [1.4.0] - 2026-04-18

### Added
- Multi-language support: `coding-standards`, `testing-conventions`, `code-review`, and `security` skills now support Python, Java, and C# via language packs
- Universal (language-agnostic) SKILL.md and checklists for all 4 language-aware skills
- Language-specific reference packs under `references/python/`, `references/java/`, `references/csharp/` for each skill
- `language` field in `lao.config.yaml` for explicit language configuration
- Auto-detection of project language from build files (`pyproject.toml`, `pom.xml`, `*.csproj`, etc.)
- Language detection integrated into `lao/SKILL.md` pipeline start and `lao-setup/SKILL.md` project scan
- Language field validation in `validate-project-skills.sh`
- Multi-Language Support section in README and design spec

### Changed
- `coding-standards/SKILL.md` rewritten as language-agnostic (universal principles only)
- `testing-conventions/SKILL.md` rewritten as language-agnostic (universal principles only)
- `code-review/SKILL.md` updated to reference language-specific code standards
- `security/SKILL.md` updated to reference language-specific checklists and examples
- Universal checklists extracted for all 4 skills (language-agnostic items only)
- `validate-plugin.sh` EXPECTED_REFS expanded from 11 to 35 entries (universal + 3 language packs × 4 skills)
- Manifest presentation now includes detected language

## [1.3.0] - 2026-04-18

### Changed
- Phase 6 (Plan) now includes no-placeholder rule, self-review checklist, and structured task templates
- Phase 7 (Implement) now includes strict TDD discipline (red-green-refactor with verification), two-stage review (spec compliance + code quality), and systematic debugging protocol
- Phase 8 (Validate) now includes rationalization prevention and structured evidence requirements
- Phase 9 (Ship) now includes 4 structured completion options (PR, merge, keep, discard)
- Simplified `lao/SKILL.md` — single workflow path


## [1.2.0] - 2026-04-16

### Changed
- Added short command aliases: `/lao`, `/lao-dry-run`, `/lao-setup`
- License standardized to MIT

### Added
- Dual command registration (full name + `/lao` alias) for all orchestrator commands
- CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md
- Expanded .gitignore for common development artifacts

## [1.1.0] - 2026-04-04

### Added
- Initial plugin structure with 13 skills (3 commands + 10 roles)
- Validation scripts: `validate-plugin.sh`, `validate-project-skills.sh`, `check-consistency.sh`
- Bats test suite with 21 tests
- Support for both Claude Code and Cursor platforms
- Config-based (`lao.config.yaml`) and convention-based project skill discovery
- Cross-role review gates at Phases 1-3
- Preview-then-execute model
- Design spec and phase output contract
