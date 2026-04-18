# C# Coding Standards — Tooling & Configuration

## Table of Contents
1. [Project File (.csproj)](#project-file-csproj)
2. [Application Configuration](#application-configuration)
3. [Dockerfile Multi-Stage Build](#dockerfile-multi-stage-build)
4. [CI Pipeline](#ci-pipeline)

---

## Project File (.csproj)

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
    <PropertyGroup>
        <TargetFramework>net8.0</TargetFramework>
        <Nullable>enable</Nullable>
        <ImplicitUsings>enable</ImplicitUsings>
        <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    </PropertyGroup>

    <ItemGroup>
        <PackageReference Include="Serilog.AspNetCore" Version="8.0.0" />
        <PackageReference Include="Serilog.Formatting.Compact" Version="2.0.0" />
        <PackageReference Include="FluentValidation.AspNetCore" Version="11.3.0" />
        <PackageReference Include="Microsoft.Extensions.Diagnostics.HealthChecks" Version="8.0.0" />
    </ItemGroup>

    <ItemGroup>
        <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.0.0">
            <PrivateAssets>all</PrivateAssets>
        </PackageReference>
    </ItemGroup>
</Project>
```

```xml
<!-- tests/OrderService.Tests.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <TargetFramework>net8.0</TargetFramework>
        <IsPackable>false</IsPackable>
    </PropertyGroup>

    <ItemGroup>
        <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.10.0" />
        <PackageReference Include="xunit" Version="2.8.0" />
        <PackageReference Include="xunit.runner.visualstudio" Version="2.8.0" />
        <PackageReference Include="Moq" Version="4.20.70" />
        <PackageReference Include="coverlet.collector" Version="6.0.2" />
        <PackageReference Include="FluentAssertions" Version="6.12.0" />
    </ItemGroup>
</Project>
```

---

## Application Configuration

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, config) => config
    .ReadFrom.Configuration(context.Configuration)
    .Enrich.FromLogContext());

builder.Services.Configure<AppConfig>(builder.Configuration.GetSection("App"));
builder.Services.AddHealthChecks();
builder.Services.AddScoped<IOrderService, OrderService>();

var app = builder.Build();

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<CorrelationIdMiddleware>();
app.MapHealthChecks("/health");
app.MapControllers();
app.Run();
```

```csharp
public class CorrelationIdMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = context.Request.Headers["X-Correlation-Id"].FirstOrDefault()
            ?? Guid.NewGuid().ToString();
        context.Items["CorrelationId"] = correlationId;
        context.Response.Headers["X-Correlation-Id"] = correlationId;
        using (Serilog.Context.LogContext.PushProperty("CorrelationId", correlationId))
        {
            await next(context);
        }
    }
}
```

---

## Dockerfile Multi-Stage Build

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.sln .
COPY src/*/*.csproj ./
RUN for f in *.csproj; do mkdir -p src/${f%.csproj} && mv $f src/${f%.csproj}/; done
RUN dotnet restore
COPY . .
RUN dotnet publish src/OrderService/OrderService.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
WORKDIR /app
COPY --from=build /app/publish .
USER appuser
EXPOSE 8080
ENTRYPOINT ["dotnet", "OrderService.dll"]
```

---

## CI Pipeline

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'
      - name: Format check
        run: dotnet format --verify-no-changes
      - name: Build
        run: dotnet build --configuration Release
      - name: Test with coverage
        run: dotnet test --configuration Release --collect:"XPlat Code Coverage"
      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: '**/coverage.cobertura.xml'
```
