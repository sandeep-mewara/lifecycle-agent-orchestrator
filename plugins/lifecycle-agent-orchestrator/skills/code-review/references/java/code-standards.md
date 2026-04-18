# Java Code Standards Quick Reference

Java-specific conventions for code reviews. Use alongside the universal `code-standards.md`.

---

## Formatting and Tooling

| Tool | Config | Enforcement |
|------|--------|-------------|
| **Google Java Format** or **Spotless** | Standard Google style | Pre-commit + CI (Maven/Gradle verify) |
| **Checkstyle** | Google or Sun conventions | CI via Maven plugin |
| **SpotBugs / Error Prone** | Default rules + custom detectors | CI via Maven plugin |
| **JaCoCo** | >=85% line coverage | CI via Maven verify |
| **JUnit 5** | Tags: `unit`, `integration`, `agent-evaluation` | CI via Surefire/Failsafe |

---

## Java Style

### Functions and Types
- **Type annotations on all public method signatures.** Use generics, avoid raw types.
- **Records** for immutable DTOs. Use classes only when mutability or inheritance is needed.
- **Bean Validation** (`@NotNull`, `@Valid`, `@Size`) on request models.
- **`Optional<T>`** for nullable return types — never return `null` from public methods.

### Naming
- **Packages:** lowercase dot-separated (`com.example.service.order`)
- **Classes/Interfaces:** `PascalCase` nouns (`OrderService`, `PaymentGateway`)
- **Methods:** `camelCase` verb-noun (`fetchOrderDetails`, `calculateTotal`)
- **Constants:** `UPPER_SNAKE_CASE` with `static final`

### Error Handling
- **`@ControllerAdvice`** with `@ExceptionHandler` for centralized error mapping.
- **Custom exception hierarchy** extending `RuntimeException` for unchecked exceptions.
- **`throw new XException(message, cause)`** to preserve exception chains.
- **`ResponseEntity<ErrorResponse>`** for consistent error response structure.

### Async Patterns
- **`CompletableFuture`** or **Project Reactor** (`Mono`/`Flux`) for async operations.
- **Connection pooling** via `WebClient` or `RestClient` with connection limits.
- **`@Async`** for fire-and-forget background tasks.

---

## Project Structure

```
src/main/java/com/example/service/
├── controller/      # REST controllers — no business logic
├── service/         # Business logic, orchestration
├── model/           # DTOs, request/response records
├── repository/      # Data access (JPA, JDBC)
├── client/          # External service clients
├── config/          # Spring configuration classes
└── exception/       # Custom exception hierarchy

src/test/java/com/example/service/
├── controller/      # Controller tests (@WebMvcTest)
├── service/         # Unit tests (@ExtendWith(MockitoExtension))
└── integration/     # Full context tests (@SpringBootTest)
```

---

## Spring Boot Specifics

- **Constructor injection** preferred over `@Autowired` field injection.
- **`@ConfigurationProperties`** for type-safe configuration.
- **Profiles** (`application-dev.yml`, `application-prod.yml`) for environment hierarchy.
- **Actuator** endpoints for health, metrics, and info.
- **Graceful shutdown** via `server.shutdown=graceful`.
