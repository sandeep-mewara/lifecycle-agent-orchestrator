# React / TypeScript Security — Code Examples

## Table of Contents
1. [XSS Prevention](#xss-prevention)
2. [Auth Token Handling](#auth-token-handling)
3. [Input Validation](#input-validation)
4. [Safe Error Responses](#safe-error-responses)
5. [Protected Routes](#protected-routes)

---

## XSS Prevention

```tsx
// GOOD — React auto-escapes by default
function UserGreeting({ name }: { name: string }) {
  return <h1>Hello, {name}</h1>; // Safe: React escapes HTML entities
}

// BAD — dangerouslySetInnerHTML without sanitization
function UnsafeContent({ html }: { html: string }) {
  return <div dangerouslySetInnerHTML={{ __html: html }} />; // XSS risk
}

// GOOD — sanitize if you must render HTML
import DOMPurify from 'dompurify';

function SafeHtmlContent({ html }: { html: string }) {
  const sanitized = DOMPurify.sanitize(html);
  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
}
```

```tsx
// GOOD — safe link with URL validation
function SafeLink({ href, children }: { href: string; children: ReactNode }) {
  const isSafe = href.startsWith('https://') || href.startsWith('/');
  if (!isSafe) return <span>{children}</span>;
  return (
    <a href={href} target="_blank" rel="noopener noreferrer">
      {children}
    </a>
  );
}

// BAD — user-controlled href without validation
function UnsafeLink({ href }: { href: string }) {
  return <a href={href}>Click</a>; // Could be javascript:alert(1)
}
```

---

## Auth Token Handling

```tsx
// GOOD — tokens in httpOnly cookies, API layer handles transparently
async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`/api${path}`, {
    ...init,
    credentials: 'include', // sends httpOnly cookies
    headers: {
      'Content-Type': 'application/json',
      ...init?.headers,
    },
  });
  if (response.status === 401) {
    // Redirect to login — don't try to read the token
    window.location.href = '/login';
    throw new Error('Unauthorized');
  }
  return handleApiResponse<T>(response);
}
```

```tsx
// BAD — token in localStorage
const token = localStorage.getItem('auth_token'); // XSS can steal this
fetch('/api/data', { headers: { Authorization: `Bearer ${token}` } });
```

---

## Input Validation

```tsx
import { z } from 'zod';

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: z.infer<typeof loginSchema>) => {
    // Client validation is for UX — server MUST re-validate
    await authApi.login(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input type="email" {...register('email')} autoComplete="email" />
      {errors.email && <span role="alert">{errors.email.message}</span>}

      <input type="password" {...register('password')} autoComplete="current-password" />
      {errors.password && <span role="alert">{errors.password.message}</span>}

      <button type="submit">Log in</button>
    </form>
  );
}
```

---

## Safe Error Responses

```tsx
// GOOD — user-friendly error display, no internal details
function ErrorCard({ error }: { error: ApiError | Error }) {
  const message = error instanceof ApiError
    ? error.message           // already user-safe from backend
    : 'Something went wrong'; // generic fallback for unexpected errors

  return (
    <div role="alert" className="error-card">
      <p>{message}</p>
      <button onClick={() => window.location.reload()}>Try again</button>
    </div>
  );
}

// BAD — exposing internal error details
function UnsafeErrorDisplay({ error }: { error: unknown }) {
  return <pre>{JSON.stringify(error, null, 2)}</pre>; // stack traces, internal state
}
```

---

## Protected Routes

```tsx
function ProtectedRoute({ children }: { children: ReactNode }) {
  const { state } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!state.isAuthenticated) {
      router.replace('/login');
    }
  }, [state.isAuthenticated, router]);

  if (!state.isAuthenticated) {
    return null; // no flash of protected content
  }

  return <>{children}</>;
}

// Usage in layout/router
<ProtectedRoute>
  <DashboardPage />
</ProtectedRoute>
```
