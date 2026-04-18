# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
