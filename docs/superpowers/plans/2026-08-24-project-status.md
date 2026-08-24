# Project Status — 2026-08-24

Snapshot of where AE stands after the August 2026 restart sprint.

## Shipped (this cycle, unreleased → 3.2.0)

| Capability                                                                 | State                                |
| -------------------------------------------------------------------------- | ------------------------------------ |
| Delegation architecture (AE never calls a model)                           | ✅ shipped; executor family hard-cut |
| Spec importers (`import-spec`, speckit/headings)                           | ✅ shipped                           |
| Evidence enforcement (`mark-evidence` + `verify --run-tests`)              | ✅ shipped                           |
| Code-agnostic distillation (`distill --repo <url>`, generic extractor)     | ✅ shipped                           |
| Seed canonical corpus (`canonicals/`: oauth2_pkce, mcp/server)             | ✅ shipped                           |
| Multi-language demo (`examples/multi_language_kv/`)                        | ✅ shipped                           |
| Skill v1.5.0 + plugin updated for new architecture                         | ✅ shipped                           |
| Docs de-staled (adapters, authoring, walkthroughs, cli-reference, roadmap) | ✅ shipped                           |

## Self-dogfood (the tool verifies its own repo)

- Canonicals: `ae-core` (172 rows + 5 accepted concepts), `ae-cli2` (14 + 2), `ae-mcp` (2).
- Project-wide `ae artifact verify`: **0 entries** — every declared invariant has executed passing evidence.
- New coverage forced by the loop: `safe_file_writer_test.dart` (SafeFileWriter had zero direct tests).

## External validation

- **left-pad (JS/TS)**: full pipeline via `--repo` on a language with no extractor. Gate check passed.
- **ecsly (Dart ECS workspace, 4 packages, ~13k LOC)**: extract → scaffold → distill → link → evidence-enforced verify, zero changes to the target. 176-row canonical distilled with 11 hand-authored invariants and 4 accepted cross-cutting concepts (determinism, low-GC hot path, no-flutter-in-core, three-lane API). After a skill-steward-guided evidence pass mapping every invariant to existing ecsly tests: **project-wide verify is clean — 0 entries**. The initial "11 missing tests" reading was wrong; the tests existed but weren't linked to the claims. Only genuine gap found: no replay-two-worlds bit-identical determinism test (evidence currently points at related command-queue + extraction-determinism tests).

## Known gaps / open work

1. ecsly: one genuine test gap — a replay-two-worlds bit-identical determinism test (command-queue + extraction-determinism tests cover parts, not the full claim).
2. Workspace-root ingest misses nested packages (needs second `init --root core_packages`); recursive discovery is a small follow-up.
3. Evidence commands are runner-sensitive (`dart test` vs `flutter test`); auto-detect from manifest at mark-evidence time.
4. Registry corpus still thin (~2 external seeds). Next: distill MCP from its official SDKs as registry pack #3.
5. Embedded skill template sync is manual; add a `just sync-skill` target.
6. Docs→code generation does not exist — deliberate (verification-only positioning).

## Test state

All packages green: CLI 77 ✓ · core 224 ✓ · MCP 55 ✓. Analyzer clean on new code.
