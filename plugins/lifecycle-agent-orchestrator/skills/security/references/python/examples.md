# Security Standards — Code Examples

## Table of Contents
1. [PII-Safe Logging](#pii-safe-logging)
2. [Prompt Injection Defense](#prompt-injection-defense)
3. [IAM Auth Enforcement](#iam-auth-enforcement)
4. [Safe Error Responses](#safe-error-responses)

---

## PII-Safe Logging

**What to log vs. what not to log:**

```python
import structlog

logger = structlog.get_logger()

async def analyze(self, order_data, order_id, user_id):
    # GOOD — identifiers and metadata only
    logger.info(
        "starting_analysis",
        order_id=order_id,
        order_year=order_data.order_year,
        order_status=order_data.order_status,
        promotion_count=len(applicable_promotions),
    )

    # BAD — never log transaction or other sensitive domain values
    # logger.info("order_data", card_number=order_data.payment.card_number)
    # logger.info("full_request", data=order_data.model_dump_json())
```

**Promotion execution — log outcome, not data:**

```python
# GOOD — what happened, not what the numbers are
logger.info(
    "promotion_applied",
    promotion_id=promotion.promotion_id,
    eligible=result.applicable,
    confidence=result.confidence_score,
)

# BAD — leaks order total impact values
# logger.info("promotion_result", order_total_change=result.impact.order_total_change)
```

---

## Prompt Injection Defense

**Structured data injection — not string concatenation:**

```python
# GOOD — named template variables, user data in data fields only
PRICING_PROMPT = """\
You are a precise, step-by-step order pricing calculator.

ORDER YEAR: {order_year}
ORDER STATUS: {order_status}
ACCOUNT BALANCE (pre-computed): ${account_balance:,.2f}

{pricing_rules_text}

FULL ORDER DATA (JSON):
{order_data_json}

COMPUTE the order total by working through EVERY step below.
...
"""

prompt = PRICING_PROMPT.format(
    order_year=order_year,
    order_status=order_status,
    account_balance=account_balance,
    pricing_rules_text=get_pricing_rules(order_year, order_status),
    order_data_json=order_data.model_dump_json(),
)
```

```python
# BAD — user input directly interpolated into instructions
prompt = f"Calculate order total for this user request: {user_message}"
```

**LLM output validation before use:**

```python
# Always validate LLM output structure and consistency
order_state = OrderState(**json_data)  # Pydantic validates types

errors = _validate_consistency(order_state, order_year)
if errors:
    # Don't trust the output — retry or degrade
    logger.warning("validation_failed", errors=errors, attempt=attempt)
```

---

## IAM Auth Enforcement

**Gateway auth check — minimal allowlist:**

```python
AUTH_EXEMPT_ROUTES = {
    "/health/full",
    "/actuator/loggers/ROOT",
    "/actuator/threaddump",
    "/metrics",
}

async def check_auth_required(request: Request, settings) -> None:
    forwarded_port = request.headers.get("X-Forwarded-Port")
    path = request.url.path

    if path in AUTH_EXEMPT_ROUTES:
        return

    raise AuthorizationError("This route requires gateway authentication")
```

**Header validation — reject malformed tokens at parse time:**

```python
import re
from typing import Annotated
from pydantic import AfterValidator, BaseModel

def validate_positive_integer_id(v: str) -> str:
    if not re.match(r"^[1-9][0-9]*$", v):
        raise ValueError(f"Must be a positive integer, got: {v}")
    return v

def validate_non_empty_token(v: str) -> str:
    if not v.strip():
        raise ValueError("Token must be non-empty")
    return v

UserId = Annotated[str, AfterValidator(validate_positive_integer_id)]
AuthToken = Annotated[str, AfterValidator(validate_non_empty_token)]

class AuthContext(BaseModel):
    user_id: UserId
    auth_token: AuthToken  # also validated
```

**Per-call token refresh — never cache beyond a request:**

```python
async def _arun(self, ..., config: RunnableConfig) -> str:
    agent_context = config["configurable"]["agent_context"]
    headers = agent_context.get_header()  # fresh IAM tokens per call
    self._calculator.set_auth_headers(headers)
    result = await self._engine.analyze(order_data)
    ...
```

---

## Safe Error Responses

**What the user sees vs. what gets logged:**

```python
def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AgentInvokeException)
    async def handle_agent_invoke(request: Request, ex: AgentInvokeException):
        # LOG: full detail for debugging (but no PII)
        logger.warning(
            "request_rejected",
            error_type=type(ex).__name__,
            transaction_id=getattr(request.state, "transaction_id", "unknown"),
        )
        # RESPOND: generic message, machine-readable code
        return JSONResponse(
            content={"message": "An internal error occurred", "code": "agent_invoke_error"},
            status_code=500,
        )
```

**What must NOT appear in error responses:**
```python
# BAD — leaks internal details
return JSONResponse(content={
    "message": str(ex),           # may contain stack trace
    "order_data": order_data.dict(),  # PII
    "prompt": prompt_text,        # internal LLM prompt
})
```
