# React / TypeScript Security — Checklist

## 1. Secret Management
- [ ] No secrets in client-side code — ever (API keys, tokens, passwords)
- [ ] Environment variables prefixed correctly (`NEXT_PUBLIC_`, `VITE_`) — only public values
- [ ] Secret API calls go through your backend — frontend never talks to secret-bearing services directly
- [ ] `.env` files in `.gitignore` — never committed

## 2. Authentication & Authorization
- [ ] Auth tokens stored in `httpOnly` cookies — not `localStorage` or `sessionStorage`
- [ ] Token refresh handled transparently by API layer
- [ ] Protected routes check auth state before rendering
- [ ] Unauthorized users redirected — no flash of protected content
- [ ] Auth state cleared on logout (cookies, in-memory state, cached data)

## 3. OWASP / Secure Coding
- [ ] No `dangerouslySetInnerHTML` without sanitization (DOMPurify or equivalent)
- [ ] User input never interpolated into URLs without encoding (`encodeURIComponent`)
- [ ] No `eval()`, `new Function()`, or `innerHTML` with user data
- [ ] Links with `target="_blank"` include `rel="noopener noreferrer"`
- [ ] Form inputs validated client-side (UX) AND server-side (security)
- [ ] CSP (Content Security Policy) headers configured — no `unsafe-inline` in production
- [ ] No user-controlled `href` values without URL validation (prevents `javascript:` protocol)

## 4. Dependencies & Vulnerabilities
- [ ] `npm audit` or equivalent run in CI
- [ ] Lock file committed (`package-lock.json` / `pnpm-lock.yaml`)
- [ ] Dependabot or Renovate configured for automated updates
- [ ] No dependencies with known critical vulnerabilities in production bundle
- [ ] Bundle analyzer run periodically to catch unexpected dependency bloat

## 5. API Security
- [ ] CSRF protection — SameSite cookies or CSRF tokens for state-changing requests
- [ ] API responses validated against typed schemas before use
- [ ] Rate limiting on login/signup forms (via backend)
- [ ] Error responses don't expose internal details (stack traces, SQL errors)

## 6. Sensitive Data Protection
- [ ] No PII in console logs, error tracking payloads, or analytics events
- [ ] No sensitive data in URL query parameters (visible in browser history, server logs)
- [ ] Autocomplete disabled on sensitive form fields (`autoComplete="off"`)
- [ ] Clipboard operations for sensitive data (passwords) use secure APIs
