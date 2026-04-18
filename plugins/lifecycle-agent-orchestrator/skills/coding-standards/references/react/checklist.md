# React / TypeScript Coding Standards — Checklist

## When Writing or Modifying Code

### Naming
- [ ] Components use `PascalCase` (`UserProfile`, `OrderList`)
- [ ] Hooks use `camelCase` prefixed with `use` (`useAuth`, `useOrderData`)
- [ ] Utility functions use `camelCase` (`formatCurrency`, `validateEmail`)
- [ ] Constants use `UPPER_SNAKE_CASE` for true constants, `camelCase` for config objects
- [ ] Props interfaces suffixed with `Props` (`UserProfileProps`)
- [ ] Types/interfaces use `PascalCase` (`OrderResponse`, `AuthState`)
- [ ] Event handlers prefixed with `handle` (`handleSubmit`, `handleClick`)
- [ ] Boolean props prefixed with `is`/`has`/`can` (`isLoading`, `hasError`)
- [ ] Files: `PascalCase.tsx` for components, `camelCase.ts` for utilities
- [ ] Test files: `ComponentName.test.tsx` or `utilName.test.ts`

### Error Handling
- [ ] Error boundaries wrap feature sections — not one giant boundary at the root
- [ ] Custom error classes for API and domain errors
- [ ] `try/catch` in async operations with user-friendly fallback UI
- [ ] Form validation via schema library (Zod, Yup) — not manual checks
- [ ] API errors mapped to typed error responses — never raw `any`

### TypeScript
- [ ] Strict mode enabled (`"strict": true` in tsconfig)
- [ ] No `any` type — use `unknown` + type guards when type is uncertain
- [ ] Props interfaces defined (not inline) for all components
- [ ] Return types on exported functions (inferred OK for internal/simple functions)
- [ ] Discriminated unions for complex state (`type Status = 'idle' | 'loading' | 'error' | 'success'`)
- [ ] Generics for reusable hooks and utilities (`useQuery<T>`)

### React Patterns
- [ ] Functional components only — no class components
- [ ] Custom hooks extract reusable logic — no logic duplication across components
- [ ] `useMemo` / `useCallback` only for measured performance issues — not by default
- [ ] State co-located with the component that uses it — lift only when needed
- [ ] Side effects in `useEffect` with proper dependency arrays and cleanup
- [ ] No direct DOM manipulation — use refs only when React APIs are insufficient

### Imports
- [ ] Groups: react → third-party → internal → styles/assets
- [ ] Absolute imports via path aliases (`@/components/...`) — no deep relative paths
- [ ] No barrel file re-exports that pull in large dependency trees

## When Setting Up a New Project

### Configuration
- [ ] TypeScript strict mode enabled
- [ ] Path aliases configured (`@/` prefix)
- [ ] Environment variables via `.env` files — prefixed (`NEXT_PUBLIC_`, `VITE_`)
- [ ] No secrets in client-side environment variables — public keys only

### Project Structure
- [ ] Feature-based directory structure (not type-based)
- [ ] Shared components in `components/ui/` or `components/shared/`
- [ ] API layer isolated in `lib/api/` or `services/`
- [ ] Types co-located or in `types/` directory

### Tooling
- [ ] ESLint with `eslint-config-next` or equivalent framework config
- [ ] Prettier for formatting (consistent with ESLint)
- [ ] `tsc --noEmit` in CI for type checking
- [ ] Lock file committed (`package-lock.json`, `pnpm-lock.yaml`, or `yarn.lock`)

### App Initialization
- [ ] Layout components for shared UI (header, sidebar, footer)
- [ ] Error boundary at feature boundaries
- [ ] Loading states for async data
- [ ] Environment-based configuration (dev/staging/production)
