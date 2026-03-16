# Token-Bucket Rate Limiter — 100 req/min per API key, in-memory, single instance

## Problem

API has no rate limiting. Any key can make unlimited requests, risking resource exhaustion and abuse. Need a minimal token-bucket limiter that returns 429 when quota is exceeded.

## Scope

### In

- `src/rate-limiter.ts` (~40 lines) — token-bucket implementation
  - `canRequest(apiKey: string): bool` consumes a token or returns false
  - Configurable: `capacity` (burst), `refillRate` fixed at 100/min
  - Per-key in-memory state, initialized to full capacity on first request
  - Monotonic clock for refill timing
  - TTL cleanup: evict keys idle > 1 hour
- `src/rate-limiter.test.ts` (~60 lines) — unit tests for all acceptance criteria
- Middleware integration: return HTTP 429 with `Retry-After` header when `canRequest` returns false

### Out

- Distributed/multi-instance rate limiting
- Persistent state across restarts
- Rate limit headers (X-RateLimit-*)
- Per-endpoint or per-user/IP limits
- Dynamic config updates
- Retry-After calculation (use static `60`)

## Acceptance Criteria

- [x] 100 requests with same key in 60s all succeed
- [x] Request 101 with same key returns 429
- [x] After 60s of inactivity, tokens refill and next request succeeds
- [x] Two different keys have independent limits
- [x] Burst capacity is configurable at initialization (default: 100)
- [x] Burst=0 still enforces base rate limit
- [x] Config rejects rate <= 0 or burst < 0

## Risks

1. **Restart resets all state** — accepted for MVP. Document as expected behavior.
2. **Multi-instance multiplies effective quota** — out of scope. Single-instance only.
3. **Memory growth from abandoned keys** — mitigate with 1-hour TTL eviction.
4. **Burst > rate creates unsustainable spikes** — validate burst <= capacity at init.
