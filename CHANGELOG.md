# Changelog

All notable changes to this project are documented in this file.

The format is based on [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — 3.2.0

### Changed — BREAKING: AE never calls a model (hard cut, crystallization #2)

- **Removed all distillation executors** (`ClaudeCodeSubagentExecutor`, `CodexExecExecutor`, `ByokLlmExecutor`), the executor ports/service/dispatcher, and the `hub.yaml` `byok:` config block. AE is a pure tool: it **emits delegation instructions** (task JSON `ae.distillation.task.v1` + prompt) for any host agent (Claude Code, pi, Codex CLI, Cursor), then **validates and merges** the agent's returned `ae.canonical.draft.v1` draft. No API keys, no model CLIs spawned, works offline.
- **`ae canonical distill` is now two-phase**: emit (`--pack`) → agent work → merge (`--from-output <file|->`). MCP parity via `ae_canonical` ops `distill` / `distill-merge`. New error codes: `draft_parse_failed`, `draft_schema_mismatch`, `draft_invalid`, `draft_concept_mismatch`; `distillation_failed` retired. `executor_used` is now always `host_agent` on merged drafts.
- **`ae doctor` no longer probes model binaries** — nothing model-related to probe; checks are Dart SDK, skill target writability, registry reachability.
- Follow-up (not in this pass): the v2 `ae generate --engine codex` inference path remains as an explicit opt-in and is slated for the same treatment.

### Added

- **Code-agnostic distillation: `ae canonical distill --repo <git-url>`.** Shallow-clones any public repository, ingests it via the best available extractor, and emits delegation instructions — distillation no longer requires a language-specific extractor. New `GenericHeuristicExtractor` (language-agnostic fallback: hashes text sources across 30+ extensions with a 500-file cap, README excerpt + per-extension summary, license detection) and `RepoCloner` adapter. The extractor registry now falls back to the generic extractor instead of returning null; `ae init`/MCP `init` only ingest directories a _specific_ extractor recognizes (unknown dirs skipped). New error code `repo_clone_failed`. Validated end-to-end on a foreign-language repo (left-pad, JS/TS).
- **Self-dogfood complete**: AE's own three Dart packages distilled into canonicals `ae-core` (172 rows + 5 accepted cross-cutting concepts incl. hexagonal-layering, id-stability, no-model-lock-in), `ae-cli2` (14 rows), `ae-mcp` (2 rows). All Tier-1 findings closed with executed test evidence; project-wide `verify` is clean.
- **Skills updated to the delegation architecture**: `skills/ae-cli/SKILL.md` v1.5.0 (`--repo` code-agnostic path, evidence-enforcement recipes, dogfood-state notes), plugin `/ae-distill` slash command accepts pack or repo URL.
- **`ae artifact mark-evidence` + `verify --run-tests` (evidence enforcement).** `mark-evidence` records test provenance (`evidence_command`, location) on a feature row and promotes `impl: missing`; `verify --run-tests` **executes** recorded commands instead of trusting cells — a failing command becomes a Tier 1 entry (`evidence failed`). New error code `feature_not_found`. Available via CLI, MCP `ae_artifact` op `mark-evidence`.
- **Skills updated to the delegation architecture**: `skills/ae-cli/SKILL.md` v1.4.0 (canonical workflow + distill delegation loop), plugin `/ae-distill` slash command rewritten for emit→work→merge. _(Superseded by v1.5.0 above.)_
- **Pipeline benchmark** at [`benchmarks/pipeline_bench.sh`](benchmarks/pipeline_bench.sh); pivot-validation evaluation note at [`docs/superpowers/notes/2026-08-24-pivot-validation-benchmark.md`](docs/superpowers/notes/2026-08-24-pivot-validation-benchmark.md).
  — deterministically import external spec documents (GitHub Spec Kit specs, ADRs, structured markdown) as canonical feature rows. No LLM, merge-safe (existing rows never overwritten; collisions reported in `skipped_ids`). `speckit` format parses FR-/NFR-/REQ- requirement lines and User Story sections with MUST/SHALL bullets folding into `invariant`; `headings` format maps every ##+ heading to a feature with sentence-level invariant extraction. New error codes: `file_not_found`, `spec_parse_empty`.
- **Seed canonical corpus** at [`canonicals/`](canonicals/): real standards contracts (`auth/oauth2_pkce`, `mcp/server`) generated from source spec docs via `import-spec` and ready to `ae canonical import` into any hub.
- **Multi-language killer demo** at [`examples/multi_language_kv/`](examples/multi_language_kv/run_demo.sh): one kv_store canonical, Dart + Rust realizations, cross-language Tier 1 gaps surfacing in ~10s without an LLM.
- **North Star section** in README reframing the project goal: make any specification verifiable against any implementation.

### Fixed

- **Distillation executor fallback** (spec §6.5 / Iter 1 dogfood Q4): when the highest-priority runnable executor fails twice (e.g. `claude_code` selected but binary broken), the dispatcher now falls through to the next runnable executor instead of failing. Fails only after every runnable executor is exhausted.
- **`ae doctor` probes `claude_available`** symmetrically with `codex_available` (Iter 1 dogfood finding).
- **`accept-concept` id validation order**: malformed `--id` (hyphens, uppercase) now fails fast with `invalid_feature_id` before the proposals file is consulted, instead of crashing with `internal_error` or confusingly reporting `proposal_not_found`. Error code documented.
- **New `safe_file_writer_test.dart`** in CLI: direct unit tests for `SafeFileWriter` consent semantics (add/block/update/check/unchanged) — gap surfaced by the evidence-enforcement loop when mark-evidence pointed at a nonexistent test file.
- **Docs de-staled**: `adapters.md`, `authoring-canonicals.md`, `walkthroughs.md` updated for the delegation architecture; `cli-reference.md` documents `--repo`, the generic extractor, and `invalid_feature_id`.
- **Embedded skill template re-synced** with `skills/ae-cli/SKILL.md` (v1.5.0); `embedded_resources_test` green.
- **Pubspec/envelope versions bumped to 3.2.0** across core/cli/mcp (Iter 1 dogfood finding #7 — binaries no longer report stale 3.0.0).

## [3.1.0] - 2026-04-27

### Added

- **`ae canonical scaffold --from-artifact <pack>... --concept <slug> [--title <t>] [--overwrite]`** — heuristic, no LLM. Parses each artifact's `## Public API` section and emits one stub feature per detected symbol with `spec`/`invariant` placeholders the user fills in (or runs `ae canonical distill` against later for an enrichment pass). Closes spec §6.7 gap. Available via CLI, MCP `ae_canonical` op `scaffold`.
- **`ae sync --prune`** — removes artifact packs whose source path no longer exists. Returns `pruned: [...]` in the envelope alongside drift. Closes spec §6.2 gap. Available via CLI and MCP `ae_sync` `prune` parameter.
- **`ae use {install,uninstall,update} --library-id <id>`** — local-first shim: checks `.ae_hub/artifacts/use/<id>/` first; falls back to `ae registry get` when no local override exists. Closes spec §12 gap.
- **`ae_doctor` MCP tool** — preflight checks the CLI's `ae doctor` runs, surfaced as an MCP tool. Closes spec §13 gap. Doctor logic moved into core (`PreflightDoctor`) so both surfaces share the implementation.
- **`ae_package` MCP tool** — `resolve` and `validate` operations matching the CLI's `ae package` subcommands. Closes spec §13 gap. Package logic moved into core (`AePackageService`).

### Changed

- `DistillationService.distill` now returns `DistillationResult { output, executorId }` instead of just `DistillationOutput`. CLI/MCP envelopes report `executor_used` directly from the result rather than re-running `canRun()` on every executor (Phase 4E quirk).
- `_handlePackageResolve` / `_handlePackageValidate` in CLI are now thin wrappers over `DefaultAePackageService`; the handcrafted version-detection and instructions-validation logic moved into core.

## [3.0.2] - 2026-04-27

### Fixed

- `ae hub init` now always nests the hub under `<resolved>/.ae_hub/` and scaffolds the v3 layout (`canonical/`, `artifacts/{local,external,use}/`) per spec §4.1. `--path X` previously created `know/ packages/ use/ hub.yaml` directly inside `X`, polluting any non-empty target directory. (Iter 0 dogfood bug 1.)
- `ae --help` lists the AE 3.0 dispatchable commands (`init`, `status`, `sync`, `canonical`, `artifact`, `spec export`); they were runnable but invisible at the top level. (Iter 0 dogfood bug 2.)
- `ae canonical distill --help` returns contextual help instead of the generic "No contextual help found" miss path. The `spec` / `spec export` help cases were already wired; help test now asserts the miss path no longer fires for any of them. (Iter 0 dogfood bug 3.)
- `mergeDistillation` now surfaces duplicate-id collisions in the distillation output and emits both `feature_count_received` and `feature_count_after_merge` in the CLI/MCP envelope, with a warnings list when the two diverge. The on-disk matrix.yaml was already self-consistent on dogfood-iter-0; the new instrumentation makes future drift visible. (Iter 0 dogfood bug 4.)
- `mergeDistillation` widens `column_schema` to include any cell keys observed on merged features (first-seen order, type `text`), so `canonical/<concept>/matrix.yaml` is always self-consistent on both first-write and merge paths. Resolves the scaffold-vs-distill mismatch where `[spec, invariant]` schema co-existed with `invocation`/`notes` cells. (Iter 0 dogfood bug 5.)

## [3.0.1] - 2026-04-17

### Added

- `ae spec export` reborn on the v3 schema: emits `spec_index.json` (`spec_export.v3`),
  `canonical_<slug>.json` (`ae.canonical.v3`), and `artifact_<name>.json` (`ae.artifact.v3`)
  per pack in the hub.
- `experiments/ae_rust_contract/` parity-check upgraded to consume the v3 shapes and
  report Tier 1/2 gaps — first non-Dart canonical consumer per spec §9.5.

### Removed (hard cut per spec §9)

- `ae know` command family and the `ae_know` MCP tool; all `know/` hub content, `KnowPack`/`KnowMatrix` models, `FileKnowledgeStore`, `DefaultAeKnowService`, and the `KnowledgeExtractor` port.
- `ae e2e sync-know` (not in the 3.0 CLI surface).
- `--know` option on `ae instructions` and `ae generate` (no longer applicable).

### Notes

- 3.0.0's coexistence promise for `ae know *` is now retired. Run `ae init` to create a fresh 3.0 hub; v2 `.ae_hub/know/` content is safe to delete manually.

## [3.0.0] - 2026-04-17

### Added

- **Canonical packs** as first-class concept descriptions: language-agnostic feature lists with `spec` and `invariant` fields. Stored under `.ae_hub/canonical/<concept>/`.
- **Artifact packs** as language-specific instances: kind (local | external | use), source SHAs, `references_canonical`, materialized matrix with `impl` / `tests` cells. Stored under `.ae_hub/artifacts/<kind>/<name>/`.
- **Heuristic extractors** for Dart (deep), Rust (solid), Kotlin/Swift (best-effort). Detect manifests, hash sources, harvest doc-comments, emit `ArtifactPack` skeletons. No LLM.
- **Distillation executors**: Claude Code subagent, Codex exec, BYOK direct LLM. Pluggable executor selection by host detection. Schema-validated wire format (`ae.distillation.task.v1` in / `ae.canonical.draft.v1` out) with retry-once on failure.
- **Tier-classified verify cockpit** (`ae status`): Tier 1 invariant violations, Tier 2 upstream blockers (sorted by downstream count), Tier 3 partial features, Tier 4 unreferenced canonicals.
- **Drift detection** (both axes): code drift via SHA compare, intent drift via canonical-invariant ↔ artifact-tests=yes check.
- **New CLI commands:** `ae init`, `ae status`, `ae sync`, `ae canonical {init, list, snapshot, diff, import}`, `ae artifact {list, verify, link, upgrade-canonical}`.
- **New MCP tools:** `ae_init`, `ae_status`, `ae_sync`, `ae_canonical`, `ae_artifact`.
- **Hub resolver v3:** project hub → user hub resolution chain for canonicals; project-only for artifacts. Package-hub layer stubbed for 3.x.
- **Claude Code plugin scaffold** at `plugins/claude-code-ae-plugin/`: hook, slash commands (`/ae-status`, `/ae-distill`), distillation skill, MCP auto-wiring.

### Reserved (designed-for, not active in 3.0)

- `HubConfig.canonicalRemotes` field for the future public canonical hub (3.x).
- `resolvePackageHub` stub for auto package-hub discovery (3.x).

### Coexistence

- All AE 2.x `ae know *` commands and the `ae_know` MCP tool continue to work. They will be removed in a future cutover release.

### Known limitations

- The 98 KLOC `cli.dart` monolith is unchanged; structural per-command file split is queued for the cutover release.
- Docs site sectional rewrite is queued for a 3.0.x follow-up. See `docs_site/docs/ae-3-overview.md` for an orientation page.
- `ae canonical distill` is wired in core (Phase 3 + 4A) but not yet surfaced as a CLI/MCP command. The `ae-distill` slash command in the Claude Code plugin documents the manual flow until then.

## [2.0.0] - 2026-03-03

### Added

- New shared package: `agentic_executables_core`
- New CLI-first package: `agentic_executables_cli` (`ae` binary)
- Deterministic template generation engine in core
- Optional Codex execution engine in CLI with `auto|codex|template` mode
- Provider-agnostic inference abstraction for custom non-Codex implementations
- Repo-managed skill template at `skills/ae-cli/SKILL.md`
- CLI commands for `skill install` and `skill update`

### Changed

- Architecture moved to 3-package model: core + CLI + MCP thin adapter
- MCP package moved to v2 contracts and tool names
- CLI is now the primary AE interaction surface

### Removed

- Backward compatibility for old MCP tool contracts

## [1.1.0] - 2025-10-13

- moved registry to separate repository: https://github.com/fluent-meaning-symbiotic/agentic_executables_registry
- `ae_use_registry` folder is now a demo folder

## [1.0.0] - 2025-10-13

### Added

- Initial release.
