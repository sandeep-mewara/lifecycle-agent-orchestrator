# React / TypeScript Testing — Checklist

## When Writing Unit Tests

- [ ] Test file named `<Component>.test.tsx` or `<util>.test.ts` alongside the source
- [ ] React Testing Library for component tests — query by role, label, text (not test IDs)
- [ ] `userEvent` over `fireEvent` for user interaction simulation
- [ ] `screen` queries preferred over destructured render result
- [ ] `waitFor` / `findBy` for async assertions — never raw `setTimeout`
- [ ] Mock API calls via MSW (Mock Service Worker) or fetch mocks — not implementation details
- [ ] Custom hooks tested via `renderHook` from `@testing-library/react`
- [ ] Each test verifies one behavior — not one giant test per component
- [ ] No snapshot tests for logic — snapshots only for stable UI structure if at all

## When Writing Integration Tests

- [ ] Full page renders with mocked API layer (MSW recommended)
- [ ] Test user flows end-to-end: navigate → interact → verify outcome
- [ ] Router and context providers wrapped via test utility
- [ ] Tests tagged or separated for CI (e.g., `describe.concurrent` or separate config)
- [ ] Accessibility checks via `jest-axe` or Testing Library's accessibility queries

## Vitest / Jest Configuration

- [ ] `jsdom` environment for component tests
- [ ] Setup file configures `@testing-library/jest-dom` matchers
- [ ] Coverage threshold >=85% for new code
- [ ] `--reporter=junit` for CI integration
- [ ] Path aliases resolved in test config (matching `tsconfig.json` paths)

## Component Test Patterns

- [ ] Render with minimal props — test defaults, then variations
- [ ] Loading → success → error states each tested independently
- [ ] Form submissions tested: valid input → API call → success feedback
- [ ] Form validation tested: invalid input → error messages displayed
- [ ] Conditional rendering tested: feature flags, permissions, empty states

## Agent Evaluation Tests

- [ ] Tests tagged with custom marker (excluded from regular test runs)
- [ ] Separate CI stage for evaluation runs
