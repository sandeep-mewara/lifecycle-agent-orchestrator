# C# Coding Standards — Code Examples

## Table of Contents
1. [Environment-Based Configuration](#environment-based-configuration)
2. [Exception Hierarchy and Middleware](#exception-hierarchy-and-middleware)
3. [Structured Logging with Serilog](#structured-logging-with-serilog)
4. [Validation and DTOs](#validation-and-dtos)
5. [Async Patterns](#async-patterns)
6. [Test Patterns](#test-patterns)

---

## Environment-Based Configuration

```json
// appsettings.json (base)
{
  "App": {
    "Name": "order-service",
    "Metrics": { "Enabled": true }
  }
}

// appsettings.Development.json
{
  "App": {
    "Metrics": { "Enabled": false }
  },
  "Logging": { "LogLevel": { "Default": "Debug" } }
}
```

```csharp
public class AppConfig
{
    public string Name { get; init; } = string.Empty;
    public MetricsConfig Metrics { get; init; } = new();
}

public class MetricsConfig
{
    public bool Enabled { get; init; }
}

// Registration
builder.Services.Configure<AppConfig>(builder.Configuration.GetSection("App"));

// Usage via DI
public class OrderService(IOptions<AppConfig> config)
{
    private readonly AppConfig _config = config.Value;
}
```

---

## Exception Hierarchy and Middleware

```csharp
public enum ErrorCode
{
    BadRequest,
    Unauthorized,
    RateLimited,
    InternalError
}

public class ServiceException : Exception
{
    public ErrorCode ErrorCode { get; }
    public int HttpStatus { get; }

    public ServiceException(ErrorCode errorCode, string message, int httpStatus)
        : base(message)
    {
        ErrorCode = errorCode;
        HttpStatus = httpStatus;
    }

    public ServiceException(ErrorCode errorCode, string message, int httpStatus, Exception inner)
        : base(message, inner)
    {
        ErrorCode = errorCode;
        HttpStatus = httpStatus;
    }
}

public class AuthorizationException : ServiceException
{
    public AuthorizationException(string message)
        : base(ErrorCode.Unauthorized, message, 401) { }
}
```

```csharp
public class ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (ServiceException ex)
        {
            logger.LogWarning("Service error: Code={ErrorCode}, Message={Message}", ex.ErrorCode, ex.Message);
            context.Response.StatusCode = ex.HttpStatus;
            await context.Response.WriteAsJsonAsync(new ErrorResponse(ex.ErrorCode.ToString(), ex.Message));
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unexpected error");
            context.Response.StatusCode = 500;
            await context.Response.WriteAsJsonAsync(new ErrorResponse("InternalError", "An internal error occurred"));
        }
    }
}

public record ErrorResponse(string Code, string Message);
```

---

## Structured Logging with Serilog

```csharp
// Program.cs
builder.Host.UseSerilog((context, config) => config
    .ReadFrom.Configuration(context.Configuration)
    .Enrich.FromLogContext()
    .Enrich.WithCorrelationId()
    .WriteTo.Console(new JsonFormatter()));
```

```csharp
public class OrderService(ILogger<OrderService> logger)
{
    public async Task<OrderResponse> ProcessOrderAsync(OrderRequest request)
    {
        using var scope = logger.BeginScope(new Dictionary<string, object>
        {
            ["OrderId"] = request.OrderId,
            ["TransactionId"] = request.TransactionId
        });

        logger.LogInformation("Processing order");
        try
        {
            var result = await ExecuteOrderLogicAsync(request);
            logger.LogInformation("Order processed, ItemCount={ItemCount}", result.ItemCount);
            return result;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Order processing failed");
            throw;
        }
    }
}
```

---

## Validation and DTOs

```csharp
public record CreateOrderRequest(
    [Required] string CustomerId,
    [Required, MinLength(1)] List<LineItem> Items,
    [Required] OrderType OrderType
);

public record LineItem(
    [Required] string ProductId,
    [Range(1, int.MaxValue)] int Quantity,
    [Range(0, double.MaxValue)] decimal UnitPrice
);

// Minimal API endpoint
app.MapPost("/api/orders", async (
    [FromBody] CreateOrderRequest request,
    IOrderService service,
    IValidator<CreateOrderRequest> validator) =>
{
    var validation = await validator.ValidateAsync(request);
    if (!validation.IsValid)
        return Results.ValidationProblem(validation.ToDictionary());
    return Results.Ok(await service.CreateAsync(request));
});
```

---

## Async Patterns

```csharp
public class NotificationClient(HttpClient httpClient, ILogger<NotificationClient> logger)
{
    public async Task<NotificationResponse> SendAsync(NotificationRequest request,
        CancellationToken ct = default)
    {
        var response = await httpClient.PostAsJsonAsync("/send", request, ct);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<NotificationResponse>(ct)
            ?? throw new ServiceException(ErrorCode.InternalError, "Empty notification response", 500);
    }
}

// Registration with resilience
builder.Services.AddHttpClient<NotificationClient>(client =>
{
    client.BaseAddress = new Uri("https://api.notifications.example.com");
    client.Timeout = TimeSpan.FromSeconds(5);
})
.AddStandardResilienceHandler();
```

---

## Test Patterns

```csharp
public class OrderServiceTests
{
    private readonly Mock<IOrderRepository> _repository = new();
    private readonly Mock<INotificationClient> _notifications = new();
    private readonly OrderService _service;

    public OrderServiceTests()
    {
        _service = new OrderService(_repository.Object, _notifications.Object,
            NullLogger<OrderService>.Instance);
    }

    [Fact]
    public async Task CreateAsync_ValidRequest_ReturnsOrderWithId()
    {
        var request = new CreateOrderRequest("cust-1",
            [new LineItem("prod-1", 2, 10.00m)], OrderType.Standard);
        _repository.Setup(r => r.SaveAsync(It.IsAny<Order>(), default))
            .ReturnsAsync((Order o, CancellationToken _) => o with { Id = "order-123" });

        var result = await _service.CreateAsync(request);

        Assert.Equal("order-123", result.OrderId);
        _notifications.Verify(n => n.SendAsync(It.IsAny<NotificationRequest>(), default), Times.Once);
    }

    [Fact]
    public async Task CreateAsync_EmptyItems_ThrowsBadRequest()
    {
        var request = new CreateOrderRequest("cust-1", [], OrderType.Standard);

        var ex = await Assert.ThrowsAsync<ServiceException>(() => _service.CreateAsync(request));
        Assert.Equal(ErrorCode.BadRequest, ex.ErrorCode);
    }
}
```
