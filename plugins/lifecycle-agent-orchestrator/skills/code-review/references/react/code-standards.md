# React / TypeScript Code Standards Quick Reference

React/TypeScript-specific conventions for code reviews. Use alongside the universal `code-standards.md`.

---

## Formatting and Tooling

| Tool | Config | Enforcement |
|------|--------|-------------|
| **ESLint** | Flat config with `typescript-eslint` + `react-hooks` | Pre-commit + CI |
| **Prettier** | Single quotes, trailing commas, 100 width | Pre-commit + CI |
| **TypeScript** | Strict mode, `noUncheckedIndexedAccess` | CI via `tsc --noEmit` |
| **Vitest** or **Jest** | jsdom environment, >=85% coverage | CI |

---

## TypeScript Style

### Types and Interfaces
- **Strict mode mandatory.** No `any` — use `unknown` + type guards.
- **Props interfaces** defined and named (`UserProfileProps`), not inline.
- **Discriminated unions** for complex state (loading/error/success).
- **Generics** for reusable utilities and hooks.
- **`as` casts are code smells.** If you need a cast, the types are wrong.

### Naming
- **Components:** `PascalCase` (`OrderList`, `UserProfile`)
- **Hooks:** `camelCase` with `use` prefix (`useAuth`, `useDebounce`)
- **Utilities:** `camelCase` (`formatCurrency`, `validateEmail`)
- **Types/Interfaces:** `PascalCase` (`OrderResponse`, `AuthState`)
- **Files:** `PascalCase.tsx` for components, `camelCase.ts` for utilities
- **Event handlers:** `handle` prefix (`handleSubmit`, `handleClick`)

### React Patterns
- **Functional components only.** Class components only for error boundaries.
- **Custom hooks** for shared logic — no copy-pasted `useEffect` chains.
- **State co-location.** State lives in the lowest component that needs it.
- **Controlled components** for forms — uncontrolled only for simple, non-validated inputs.
- **No premature optimization.** `useMemo`/`useCallback` only after measuring.
- **Effects have cleanup.** Subscriptions, timers, and abort controllers cleaned up in return.

### Error Handling
- **Error boundaries** at feature boundaries — not one at the root.
- **Async errors caught and surfaced** — loading/error/success states explicit.
- **API errors typed** — custom error classes, not `catch (e: any)`.
- **Form validation via schema** (Zod/Yup) — not manual if/else chains.

---

## Project Structure

```
src/
├── app/                # Routes and layouts (Next.js App Router / framework router)
├── components/
│   ├── ui/             # Reusable UI primitives (Button, Card, Modal)
│   └── features/       # Feature-specific components (OrderList, UserProfile)
├── hooks/              # Shared custom hooks
├── lib/
│   ├── api/            # API client and typed endpoints
│   └── utils/          # Pure utility functions
├── types/              # Shared type definitions
└── styles/             # Global styles, theme config

tests/
├── components/         # Component tests
├── hooks/              # Hook tests
├── lib/                # Utility and API tests
└── e2e/                # End-to-end tests (Playwright/Cypress)
```

**Key conventions:**
- Feature components group related UI, hooks, and types together.
- API layer isolated — components never call `fetch` directly.
- Shared UI components are generic and composable.

---

## Accessibility

- **Semantic HTML first.** `<button>`, `<nav>`, `<main>` — not `<div onClick>`.
- **ARIA attributes** only when semantic HTML is insufficient.
- **Keyboard navigation** works for all interactive elements.
- **Color contrast** meets WCAG AA (4.5:1 for text).
- **Focus management** after route changes and modal open/close.

---

## Performance

- **Bundle size matters.** No giant utility libraries for one function.
- **Dynamic imports** (`next/dynamic`, `React.lazy`) for below-the-fold features.
- **Images optimized** via framework image component (`next/image`).
- **No layout shifts** — dimensions specified for media, skeleton loaders for async content.

---

## Testing Standards

- **React Testing Library** — query by role/label/text, not test IDs.
- **`userEvent`** over `fireEvent` for realistic interaction simulation.
- **MSW** for API mocking — intercept at the network level, not implementation.
- **Each test = one behavior.** Not one giant test that clicks through an entire flow.
- **Assertions verify what the user sees.** "The error message is displayed" — not "setState was called."
