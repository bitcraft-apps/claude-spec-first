# MVP Scope: Token-Bucket Rate Limiter

## In Scope

### Core Functionality
- Token-bucket algorithm implementation
- Rate limit: 100 requests/minute per API key
- HTTP 429 (Too Many Requests) response when limit exceeded
- Configurable burst capacity (single integer parameter)
- Per-API-key tracking with in-memory storage

### Required Interface
- Single rate limit check function: `canRequest(apiKey: string) -> bool`
- Configuration: `capacity` (burst) + `refillRate` (100 req/min)
- Automatic token refill based on elapsed time

### Minimum Viable Behavior
- Reject requests when tokens exhausted
- Return 429 status code
- Track token state per API key

## Out of Scope (Future Considerations)

### Storage & Persistence
- Database persistence (in-memory only for MVP)
- Distributed rate limiting across multiple instances
- Backup/recovery of rate limit state

### Observability
- Detailed metrics/logging
- Rate limit headers (X-RateLimit-*)
- Analytics or audit trails

### Advanced Features
- Per-endpoint rate limits
- Time-window sliding windows
- User/IP-based (API key only)
- Backpressure/queue management
- Tiered/different limits per customer

### Configuration
- Dynamic config updates without restart
- Per-API-key custom limits
- Multiple rate limit rules

### Error Handling
- Graceful degradation on memory limits
- Circuit breaker patterns
- Retry-After header calculation

## Acceptance Criteria

1. Function rejects request when bucket empty (returns false)
2. Function accepts request when tokens available (returns true)
3. Tokens refill at 100/60 per second
4. Burst capacity configurable at initialization
5. Per-API-key state maintained independently
6. Returns 429 when appropriate

## Non-Functional

- Size: ~40 lines core logic
- No external dependencies
- Synchronous operation
- No persistence layer required
