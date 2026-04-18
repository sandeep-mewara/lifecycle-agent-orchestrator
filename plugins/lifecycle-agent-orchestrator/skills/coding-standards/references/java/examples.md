# Java Coding Standards — Code Examples

## Table of Contents
1. [Environment-Based Configuration](#environment-based-configuration)
2. [Exception Hierarchy and Handlers](#exception-hierarchy-and-handlers)
3. [Structured Logging with SLF4J](#structured-logging-with-slf4j)
4. [Bean Validation and DTOs](#bean-validation-and-dtos)
5. [Async Patterns](#async-patterns)
6. [Test Patterns](#test-patterns)

---

## Environment-Based Configuration

```yaml
# application.yml (base)
app:
  name: order-service
  metrics:
    enabled: true

# application-dev.yml
app:
  metrics:
    enabled: false
logging:
  level:
    root: DEBUG

# application-prod.yml
app:
  metrics:
    enabled: true
logging:
  level:
    root: INFO
```

```java
@ConfigurationProperties(prefix = "app")
public record AppConfig(
    String name,
    MetricsConfig metrics
) {
    public record MetricsConfig(boolean enabled) {}
}
```

---

## Exception Hierarchy and Handlers

```java
public enum ErrorCode {
    BAD_REQUEST("bad_request"),
    UNAUTHORIZED("unauthorized"),
    RATE_LIMITED("rate_limited"),
    INTERNAL_ERROR("internal_error");

    private final String code;
    ErrorCode(String code) { this.code = code; }
    public String getCode() { return code; }
}

public class ServiceException extends RuntimeException {
    private final ErrorCode errorCode;
    private final int httpStatus;

    public ServiceException(ErrorCode errorCode, String message, int httpStatus) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }

    public ServiceException(ErrorCode errorCode, String message, int httpStatus, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }
}

public class AuthorizationException extends ServiceException {
    public AuthorizationException(String message) {
        super(ErrorCode.UNAUTHORIZED, message, 401);
    }
}
```

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ServiceException.class)
    public ResponseEntity<ErrorResponse> handleServiceException(ServiceException ex) {
        log.warn("Service error: code={}, message={}", ex.getErrorCode(), ex.getMessage());
        return ResponseEntity
            .status(ex.getHttpStatus())
            .body(new ErrorResponse(ex.getErrorCode().getCode(), ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity
            .status(500)
            .body(new ErrorResponse("internal_error", "An internal error occurred"));
    }
}

public record ErrorResponse(String code, String message) {}
```

---

## Structured Logging with SLF4J

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

public class OrderService {
    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    public OrderResponse processOrder(OrderRequest request) {
        MDC.put("orderId", request.orderId());
        MDC.put("transactionId", request.transactionId());
        try {
            log.info("Processing order");
            var result = executeOrderLogic(request);
            log.info("Order processed successfully, itemCount={}", result.itemCount());
            return result;
        } catch (Exception ex) {
            log.error("Order processing failed", ex);
            throw ex;
        } finally {
            MDC.clear();
        }
    }
}
```

```xml
<!-- logback-spring.xml (production) -->
<configuration>
    <appender name="JSON" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <includeMdcKeyName>transactionId</includeMdcKeyName>
            <includeMdcKeyName>orderId</includeMdcKeyName>
        </encoder>
    </appender>
    <root level="INFO">
        <appender-ref ref="JSON"/>
    </root>
</configuration>
```

---

## Bean Validation and DTOs

```java
public record CreateOrderRequest(
    @NotBlank String customerId,
    @NotEmpty @Valid List<LineItem> items,
    @NotNull OrderType orderType
) {}

public record LineItem(
    @NotBlank String productId,
    @Positive int quantity,
    @PositiveOrZero BigDecimal unitPrice
) {}

@RestController
@RequestMapping("/api/orders")
public class OrderController {
    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(@Valid @RequestBody CreateOrderRequest request) {
        return ResponseEntity.ok(orderService.create(request));
    }
}
```

---

## Async Patterns

```java
@Service
public class NotificationService {
    private final WebClient webClient;

    public NotificationService(WebClient.Builder builder) {
        this.webClient = builder.baseUrl("https://api.notifications.example.com").build();
    }

    public Mono<NotificationResponse> sendNotification(NotificationRequest request) {
        return webClient.post()
            .uri("/send")
            .bodyValue(request)
            .retrieve()
            .bodyToMono(NotificationResponse.class)
            .timeout(Duration.ofSeconds(5))
            .retryWhen(Retry.backoff(3, Duration.ofMillis(500)))
            .doOnError(ex -> log.warn("Notification failed: {}", ex.getMessage()));
    }
}
```

---

## Test Patterns

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {
    @Mock private OrderRepository repository;
    @Mock private NotificationService notifications;
    @InjectMocks private OrderService service;

    @Test
    void createOrder_validRequest_returnsOrderWithId() {
        var request = new CreateOrderRequest("cust-1", List.of(new LineItem("prod-1", 2, BigDecimal.TEN)), OrderType.STANDARD);
        when(repository.save(any())).thenAnswer(inv -> {
            var order = inv.getArgument(0, Order.class);
            return order.withId("order-123");
        });

        var result = service.create(request);

        assertThat(result.orderId()).isEqualTo("order-123");
        verify(notifications).sendNotification(any());
    }

    @Test
    void createOrder_emptyItems_throwsBadRequest() {
        var request = new CreateOrderRequest("cust-1", List.of(), OrderType.STANDARD);

        assertThatThrownBy(() -> service.create(request))
            .isInstanceOf(ServiceException.class)
            .extracting("errorCode")
            .isEqualTo(ErrorCode.BAD_REQUEST);
    }
}
```
