# Java Security — Code Examples

## Table of Contents
1. [Spring Security Configuration](#spring-security-configuration)
2. [Secrets Management](#secrets-management)
3. [Input Validation](#input-validation)
4. [Safe Error Responses](#safe-error-responses)
5. [PII-Safe Logging](#pii-safe-logging)

---

## Spring Security Configuration

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                .requestMatchers("/api/**").authenticated()
                .anyRequest().denyAll()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .csrf(AbstractHttpConfigurer::disable)
            .build();
    }
}
```

---

## Secrets Management

```java
@ConfigurationProperties(prefix = "app.secrets")
public record SecretsConfig(
    String apiKeyPath,      // e.g., "vault/data/myapp/api-key"
    String dbPasswordPath   // e.g., "vault/data/myapp/db-password"
) {}

@Service
public class SecretsService {
    private final VaultTemplate vault;
    private final SecretsConfig config;

    public SecretsService(VaultTemplate vault, SecretsConfig config) {
        this.vault = vault;
        this.config = config;
    }

    public String getApiKey() {
        var response = vault.read(config.apiKeyPath());
        if (response == null || response.getData() == null) {
            throw new ServiceException(ErrorCode.INTERNAL_ERROR, "Secret not found", 500);
        }
        return (String) response.getData().get("value");
    }
}
```

---

## Input Validation

```java
public record CreateUserRequest(
    @NotBlank(message = "Name is required")
    @Size(max = 100, message = "Name must be 100 characters or fewer")
    String name,

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    String email,

    @NotNull(message = "Role is required")
    UserRole role
) {}

@RestController
@RequestMapping("/api/users")
public class UserController {
    @PostMapping
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody CreateUserRequest request) {
        return ResponseEntity.ok(userService.create(request));
    }
}
```

---

## Safe Error Responses

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        var errors = ex.getBindingResult().getFieldErrors().stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .toList();
        return ResponseEntity.badRequest()
            .body(new ErrorResponse("validation_error", String.join("; ", errors)));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex) {
        // Log full detail for debugging — never expose to client
        log.error("Unexpected error", ex);
        return ResponseEntity.internalServerError()
            .body(new ErrorResponse("internal_error", "An internal error occurred"));
    }
}
```

---

## PII-Safe Logging

```java
// GOOD — identifiers and metadata only
log.info("Processing order, orderId={}, itemCount={}", order.getId(), order.getItems().size());

// BAD — leaks sensitive data
// log.info("Processing order: {}", order);   // toString() may include PII
// log.info("Payment: card={}", order.getPayment().getCardNumber());
```

```java
// Safe toString() override
public record Order(String id, String customerId, PaymentInfo payment, List<LineItem> items) {
    @Override
    public String toString() {
        return "Order[id=%s, itemCount=%d]".formatted(id, items.size());
    }
}
```
