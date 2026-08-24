---
title: "Adapters"
outline: deep
---

# Adapters

AE 3.0 is ports-and-adapters all the way down. Three independent adapter families do the work; everything else is composition. Each axis is independently extensible — adding a new language extractor doesn't touch sources or distillation, and vice versa. This page is the developer-facing entry point that the spec earmarked for `docs/extending.md`.

If you want to know what AE 3.0 ships out of the box vs. what's roadmapped, this is the page. If you want to write a new adapter for, say, JS/TS or Python, the interfaces below are the contract.

## KnowledgeSource — how raw content gets in

The first family handles "where does the content come from?" — a local directory, a URL, a PDF, a git clone. It's the carry-over from AE 2.x, lightly extended for 3.0.

```dart
abstract interface class KnowledgeSource {
  bool canHandle(KnowSourceSpec spec);
  Future<RawContent> fetch(KnowSourceSpec spec);
}
```

3.0 adapters:

- **`passthrough_source`** — local filesystem path; no transformation.
- **`url_html_source`** — fetch a URL, strip to readable HTML.
- **`pdf_source`** — extract text from a PDF.
- **`git_clone_source`** — shallow clone a git URL into a temp directory and treat as local.

These feed both `HeuristicExtractor` (see below; it expects a local directory) and the canonical-import path. Adding a new source — say, a Notion page — means writing one class that implements the interface and registering it in the dispatcher.

## HeuristicExtractor — language-aware structural parse, no LLM

The second family is new in 3.0 and is the reason `ae init` is sub-second. A heuristic extractor takes a directory, parses manifests, walks public symbols, harvests doc-comments, hashes files, and emits a `HeuristicArtifact` skeleton.

```dart
abstract interface class HeuristicExtractor {
  String get languageId;                    // "dart" | "rust" | "kotlin_swift"
  bool canHandle(Directory sourceDir);
  Future<HeuristicArtifact> extract(Directory sourceDir);
}
```

3.0 adapters:

- **`DartHeuristicExtractor`** — deep. Parses `pubspec.yaml` workspaces, walks recursive sub-packages, detects barrel files, parses library directives, enumerates public symbols, harvests dartdoc comments, flags bridge packages (presence of `dart:ffi` / method-channel imports).
- **`RustHeuristicExtractor`** — solid. Reads `Cargo.toml` workspace members, enumerates `pub` items, is feature-flag aware.
- **`KotlinSwiftHeuristicExtractor`** — best-effort. Parses `Package.swift` and `build.gradle.kts` to identify the package; lists Kotlin/Swift class files. No deep semantic parse on day one.
- **`GenericHeuristicExtractor`** — language-agnostic fallback (new in 3.2). Handles any directory: hashes text source files across 30+ extensions (500-file cap, vendor/build dirs ignored), builds an index from the README excerpt plus per-extension file counts, detects common licenses. This is what makes distillation **code-agnostic** — the delegation path needs no language-specific parse because the host agent reads whatever the structural summary points at.

The registry (`HeuristicExtractorRegistry.findFor`) dispatches to the first specific extractor whose `canHandle` matches and falls back to the generic extractor when none do — ingestion never hard-fails on an unknown language. Callers that must distinguish (e.g. `ae init`, which only ingests recognized packages) check `languageId != 'generic'`.

Related adapter: **`RepoCloner`** — shallow-clones a public git URL into a temp directory for code-agnostic distillation (`ae canonical distill --repo <url>`); cleans up on failure.

A `HeuristicArtifact` produces:

- `meta.yaml` skeleton — source path, file hashes, language, scanned timestamp.
- `index.md` — package title, README excerpt, parsed exports/public API, dependency list.
- Empty `matrix.yaml` (`features: []`). Rows are added when a canonical is linked.

JS/TS, Python, and Go extractors remain roadmapped as _accelerators_ (see [Roadmap → 3.2/3.x](./roadmap#three-two-three-x)) — with the generic fallback they are no longer a capability gate: unknown languages distill today via the delegation path, just with less pre-digested context. A specific extractor, when written, improves the structural summary and sync fidelity.

## Distillation delegation — AE emits, the agent works, AE validates

The third family is the deliberate boundary between AE and any LLM — and it is a **hard boundary**: AE never owns a model and never calls one. There are no executor adapters, no API keys in `hub.yaml`, no model CLIs spawned by AE.

Instead, distillation is a **two-phase delegation**:

1. **Emit** — AE builds a `DistillationTask` (`ae.distillation.task.v1`) from the artifact's real source files plus the canonical seed rows, wraps it in delegation instructions, and returns both to the caller. The operator hands these to whatever coding agent they use (Claude Code, pi, Codex CLI, Cursor — AE is harness-agnostic by construction).
2. **Merge** — the agent returns an `ae.canonical.draft.v1` JSON. AE validates the schema and `concept_id`, enforces id stability (no invented ids — see the id-stability design), merges into the live canonical, and persists `proposed_concepts` for `ae canonical accept-concept`.

The former executor adapters (`claude_code` subagent, `codex exec`, BYOK direct-LLM) were removed in 3.2.0: they made AE a model _caller_, which broke crystallization #2 ("AE composes with the agent rather than competing with it"). Delegation keeps AE a pure tool: deterministic, offline, keyless, and identical on every harness.

See [CLI reference → ae canonical distill](./cli-reference#ae-canonical-distill) for the user-facing flags.

## Storage — split from the 2.x knowledge store

A quieter but real fourth family. The 2.x `file_know_store` is split into:

- **`FileCanonicalStore`** — read/write `canonical/<concept>/`. Knows about snapshot directories.
- **`FileArtifactStore`** — read/write `artifacts/<kind>/<pack>/`. Handles incremental file-hash updates.

These aren't user-facing in 3.0; they exist to make alternate backends (memory store for tests, future Dgraph if it ever becomes worth it — see [Roadmap → Post-3.x](./roadmap#post-3-x)) drop-in replaceable.

## Hub resolver

`HubResolver` walks the project / user / package / remote chain documented in [Hub layout → Resolution order](./hub-layout#resolution-order). 3.0 implements project + user; package and remote are stubbed in the resolver but inert.

## Services

Above the adapters, services are the orchestrators:

- **`CanonicalService`** — init, list, snapshot, diff, import, distill merge.
- **`ArtifactService`** — ingest (calls heuristic extractor), sync (incremental re-scan), verify, link, upgrade-canonical, materialize.
- **`DriftService`** — code drift (file-hash diff vs `meta.yaml`); intent drift (canonical invariants without tests).
- **`DefaultDistillDelegationService`** — build the emission (task + instructions). Merge-side validation lives in `CanonicalService.mergeDistillationDetailed`.
- **`HubService`** — config, status, resolution.

Each service is a small surface, separately testable, and lands in its own file under `agentic_executables_core/lib/src/services/`. Read the source if you want the precise contract — it's small enough to hold in one head.

## Where to next

- [Authoring canonicals](./authoring-canonicals) — how distillation delegation is used end-to-end.
- [CLI reference](./cli-reference) — every command and the adapter it triggers.
- [Roadmap](./roadmap) — which adapters are planned for 3.x.
