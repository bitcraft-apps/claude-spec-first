# Rate Limiter

Token-bucket rate limiter for API servers. Per-key, in-memory, single instance.

## Install

```
npm install
npx tsc
```

## Quick Start

### Express Middleware

```ts
import { rateLimiterMiddleware } from "./rate-limiter-middleware.js";

app.use(rateLimiterMiddleware());
```

The middleware reads the `x-api-key` header to identify callers. Requests without the header are grouped under `"anonymous"`.

### Standalone

```ts
import { RateLimiter } from "./rate-limiter.js";

const limiter = new RateLimiter();

if (limiter.canRequest("user-key-123")) {
  // proceed
} else {
  // rejected — quota exceeded
}
```

## Configuration

Both `RateLimiter` and `rateLimiterMiddleware` accept the same optional config:

| Option | Default | Description |
|--------|---------|-------------|
| `capacity` | `100` | Max burst tokens per key. Must be >= 0. |
| `rate` | `100` | Tokens refilled per minute. Must be > 0. |

```ts
rateLimiterMiddleware({ capacity: 50, rate: 30 });
```

Setting `capacity: 0` rejects all requests (useful for kill switches).

## Response When Limited

When a key exceeds its quota, the middleware returns:

- Status: `429 Too Many Requests`
- Header: `Retry-After: 60`
- Body: `{ "error": "Too Many Requests" }`

## Limits

- In-memory only. State resets on restart.
- Single instance. Multiple server instances each track independently.
- Idle keys are evicted after 1 hour.
