# AGENTS.md

Rules for all agents in this project — especially doc-generating agents.

## Documentation Rules

1. **Minimum viable docs.** Document what the user needs to know. If a feature is automatic and invisible, one sentence is enough.
2. **No duplication.** Agent files are the source of truth for agent details. Do not re-list agent names, tools, or descriptions in docs that readers can find in `framework/agents/`.
3. **No speculative content.** Do not add troubleshooting for problems nobody has reported. Do not document rationale unless the design is surprising.
4. **Proportional to the change.** A one-line config change does not need a new section, glossary entries, ASCII diagrams, or worked examples. Match doc weight to change weight.
5. **No branding internal mechanics.** Do not invent terms like "two-tier model routing" for simple concepts. Say what it does plainly.
6. **User guide = user actions only.** If the user doesn't need to do anything, don't explain the internals. One line noting the behavior is sufficient.
7. **Technical reference = contract surface.** Document interfaces, schemas, and extension points. Do not duplicate orchestration flows already defined in command files.

## Code Rules

1. **YAGNI, KISS, SRP** — inherited from CLAUDE.md and enforced here too.
2. **No validation for things that can't go wrong.** Trust internal contracts.
3. **No abstractions for one-off operations.**
