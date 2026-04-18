# Java Coding Standards — Checklist

## When Writing or Modifying Code

### Naming
- [ ] Methods use `camelCase` with verb-first names (`getOrderData`, `validateRequest`)
- [ ] Classes and interfaces use `PascalCase`
- [ ] Variables use `camelCase` — descriptive names (`userId` not `uid`)
- [ ] Constants use `UPPER_SNAKE_CASE` with `static final`
- [ ] Packages use lowercase dot-separated (`com.example.service.order`)
- [ ] Exception classes suffixed with `Exception` (`AuthorizationException`)
- [ ] Booleans prefixed with `is`/`has`/`can` (`isActive`, `hasPermission`)

### Error Handling
- [ ] Custom exception hierarchy extending `RuntimeException` for unchecked, `Exception` for checked
- [ ] `@ControllerAdvice` / `@ExceptionHandler` for centralized error-to-HTTP mapping
- [ ] Specific exceptions caught first, generic `Exception` last
- [ ] `throw new ... (message, cause)` to preserve exception chains
- [ ] Logger call before re-throwing exceptions
- [ ] Business exceptions carry error codes (`ErrorCode` enum)

### Structured Logging
- [ ] SLF4J as logging facade, Logback as implementation
- [ ] MDC (Mapped Diagnostic Context) for correlation ID propagation
- [ ] Parameterized logging: `log.info("Processing order {}", orderId)` — not string concatenation
- [ ] No `System.out.println()` or `System.err.println()` in production code
- [ ] JSON layout in production (Logstash encoder or similar)
- [ ] Log levels follow the universal matrix

### Data Models
- [ ] Records or immutable classes for DTOs
- [ ] Bean Validation annotations (`@NotNull`, `@Size`, `@Valid`) on request models
- [ ] Jackson annotations for serialization control
- [ ] `Optional<T>` for nullable return types — never return `null` from public methods

### Imports
- [ ] No wildcard imports (`import java.util.*`)
- [ ] Groups: `java.*` → `javax.*` → third-party → project
- [ ] No unused imports (IDE auto-cleanup)

## When Setting Up a New Project

### Configuration
- [ ] Spring profiles for environment hierarchy (`application.yml`, `application-dev.yml`, `application-prod.yml`)
- [ ] `@ConfigurationProperties` for type-safe config binding
- [ ] Secrets via environment variables or vault client — never in `application.yml`

### Project Structure
- [ ] Maven or Gradle with wrapper committed (`mvnw` / `gradlew`)
- [ ] Standard layout: `src/main/java/`, `src/main/resources/`, `src/test/java/`
- [ ] Package-by-feature, not package-by-layer

### Tooling
- [ ] Checkstyle or Google Java Format for consistent style
- [ ] SpotBugs or Error Prone for static analysis
- [ ] JaCoCo for coverage (>=85% threshold)
- [ ] `pom.xml` / `build.gradle` with dependency management (BOM for Spring Boot)
- [ ] Dependency lock via `pom.xml` versions or Gradle lock file

### App Initialization
- [ ] Spring Boot `@SpringBootApplication` with component scan
- [ ] `@Bean` lifecycle management via Spring container
- [ ] Health checks via Spring Actuator (`/actuator/health`)
- [ ] Graceful shutdown configured (`server.shutdown=graceful`)
