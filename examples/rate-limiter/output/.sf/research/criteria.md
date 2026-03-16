# Acceptance Criteria: Token-Bucket Rate Limiter

## Must Pass

1. **Rate limit enforced per API key**
   - Send 101 requests in 60 seconds with same key → 429 on request 101
   - Send 100 requests in 60 seconds with same key → all succeed (200/201)

2. **Returns 429 status code**
   - Request exceeds limit → HTTP 429 response
   - Response body includes `Retry-After` header with seconds

3. **Configurable burst capacity**
   - Accept `RATE_LIMITER_BURST` env var or config parameter
   - Default burst = 100 (tokens)
   - Allow 100 + burst tokens in first refill window

4. **Tokens refill at 100 req/min rate**
   - Make 101 requests (hit limit)
   - Wait 60 seconds
   - Next request succeeds (tokens refilled)

5. **Per-key isolation**
   - Two different API keys → separate limits
   - Key A at limit does not block key B requests

## Edge Cases (Must Not Fail)

- Requests with no API key → consistent behavior (block or pass, documented)
- Concurrent requests same key → no race conditions (correct count)
- Burst = 0 → system still enforces base rate limit

## Definition of Done

All 5 "Must Pass" criteria pass. Can test via integration test or manual requests.
