# Doc Context

## Technical Docs

- **Rate limiter**: Example application, not a plugin feature. No plugin doc updates needed.
- **Existing coverage**: `examples/rate-limiter/README.md` documents the workflow walkthrough.
- **Token bucket**: The algorithm used. Tokens refill continuously at `rate` tokens/minute, capped at `capacity`.
- **canRequest**: The single public method on `RateLimiter`. Consumes one token, returns boolean.
- **rateLimiterMiddleware**: Factory function returning Express middleware. Keys on `x-api-key` header.
- **429 response**: Static `Retry-After: 60` header, JSON body `{ "error": "Too Many Requests" }`.
- **TTL eviction**: Keys idle >1 hour are purged on next `canRequest` call. No background timer.

## User Docs

- **Audience**: Developers integrating the middleware into an Express API server.
- **Config options**: `capacity` (burst, default 100) and `rate` (tokens/min, default 100). Only two knobs.
- **API key identification**: Via `x-api-key` header; missing header falls back to `"anonymous"`.
- **capacity: 0**: Documented as a kill-switch pattern. Rejects all requests.
- **Limits section**: Covers in-memory-only, single-instance, and restart-clears-state. No distributed support.
