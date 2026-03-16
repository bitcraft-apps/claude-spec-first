# Implementation Summary

## Files
- `src/rate-limiter.ts` (56 lines) — Token-bucket class with per-key Map
- `src/rate-limiter.test.ts` (63 lines) — 8 vitest tests covering all criteria
- `src/rate-limiter-middleware.ts` (13 lines) — Express middleware, 429 + Retry-After
- `tsconfig.json` — ES2020 strict mode
- `package.json` — vitest + typescript devDeps

## Public API

**Class `RateLimiter`**
- `constructor(config?: { capacity?: number; rate?: number })`
- `canRequest(apiKey: string): boolean`

**Function `rateLimiterMiddleware(config?)`**
- Returns Express-compatible `(req, res, next)` middleware
- Reads `x-api-key` header, falls back to `"anonymous"`

## Design Decisions
- `performance.now()` for monotonic timing
- Map<string, Bucket> for per-key state, initialized to full capacity
- TTL eviction on every `canRequest()` call (no timer)
- Static `Retry-After: 60`
- Validation at init, not runtime

## Test Coverage
All 7 acceptance criteria mapped to tests plus edge cases (capacity=0, invalid config).
