# C# Security — Checklist

## 1. Secret Management
- [ ] Secrets via Azure Key Vault, AWS Secrets Manager, or User Secrets (dev only)
- [ ] `IOptions<T>` references secret paths, not literal values
- [ ] No secrets in `appsettings.json` or `launchSettings.json`
- [ ] `AddUserSecrets<Program>()` for local development only — not in production

## 2. Authentication & Authorization
- [ ] ASP.NET Core Authentication middleware configured (`AddAuthentication`, `AddJwtBearer`)
- [ ] `[Authorize]` attribute on controllers/endpoints requiring auth
- [ ] Policy-based authorization for fine-grained access (`AddAuthorizationBuilder`)
- [ ] CORS configured restrictively via `AddCors` with specific origins
- [ ] Anti-forgery tokens for form-based endpoints

## 3. OWASP / Secure Coding
- [ ] Data Annotations or FluentValidation on all request models
- [ ] `[FromBody]` parameters validated with model binding
- [ ] Entity Framework with parameterized queries — no raw SQL string interpolation
- [ ] `JsonSerializerOptions` configured to reject unknown properties
- [ ] `System.Text.Json` used (not Newtonsoft) for new projects — default secure settings

## 4. Dependencies & Vulnerabilities
- [ ] `dotnet list package --vulnerable` run in CI
- [ ] NuGet package sources configured (nuget.org or private feed)
- [ ] `Directory.Packages.props` for centralized version management
- [ ] Container base image pinned to specific digest

## 5. API Security
- [ ] Exception middleware catches all unhandled exceptions — no stack traces in responses
- [ ] Problem Details (RFC 7807) for error responses
- [ ] Rate limiting via `Microsoft.AspNetCore.RateLimiting` or API gateway
- [ ] Request size limits configured (`Kestrel.Limits.MaxRequestBodySize`)

## 6. Sensitive Data Protection
- [ ] Serilog enrichers carry correlation context — no sensitive values
- [ ] `[JsonIgnore]` on sensitive model properties
- [ ] Data Protection API for encryption of sensitive data at rest
- [ ] `ILogger` with structured logging — message templates, not string interpolation
