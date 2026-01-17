# Agentic Executables - Design FAQ

Design rationale and architectural decisions. Optimized for AI agent understanding.

## Framework Architecture

**Q: Why use MCP (Model Context Protocol) instead of direct API calls or REST endpoints?**

A: MCP provides standardized, agent-friendly interface designed for AI interactions. Enables language-agnostic operations and consistent interface across all agents. Trade-off: Additional abstraction layer (minimal overhead).

**Q: Why exactly 5 core tools instead of more granular or fewer consolidated tools?**

A: Five tools represent distinct operational phases: discovery, guidance, verification, evaluation, registry management. Each serves specific purpose without fragmentation. Trade-off: More tools to learn (mitigated by clear naming).

**Q: Why markdown-based AE files instead of JSON, YAML, or structured formats?**

A: Markdown balances human readability, agent parsing capability, and flexibility. AI agents parse markdown effectively, humans edit easily, supports code blocks naturally. Trade-off: Less strict validation (mitigated by verification tools).

**Q: Why registry-based distribution instead of npm/pypi/pub.dev integration?**

A: Registry keeps AE files separate from package repos, enabling language-agnostic management and retroactive support for existing libraries. Trade-off: Two-step process (install package + fetch AE files).

**Q: Why language-agnostic approach instead of language-specific implementations?**

A: Single framework works across all ecosystems, reducing maintenance and allowing consistent patterns. Trade-off: Less language-specific optimizations (acceptable, handled in AE files).

**Q: Why validation and compliance checks instead of trusting AE file authors?**

A: Ensures framework principles adherence, maintains quality standards, catches mistakes early. Trade-off: Additional workflow step (worthwhile for quality).

**Q: Why strategic guidance tools instead of direct execution tools?**

A: Empowers agents to make context-aware decisions while maintaining human oversight. Avoids security concerns and handles edge cases through agent reasoning. Trade-off: Two-step process (guidance → execution).

**Q: Why context types (library vs project) instead of single unified context?**

A: Library and project contexts have fundamentally different goals. Library authors maintain AE files, developers use them. Trade-off: Requires understanding two contexts (minimal overhead).

**Q: Why GitHub-based registry instead of custom registry service?**

A: GitHub provides version control, PR workflow, community contributions, and raw file access out of the box. Trade-off: Tied to GitHub (acceptable, reliable API).

**Q: Why LOC (Lines of Code) scoring in compliance evaluation?**

A: Encourages concise documentation. Shorter files are easier for agents to process and indicate better structure. Thresholds: <500 PASS, 500-800 WARNING, >800 FAIL. Trade-off: Could penalize complex libraries (mitigated by warnings).

**Q: Why separate verification and evaluation tools instead of combined?**

A: Verification provides checklist-based validation (pass/fail), evaluation provides scoring with recommendations. Different use cases: quick check vs comprehensive assessment. Trade-off: Two tools to learn (clear purposes).

**Q: Why resource-based document loading instead of hardcoded strings?**

A: Allows updating documentation without code changes, supports different layouts, easier maintenance. Trade-off: Requires file system access (acceptable).

## Implementation Details

**Q: Why Dart for the MCP server implementation?**

A: Excellent performance, strong typing, good MCP package support, compiles to native executables. Trade-off: Less common than Python/Node.js (acceptable).

**Q: Why JSON responses instead of structured objects or streaming?**

A: MCP protocol expects JSON. Language-agnostic, human-readable for debugging, standard format. Trade-off: Text-based (larger than binary, acceptable for this use case).
