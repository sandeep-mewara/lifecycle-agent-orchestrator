# React / TypeScript Coding Standards — Code Examples

## Table of Contents
1. [Component Patterns](#component-patterns)
2. [Custom Hooks](#custom-hooks)
3. [Error Handling](#error-handling)
4. [API Layer](#api-layer)
5. [State Management](#state-management)
6. [Form Validation](#form-validation)

---

## Component Patterns

```tsx
interface UserProfileProps {
  userId: string;
  showActions?: boolean;
}

export function UserProfile({ userId, showActions = true }: UserProfileProps) {
  const { data: user, isLoading, error } = useUser(userId);

  if (isLoading) return <ProfileSkeleton />;
  if (error) return <ErrorCard message="Failed to load profile" />;
  if (!user) return null;

  return (
    <div className="space-y-4">
      <h2>{user.name}</h2>
      <p>{user.email}</p>
      {showActions && <UserActions userId={userId} />}
    </div>
  );
}
```

```tsx
// Discriminated union for component state
type OrderStatus =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'error'; error: string }
  | { status: 'success'; data: Order[] };

function OrderList() {
  const [state, setState] = useState<OrderStatus>({ status: 'idle' });

  // State transitions are type-safe — can only access `error` when status is 'error'
  if (state.status === 'error') {
    return <ErrorCard message={state.error} />;
  }
}
```

---

## Custom Hooks

```tsx
// Data fetching hook with proper cleanup
function useUser(userId: string) {
  const [data, setData] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    setIsLoading(true);

    fetchUser(userId, { signal: controller.signal })
      .then(setData)
      .catch((err) => {
        if (!controller.signal.aborted) setError(err);
      })
      .finally(() => {
        if (!controller.signal.aborted) setIsLoading(false);
      });

    return () => controller.abort();
  }, [userId]);

  return { data, isLoading, error };
}
```

```tsx
// Debounced value hook — reusable generic
function useDebounce<T>(value: T, delayMs: number): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(timer);
  }, [value, delayMs]);

  return debounced;
}
```

---

## Error Handling

```tsx
// Error boundary for feature sections
class FeatureErrorBoundary extends Component<
  { children: ReactNode; fallback?: ReactNode },
  { hasError: boolean }
> {
  state = { hasError: false };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('Feature error:', error, info.componentStack);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? <ErrorCard message="Something went wrong" />;
    }
    return this.props.children;
  }
}

// Usage: wrap feature sections, not the entire app
<FeatureErrorBoundary fallback={<OrderErrorFallback />}>
  <OrderDashboard />
</FeatureErrorBoundary>
```

```tsx
// Typed API errors
class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public code: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

async function handleApiResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new ApiError(
      body.message ?? 'Request failed',
      response.status,
      body.code ?? 'unknown_error',
    );
  }
  return response.json();
}
```

---

## API Layer

```tsx
const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? '/api';

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...init?.headers,
    },
  });
  return handleApiResponse<T>(response);
}

export const ordersApi = {
  list: () => apiFetch<Order[]>('/orders'),
  get: (id: string) => apiFetch<Order>(`/orders/${id}`),
  create: (data: CreateOrderRequest) =>
    apiFetch<Order>('/orders', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
};
```

---

## State Management

```tsx
// Context + reducer for shared feature state
interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
}

type AuthAction =
  | { type: 'LOGIN'; user: User }
  | { type: 'LOGOUT' };

function authReducer(state: AuthState, action: AuthAction): AuthState {
  switch (action.type) {
    case 'LOGIN':
      return { user: action.user, isAuthenticated: true };
    case 'LOGOUT':
      return { user: null, isAuthenticated: false };
  }
}

const AuthContext = createContext<{
  state: AuthState;
  dispatch: Dispatch<AuthAction>;
} | null>(null);

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
```

---

## Form Validation

```tsx
import { z } from 'zod';

const createOrderSchema = z.object({
  customerId: z.string().min(1, 'Customer is required'),
  items: z.array(z.object({
    productId: z.string().min(1),
    quantity: z.number().int().positive(),
  })).min(1, 'At least one item required'),
  notes: z.string().max(500).optional(),
});

type CreateOrderForm = z.infer<typeof createOrderSchema>;

function CreateOrderForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<CreateOrderForm>({
    resolver: zodResolver(createOrderSchema),
  });

  const onSubmit = async (data: CreateOrderForm) => {
    try {
      await ordersApi.create(data);
    } catch (err) {
      if (err instanceof ApiError) {
        toast.error(err.message);
      }
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('customerId')} />
      {errors.customerId && <span>{errors.customerId.message}</span>}
      <button type="submit">Create Order</button>
    </form>
  );
}
```
