# Rate Limiter — Technical Docs

## API Reference

### `RateLimiterConfig`

```typescript
interface RateLimiterConfig {
  capacity?: number; // Burst capacity (max tokens). Default: 100. Must be >= 0.
  rate?: number;     // Tokens per minute. Default: 100. Must be > 0.
}
```

### `RateLimiter`

```typescript
import { RateLimiter } from "./rate-limiter.js";

const limiter = new RateLimiter({ capacity: 100, rate: 100 });
limiter.canRequest("user-key-123"); // true | false
```

- **`constructor(config?: RateLimiterConfig)`** — Throws if `rate <= 0` or `capacity < 0`.
- **`canRequest(apiKey: string): boolean`** — Consumes one token for the given key. Returns `false` when the bucket is empty. New keys start at full capacity. Idle keys (>1 hour) are evicted automatically.

### `rateLimiterMiddleware`

```typescript
import { rateLimiterMiddleware } from "./rate-limiter-middleware.js";

app.use(rateLimiterMiddleware({ capacity: 100, rate: 100 }));
```

Express-compatible middleware. Identifies callers by the `x-api-key` request header (falls back to `"anonymous"`).

**On success**: calls `next()`.

**On limit exceeded**: responds with:
- Status: `429`
- Header: `Retry-After: 60`
- Body: `{ "error": "Too Many Requests" }`

## Constraints

- In-memory only. State resets on restart.
- Single-instance. Multiple processes each enforce independent limits.
- No `X-RateLimit-*` headers. No per-endpoint limits.
