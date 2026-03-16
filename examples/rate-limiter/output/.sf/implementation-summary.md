# Implementation Summary: Token-Bucket Rate Limiter

## Files Created

- `src/rate-limiter.ts` — Token-bucket rate limiter class with per-key in-memory state
- `src/rate-limiter.test.ts` — 8 unit tests covering all acceptance criteria
- `src/rate-limiter-middleware.ts` — Express-style middleware returning 429 with `Retry-After: 60`
- `tsconfig.json` — Minimal TypeScript config
- `package.json` — Added vitest and typescript dev dependencies

## Acceptance Criteria Status

- [x] 100 requests with same key in 60s all succeed
- [x] Request 101 with same key returns 429
- [x] After 60s of inactivity, tokens refill and next request succeeds
- [x] Two different keys have independent limits
- [x] Burst capacity is configurable at initialization (default: 100)
- [x] Burst=0 still enforces base rate limit (all requests rejected since cap is 0)
- [x] Config rejects rate <= 0 or burst < 0

## Design Decisions

- `performance.now()` used as monotonic clock for refill timing
- TTL eviction runs on each `canRequest` call (simple, no timer needed)
- Middleware reads API key from `x-api-key` header, falls back to `"anonymous"`
- Restart resets all state (expected behavior per spec)
