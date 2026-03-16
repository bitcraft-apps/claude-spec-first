# Rate Limiter Risks

## Blockers

### 1. State Persistence Across Restarts
**Risk**: Token bucket state (current tokens, last refill time) is lost on service restart, allowing temporary burst abuse.
**Impact**: First requests after restart can exhaust quota before normal rate applies.
**Solution**: Store state in-memory with clear acceptance that restart resets limits. Document as expected behavior.

### 2. Distributed System State
**Risk**: Multiple service instances have independent buckets per API key, multiplying effective quota.
**Impact**: 100 req/min per instance defeats the per-key guarantee if not enforced globally.
**Solution**: Clarify if this is single-instance only. If distributed is needed, require external state store (Redis, database).

### 3. Clock Skew / Time-Based Precision
**Risk**: System clock adjustments or microsecond precision differences in refill calculations cause inconsistent token allocation.
**Impact**: Unfair limiting or gaps in enforcement.
**Solution**: Use monotonic clock source (not wall clock) for refill timing. Clamp refill to prevent negative time deltas.

## Edge Cases

### 1. First Request
**Risk**: Uninitialized bucket has undefined state.
**Solution**: Initialize with full capacity on first request.

### 2. Burst Larger Than Capacity
**Risk**: Configurable burst exceeds sustainable rate (e.g., burst = 1000, rate = 100/min).
**Impact**: Queue builds indefinitely if burst is consumed.
**Solution**: Validate burst <= rate * time_window. Reject invalid config.

### 3. API Key Lifecycle
**Risk**: Expired/revoked keys still accumulate tokens in memory.
**Impact**: Memory leak or reactivation of revoked key sees unused quota.
**Solution**: Implement TTL for inactive keys (e.g., clear bucket after 24h without requests).

### 4. Zero or Negative Configuration
**Risk**: Rate = 0, burst = negative passed to limiter.
**Impact**: Undefined behavior (division by zero, rejection of all requests).
**Solution**: Validate rate > 0, burst >= 0 at initialization.

### 5. 429 Response Under Load
**Risk**: No backoff guidance; clients may retry immediately, amplifying load.
**Impact**: Cascade failure if client behavior is synchronous.
**Solution**: Include `Retry-After` header in 429 response. Document client retry expectations.

## Assumptions to Validate

- **Single instance or distributed?** (Determines if external state needed)
- **API keys managed externally?** (Who creates/revokes keys? Scope of limiter?)
- **Burst behavior**: Is it refillable continuously or one-time per window?

## Simple MVP Approach

- Single-instance, in-memory token bucket
- Clear bucket state on service start
- Validate config (rate > 0, burst reasonable)
- Return 429 with `Retry-After: 60` header
- Clock-based refill using `time.now()` with monotonic source
- TTL cleanup for unused keys after 1 hour
