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
- **ecsly (Dart ECS workspace, 4 packages, ~13k LOC)**: extract → scaffold → distill → link → evidence-enforced verify, zero changes to the target. 176-row canonical distilled with 11 hand-authored invariants and 4 accepted cross-cutting concepts (determinism, low-GC hot path, no-flutter-in-core, three-lane API). After a skill-steward-guided evidence pass mapping every invariant to existing ecsly tests: **project-wide verify is clean — 0 entries**. The initial "11 missing tests" reading was wrong; the tests existed but weren't linked to the claims. The one genuine gap found — no replay-two-worlds bit-identical determinism test — was written and is now the executed evidence for `deterministic_structural_changes`.

## Known gaps / open work

1. Workspace-root ingest misses nested packages (needs second `init --root core_packages`); recursive discovery is a small follow-up.
2. Evidence commands are runner-sensitive (`dart test` vs `flutter test`); auto-detect from manifest at mark-evidence time.
3. Registry corpus still thin (~2 external seeds). Next: distill MCP from its official SDKs as registry pack #3.
4. Embedded skill template sync is manual; add a `just sync-skill` target.
5. Docs→code generation does not exist — deliberate (verification-only positioning).
6. ecsly CI gate (`.github/workflows/ae-verify.yml`) installs AE from git main; pin to a tag once 3.2.0 is released.

## Test state

All packages green: CLI 77 ✓ · core 224 ✓ · MCP 55 ✓. Analyzer clean on new code.
