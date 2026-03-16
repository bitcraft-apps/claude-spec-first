export interface RateLimiterConfig {
  capacity?: number; // burst capacity, default 100
  rate?: number; // tokens per minute, default 100
}

interface Bucket {
  tokens: number;
  lastRefill: number;
  lastAccess: number;
}

const TTL_MS = 60 * 60 * 1000; // 1 hour

export class RateLimiter {
  private buckets = new Map<string, Bucket>();
  private capacity: number;
  private rate: number;

  constructor(config: RateLimiterConfig = {}) {
    const { capacity = 100, rate = 100 } = config;
    if (rate <= 0) throw new Error("rate must be > 0");
    if (capacity < 0) throw new Error("capacity must be >= 0");
    this.capacity = capacity;
    this.rate = rate;
  }

  canRequest(apiKey: string): boolean {
    this.evictStale();
    const now = performance.now();
    let bucket = this.buckets.get(apiKey);
    if (!bucket) {
      bucket = { tokens: this.capacity, lastRefill: now, lastAccess: now };
      this.buckets.set(apiKey, bucket);
    }
    // Refill tokens based on elapsed time
    const elapsed = (now - bucket.lastRefill) / 60_000; // minutes
    const refill = elapsed * this.rate;
    bucket.tokens = Math.min(this.capacity, bucket.tokens + refill);
    bucket.lastRefill = now;
    bucket.lastAccess = now;

    if (bucket.tokens >= 1) {
      bucket.tokens -= 1;
      return true;
    }
    return false;
  }

  private evictStale(): void {
    const now = performance.now();
    for (const [key, bucket] of this.buckets) {
      if (now - bucket.lastAccess > TTL_MS) this.buckets.delete(key);
    }
  }
}
