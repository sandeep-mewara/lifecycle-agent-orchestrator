# C# Testing — Checklist

## When Writing Unit Tests

- [ ] Test class named `<ClassName>Tests` in matching namespace under `tests/`
- [ ] xUnit `[Fact]` for single-case tests, `[Theory]` for data-driven tests
- [ ] `[InlineData]`, `[MemberData]`, or `[ClassData]` for parameterized tests
- [ ] Moq or NSubstitute for dependency mocking
- [ ] FluentAssertions preferred (`result.Should().Be(expected)`)
- [ ] `Assert.ThrowsAsync<T>()` for async exception assertions
- [ ] Constructor injection for test setup (xUnit creates new instance per test)
- [ ] `ITestOutputHelper` for test-scoped logging

## When Writing Integration Tests

- [ ] `WebApplicationFactory<Program>` for in-process API testing
- [ ] `IClassFixture<T>` for shared expensive setup (app factory, database)
- [ ] `HttpClient` from factory for HTTP endpoint testing
- [ ] `[Collection]` attribute for tests sharing expensive fixtures
- [ ] Testcontainers for database/infrastructure dependencies
- [ ] `appsettings.Testing.json` for test configuration overrides
- [ ] Tests in separate project (`*.IntegrationTests.csproj`)

## dotnet test & CI

- [ ] Coverlet configured with >=85% line coverage threshold
- [ ] `dotnet test --collect:"XPlat Code Coverage"` in CI
- [ ] Test results in TRX format for CI reporting
- [ ] `dotnet format --verify-no-changes` in CI pipeline

## Agent Evaluation Tests

- [ ] Tests tagged with `[Trait("Category", "AgentEvaluation")]`
- [ ] Excluded from default test run (`--filter "Category!=AgentEvaluation"`)
- [ ] Separate CI stage for evaluation runs
