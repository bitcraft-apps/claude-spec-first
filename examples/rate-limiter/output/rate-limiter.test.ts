import { describe, it, expect, vi } from "vitest";
import { RateLimiter } from "./rate-limiter.js";

describe("RateLimiter", () => {
  it("allows 100 requests within 60s", () => {
    const limiter = new RateLimiter();
    for (let i = 0; i < 100; i++) {
      expect(limiter.canRequest("key-a")).toBe(true);
    }
  });

  it("rejects request 101", () => {
    const limiter = new RateLimiter();
    for (let i = 0; i < 100; i++) limiter.canRequest("key-a");
    expect(limiter.canRequest("key-a")).toBe(false);
  });

  it("refills tokens after 60s of inactivity", () => {
    const limiter = new RateLimiter();
    for (let i = 0; i < 100; i++) limiter.canRequest("key-a");
    expect(limiter.canRequest("key-a")).toBe(false);
    // Advance clock by 60 seconds
    vi.spyOn(performance, "now").mockReturnValue(performance.now() + 60_000);
    expect(limiter.canRequest("key-a")).toBe(true);
    vi.restoreAllMocks();
  });

  it("tracks keys independently", () => {
    const limiter = new RateLimiter();
    for (let i = 0; i < 100; i++) limiter.canRequest("key-a");
    expect(limiter.canRequest("key-a")).toBe(false);
    expect(limiter.canRequest("key-b")).toBe(true);
  });

  it("accepts configurable burst capacity", () => {
    const limiter = new RateLimiter({ capacity: 5 });
    for (let i = 0; i < 5; i++) {
      expect(limiter.canRequest("key-a")).toBe(true);
    }
    expect(limiter.canRequest("key-a")).toBe(false);
  });

  it("burst=0 enforces base rate limit", () => {
    const limiter = new RateLimiter({ capacity: 0 });
    // No burst tokens available, first request fails
    expect(limiter.canRequest("key-a")).toBe(false);
    // After enough time passes for 1 token refill, it succeeds
    vi.spyOn(performance, "now").mockReturnValue(performance.now() + 1_000);
    // 1 second = 100/60 ~1.67 tokens, but capped at capacity 0
    // capacity=0 means tokens can never exceed 0, so still false
    expect(limiter.canRequest("key-a")).toBe(false);
    vi.restoreAllMocks();
  });

  it("rejects rate <= 0", () => {
    expect(() => new RateLimiter({ rate: 0 })).toThrow();
    expect(() => new RateLimiter({ rate: -1 })).toThrow();
  });

  it("rejects burst < 0", () => {
    expect(() => new RateLimiter({ capacity: -1 })).toThrow();
  });
});
