# Example: Rate Limiter

Build a token-bucket rate limiter using the spec-first workflow.

## 1. Write the spec

```
/sf:spec
```

Describe what you need:

> Token-bucket rate limiter. 100 requests per minute per API key.
> Returns 429 when exceeded. Configurable burst allowance.

Review the generated spec, then proceed to implementation.

## 2. Implement

```
/sf:implement
```

Generates working code from the spec, following existing patterns in your codebase.

## 3. Document

```
/sf:document
```

Produces user-facing and technical docs based on the implementation.

## What to expect

Each command runs autonomously. Review the output, iterate if needed.
The workflow is sequential: **spec > implement > document**.

No generated artifacts are included in this example — run it yourself to see the output.
