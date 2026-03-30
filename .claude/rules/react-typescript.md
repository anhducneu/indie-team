# Rules: React / TypeScript

**Applies to:** `frontend/src/**/*.{ts,tsx}`, `frontend/*.{ts,tsx,json}`

---

## Language & Tooling
- TypeScript strict mode — `tsconfig.json` must have `"strict": true`
- No `any` type — ever. Use `unknown` + type guards, generics, or proper interfaces
- Functional components only — no class components
- `const` for all component declarations: `const MyComponent: React.FC<Props> = ...`

## Directory Structure (enforced)
```
src/
  components/   ← Reusable, stateless/presentational UI components
  pages/        ← Route-level components (one per route)
  features/     ← Feature-scoped components + co-located logic
  hooks/        ← Custom React hooks (use* prefix)
  services/     ← All API call functions (typed, no fetch/axios in components)
  store/        ← Zustand stores or Redux slices
  types/        ← Shared TypeScript interfaces and types
  utils/        ← Pure utility functions (no side effects)
```

## Naming Conventions
| Type | Pattern | Example |
|------|---------|---------|
| Component | PascalCase | `PaymentForm`, `AccountSummaryCard` |
| Hook | `use` + PascalCase | `usePaymentSubmit`, `useAccountBalance` |
| File | Match export name | `PaymentForm.tsx`, `usePaymentSubmit.ts` |
| Service fn | camelCase | `submitPayment`, `fetchAccountBalance` |
| Store | camelCase | `useAuthStore`, `usePaymentStore` |

## API Calls
- All API calls go through typed functions in `src/services/` — never call `fetch` or `axios` directly in a component
- Every service function must have explicit TypeScript return types
- Use TanStack Query (React Query v5) for server state — no manual `useEffect` fetching
- Handle all states in every component: loading, error, empty, success — no implicit rendering

## State Management
- Local UI state: `useState` / `useReducer`
- Server state: TanStack Query
- Global app state: Zustand (lightweight) or Redux Toolkit (complex auth/session)
- No prop drilling beyond 2 levels — use context or a store

## Sensitive Data Display
- Card numbers: show only last 4 digits — `**** **** **** {last4}`
- Account numbers: show only last 4 digits
- SSN / tax IDs: never render client-side beyond what is explicitly required
- Never store sensitive data in `localStorage` or `sessionStorage`
- Never log sensitive fields to `console`

## Accessibility (WCAG 2.1 AA required)
- All interactive elements keyboard-navigable (Tab, Enter, Space)
- Semantic HTML: `<button>`, `<nav>`, `<main>`, `<section>`, `<form>`
- ARIA labels on icon-only buttons: `aria-label="Close dialog"`
- Sufficient color contrast (4.5:1 for normal text, 3:1 for large text)
- Form inputs paired with visible `<label>` elements

## Testing
- Vitest + React Testing Library — test user-visible behavior, not internals
- MSW (Mock Service Worker) for API mocking — no manual `jest.mock('axios')`
- Do not test implementation details (internal state, private methods)
- Every component must have at least a smoke test (renders without crashing)
