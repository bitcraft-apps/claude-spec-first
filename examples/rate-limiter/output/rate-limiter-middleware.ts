import { RateLimiter, RateLimiterConfig } from "./rate-limiter.js";

export function rateLimiterMiddleware(config?: RateLimiterConfig) {
  const limiter = new RateLimiter(config);
  return (req: { headers: Record<string, string> }, res: { status: (code: number) => { set: (header: string, value: string) => { json: (body: unknown) => void } } }, next: () => void) => {
    const apiKey = req.headers["x-api-key"] ?? "anonymous";
    if (limiter.canRequest(apiKey)) {
      next();
    } else {
      res.status(429).set("Retry-After", "60").json({ error: "Too Many Requests" });
    }
  };
}
