# C# Coding Standards — Checklist

## When Writing or Modifying Code

### Naming
- [ ] Methods use `PascalCase` with verb-first names (`GetOrderData`, `ValidateRequest`)
- [ ] Async methods suffixed with `Async` (`GetOrderDataAsync`)
- [ ] Classes, interfaces, records use `PascalCase`
- [ ] Interfaces prefixed with `I` (`IOrderService`, `IRepository<T>`)
- [ ] Private fields use `_camelCase` (`_orderRepository`, `_logger`)
- [ ] Parameters and local variables use `camelCase`
- [ ] Constants use `PascalCase` (C# convention, not UPPER_SNAKE)
- [ ] Booleans prefixed with `Is`/`Has`/`Can` (`IsActive`, `HasPermission`)
- [ ] Namespaces match folder structure

### Error Handling
- [ ] Custom exception hierarchy extending appropriate base (`Exception`, `ApplicationException`)
- [ ] Exception filter middleware for centralized error-to-HTTP mapping
- [ ] Specific exceptions caught first, generic `Exception` last
- [ ] `throw;` to preserve stack trace (not `throw ex;`)
- [ ] Logger call before re-throwing
- [ ] Problem Details (RFC 7807) for API error responses

### Structured Logging
- [ ] Serilog or Microsoft.Extensions.Logging as logging framework
- [ ] Structured logging with message templates: `_logger.LogInformation("Processing order {OrderId}", orderId)`
- [ ] No string interpolation in log messages (`$"..."` defeats structured logging)
- [ ] No `Console.WriteLine()` in production code
- [ ] JSON sink in production, console sink in local dev
- [ ] Correlation ID via `IHttpContextAccessor` or middleware

### Data Models
- [ ] Records for immutable DTOs (`public record OrderResponse(string OrderId, decimal Total)`)
- [ ] Data annotations or FluentValidation for request validation
- [ ] `[Required]`, `[StringLength]`, `[Range]` on request models
- [ ] Nullable reference types enabled (`<Nullable>enable</Nullable>`)

### Imports
- [ ] `using` statements organized: System → third-party → project
- [ ] No unused usings (IDE auto-cleanup)
- [ ] Global usings in `GlobalUsings.cs` for common namespaces

## When Setting Up a New Project

### Configuration
- [ ] `appsettings.json` + `appsettings.{Environment}.json` hierarchy
- [ ] `IOptions<T>` pattern for type-safe configuration
- [ ] Secrets via User Secrets (dev), Key Vault, or environment variables — never in `appsettings.json`
- [ ] `ASPNETCORE_ENVIRONMENT` drives configuration

### Project Structure
- [ ] .NET SDK-style `.csproj` with explicit `TargetFramework`
- [ ] Solution file (`.sln`) at repo root
- [ ] `src/` for application projects, `tests/` for test projects
- [ ] One project per bounded context / service

### Tooling
- [ ] `.editorconfig` for consistent formatting
- [ ] Roslyn analyzers (`Microsoft.CodeAnalysis.NetAnalyzers`)
- [ ] `dotnet format` enforced in CI
- [ ] Coverlet for coverage (>=85% threshold)
- [ ] `Directory.Build.props` for shared build properties

### App Initialization
- [ ] `WebApplication.CreateBuilder()` with minimal API or controllers
- [ ] Dependency injection via `builder.Services`
- [ ] Health checks via `Microsoft.Extensions.Diagnostics.HealthChecks`
- [ ] Graceful shutdown via `IHostApplicationLifetime`
