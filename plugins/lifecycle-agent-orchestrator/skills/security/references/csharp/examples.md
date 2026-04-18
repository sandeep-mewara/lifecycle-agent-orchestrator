# C# Security — Code Examples

## Table of Contents
1. [Authentication Configuration](#authentication-configuration)
2. [Secrets Management](#secrets-management)
3. [Input Validation](#input-validation)
4. [Safe Error Responses](#safe-error-responses)
5. [PII-Safe Logging](#pii-safe-logging)

---

## Authentication Configuration

```csharp
// Program.cs
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Auth:Authority"];
        options.Audience = builder.Configuration["Auth:Audience"];
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });

builder.Services.AddAuthorizationBuilder()
    .AddPolicy("AdminOnly", policy => policy.RequireRole("admin"))
    .AddPolicy("ReadAccess", policy => policy.RequireClaim("scope", "read"));

// Endpoint
app.MapGet("/api/admin/users", [Authorize(Policy = "AdminOnly")] async (IUserService service) =>
    Results.Ok(await service.GetAllAsync()));
```

---

## Secrets Management

```csharp
// Program.cs — Azure Key Vault integration
builder.Configuration.AddAzureKeyVault(
    new Uri(builder.Configuration["KeyVault:Uri"]!),
    new DefaultAzureCredential());

// Usage via IOptions
public class ExternalApiClient(IOptions<ApiConfig> config, HttpClient httpClient)
{
    public async Task<ApiResponse> CallAsync(ApiRequest request, CancellationToken ct)
    {
        httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", config.Value.ApiKey);
        var response = await httpClient.PostAsJsonAsync("/api/process", request, ct);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<ApiResponse>(ct)
            ?? throw new ServiceException(ErrorCode.InternalError, "Empty API response", 500);
    }
}
```

---

## Input Validation

```csharp
// FluentValidation
public class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Role).IsInEnum();
    }
}

// Minimal API endpoint with validation
app.MapPost("/api/users", async (
    CreateUserRequest request,
    IValidator<CreateUserRequest> validator,
    IUserService service) =>
{
    var result = await validator.ValidateAsync(request);
    if (!result.IsValid)
        return Results.ValidationProblem(result.ToDictionary());
    return Results.Ok(await service.CreateAsync(request));
});
```

---

## Safe Error Responses

```csharp
public class ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (ServiceException ex)
        {
            logger.LogWarning("Service error: {ErrorCode} - {Message}", ex.ErrorCode, ex.Message);
            context.Response.StatusCode = ex.HttpStatus;
            await context.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Status = ex.HttpStatus,
                Title = ex.ErrorCode.ToString(),
                Detail = ex.Message,
                Type = $"https://api.example.com/errors/{ex.ErrorCode.ToString().ToLower()}"
            });
        }
        catch (Exception ex)
        {
            // Log full detail — never expose to client
            logger.LogError(ex, "Unexpected error");
            context.Response.StatusCode = 500;
            await context.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Status = 500,
                Title = "Internal Server Error",
                Detail = "An internal error occurred"
            });
        }
    }
}
```

---

## PII-Safe Logging

```csharp
// GOOD — identifiers and metadata only
logger.LogInformation("Processing order {OrderId}, items={ItemCount}",
    order.Id, order.Items.Count);

// BAD — leaks sensitive data
// logger.LogInformation("Processing order: {@Order}", order);  // Serilog destructuring exposes all fields
// logger.LogInformation("Payment: card={CardNumber}", order.Payment.CardNumber);
```

```csharp
// Safe serialization — exclude sensitive fields
public record Order(string Id, string CustomerId, PaymentInfo Payment, List<LineItem> Items)
{
    public override string ToString() => $"Order[Id={Id}, ItemCount={Items.Count}]";
}
```
