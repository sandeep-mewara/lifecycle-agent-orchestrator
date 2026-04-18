# C# Code Standards Quick Reference

C#-specific conventions for code reviews. Use alongside the universal `code-standards.md`.

---

## Formatting and Tooling

| Tool | Config | Enforcement |
|------|--------|-------------|
| **dotnet format** | `.editorconfig` | CI pipeline |
| **Roslyn Analyzers** | `Microsoft.CodeAnalysis.NetAnalyzers` | Build warnings / errors |
| **Coverlet** | >=85% line coverage | CI via `dotnet test` |
| **xUnit** | Traits: `Category=Unit`, `Category=Integration` | CI via `dotnet test` |

---

## C# Style

### Functions and Types
- **All public methods have XML documentation comments.** Use `<summary>`, `<param>`, `<returns>`.
- **Records** for immutable DTOs (`public record OrderResponse(string OrderId, decimal Total)`).
- **Nullable reference types enabled** (`<Nullable>enable</Nullable>`) — compiler catches null issues.
- **FluentValidation** or Data Annotations for request validation.

### Naming
- **Namespaces:** Match folder structure (`MyApp.Services.Orders`)
- **Classes/Records:** `PascalCase` nouns (`OrderService`, `PaymentGateway`)
- **Interfaces:** `IPascalCase` (`IOrderService`, `IRepository<T>`)
- **Methods:** `PascalCase` verb-noun, `Async` suffix for async (`GetOrderDetailsAsync`)
- **Private fields:** `_camelCase` (`_orderRepository`, `_logger`)
- **Constants:** `PascalCase` (C# convention)

### Error Handling
- **Exception middleware** for centralized error-to-HTTP mapping.
- **Problem Details** (RFC 7807) for API error responses.
- **`throw;`** to preserve stack trace (never `throw ex;`).
- **Custom exception hierarchy** with error codes.

### Async Patterns
- **`async`/`await` throughout** — no `.Result` or `.Wait()` (deadlock risk).
- **`CancellationToken`** propagated through all async chains.
- **`IHttpClientFactory`** with named/typed clients for connection pooling.
- **Polly** or `Microsoft.Extensions.Http.Resilience` for retry/circuit-breaker.

---

## Project Structure

```
src/
├── MyApp.Api/              # ASP.NET Core host, controllers/endpoints
├── MyApp.Application/      # Business logic, services, interfaces
├── MyApp.Domain/           # Domain models, value objects
├── MyApp.Infrastructure/   # Data access, external clients
└── MyApp.Contracts/        # Shared DTOs, API contracts

tests/
├── MyApp.UnitTests/
└── MyApp.IntegrationTests/
```

---

## ASP.NET Core Specifics

- **Dependency injection** via `builder.Services` — constructor injection only.
- **`IOptions<T>` / `IOptionsSnapshot<T>`** for type-safe configuration.
- **`appsettings.{Environment}.json`** for environment hierarchy.
- **Health checks** via `Microsoft.Extensions.Diagnostics.HealthChecks`.
- **Minimal APIs** or controllers — consistent choice within a project.
- **Middleware pipeline** ordering matters — auth before business logic.
