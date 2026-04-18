# Java Security — Checklist

## 1. Secret Management
- [ ] Secrets via Spring Cloud Vault, AWS Secrets Manager SDK, or environment variables injected by orchestrator
- [ ] `@ConfigurationProperties` references secret paths, not literal values
- [ ] No secrets in `application.yml` or `application.properties`
- [ ] `spring-boot-starter-actuator` endpoints secured (sensitive endpoints require auth)

## 2. Authentication & Authorization
- [ ] Spring Security filter chain configured with appropriate auth mechanism
- [ ] `@PreAuthorize` or method security for fine-grained access control
- [ ] CORS configured restrictively (`@CrossOrigin` only where needed with specific origins)
- [ ] CSRF protection enabled for browser-facing endpoints
- [ ] Session management configured (stateless for APIs, secure cookies for web)

## 3. OWASP / Secure Coding
- [ ] Bean Validation (`@Valid`, `@NotNull`, `@Size`) on all controller request parameters
- [ ] `@RequestBody` validated with `@Valid` annotation
- [ ] No raw SQL — use JPA/Hibernate parameterized queries or `JdbcTemplate` with `?` placeholders
- [ ] Jackson `DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES` enabled
- [ ] `ObjectMapper` configured to not include type info by default (CVE prevention)

## 4. Dependencies & Vulnerabilities
- [ ] `maven-dependency-check-plugin` or `gradle-dependency-check` in build
- [ ] Spring Boot BOM manages transitive dependency versions
- [ ] `mvn dependency:tree` reviewed for unexpected transitive dependencies
- [ ] Container base image pinned to specific digest, not just tag

## 5. API Security
- [ ] `@ControllerAdvice` with `@ExceptionHandler` — no stack traces in responses
- [ ] Spring Security `HttpSecurity` chain with `.authorizeHttpRequests()`
- [ ] Rate limiting via Spring Cloud Gateway or API gateway
- [ ] Request size limits configured (`server.tomcat.max-http-form-post-size`)

## 6. Sensitive Data Protection
- [ ] SLF4J MDC for correlation context — no sensitive values in MDC
- [ ] Logback/Logstash JSON encoder with field filtering
- [ ] `@JsonIgnore` on sensitive model fields
- [ ] `toString()` overrides exclude sensitive fields
