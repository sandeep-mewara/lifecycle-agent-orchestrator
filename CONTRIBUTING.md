# Contributing to Lifecycle Agent Orchestrator

Thank you for your interest in contributing! This guide will help you get started.

## How to Contribute

### Reporting Issues

- Use [GitHub Issues](https://github.com/sandeep-mewara/lifecycle-orchestrator/issues) to report bugs or request features.
- Include steps to reproduce, expected behavior, and actual behavior for bug reports.
- Check existing issues before creating a new one.

### Submitting Changes

1. Fork the repository and create a branch from `main`.
2. Make your changes — follow the existing code and documentation style.
3. Run the validation suite before submitting:

```bash
# Plugin structural validation
./plugins/lifecycle-agent-orchestrator/scripts/validate-plugin.sh

# Cross-reference consistency
./plugins/lifecycle-agent-orchestrator/scripts/check-consistency.sh

# Test suite (requires bats-core: brew install bats-core)
bats plugins/lifecycle-agent-orchestrator/tests/
```

4. Open a pull request with a clear description of the change.

### What Can You Contribute?

- **Bug fixes** — corrections to skills, scripts, or documentation
- **New base roles** — additional lifecycle phases (update manifests and validation scripts accordingly)
- **Improved examples** — better code examples in reference docs
- **Documentation** — clearer explanations, additional walkthroughs
- **Test coverage** — new bats test cases or fixture scenarios

### Skill Authoring Guidelines

- Every skill needs a `SKILL.md` with YAML frontmatter (`name`, `description`).
- Reference files go in a `references/` subdirectory.
- Skills should be generic and project-agnostic — project-specific patterns belong in overlays.
- Update `scripts/validate-plugin.sh` expected skill count when adding or removing skills.
- Update `scripts/check-consistency.sh` if adding new cross-reference points.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
