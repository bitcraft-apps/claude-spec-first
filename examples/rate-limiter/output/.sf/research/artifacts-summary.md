# Artifacts Summary

**Project**: Token-Bucket Rate Limiter — 100 req/min per API key, in-memory, single instance

## Requirements
- Token-bucket algorithm: 100 requests/minute per API key
- HTTP 429 with `Retry-After: 60` when quota exceeded
- Configurable burst capacity (default 100, must be >= 0)
- Per-API-key in-memory tracking with independent limits
- Core function: `canRequest(apiKey: string): bool`
- Monotonic clock (`performance.now()`) for refill timing
- TTL eviction for idle keys (>1 hour)

## Acceptance Criteria (All Passed)
1. 100 requests with same key in 60s all succeed
2. Request 101 returns 429
3. After 60s inactivity, tokens refill
4. Two different keys have independent limits
5. Burst capacity configurable (default: 100)
6. Burst=0 enforces rate limit (all rejected)
7. Config rejects rate <= 0 or burst < 0

## Scope Boundaries
- **In**: Token-bucket core, middleware, unit tests, configurable capacity
- **Out**: Distributed rate limiting, persistence, X-RateLimit-* headers, per-endpoint limits, dynamic config

## Risks
1. Restart resets state → Accepted for MVP
2. Multi-instance multiplies quota → Out of scope
3. Memory growth → 1-hour TTL eviction
4. Invalid config → Validation at init
