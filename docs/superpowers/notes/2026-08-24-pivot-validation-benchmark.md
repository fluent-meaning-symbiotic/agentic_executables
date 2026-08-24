# Pivot Validation — Benchmark & Honest Evaluation

> Date: 2026-08-24 (session). Scope: prove the initial pivot on AE itself,
> benchmark what is truly possible, name the weakest points, decide changes.

## The claim under test

Initial goal: docs that project bidirectionally to code and back,
harness-agnostic, living parts of the app, so people work at the
pattern/standard level. The falsification test: **run the entire pipeline
on agentic_executables itself** — if it needs hand-prepared specs or
fixtures, agents already read code fine and the idea is dead.

## Verdict: the loop closes, end to end, on the repo itself

Executed today, zero hand-preparation of spec or fixtures:

1. `ae init` ingested 4 real packages (3 Dart + the Rust contract crate via
   symlink — which exposed and fixed a real scanner bug).
2. `canonical scaffold` derived **14 feature rows from the Dart CLI's own
   public API** — the spec originates from code, not from a human.
3. `canonical distill` (emit) produced delegation instructions; the host
   agent (Claude, in-session) enriched rows by reading `safe_file_writer.dart`
   and returned an `ae.canonical.draft.v1` draft.
4. Merge (`--from-output`) enforced id-stability (3 ⊆ 14 rows), preserved all
   pre-existing ids, persisted a `proposed_concept`.
5. Those 3 new invariants immediately fired as **Tier-1 violations on the
   linked core and mcp packs** — declared invariants with no test evidence
   anywhere. The docs now catch the code.

## Benchmark (fresh hub → full loop, `meta.timing_ms`, M-series MacBook)

| Phase | ms | Notes |
|---|---:|---|
| ingest: ae init (4 packages) | 150 | manifest detection + SHA hashing |
| scaffold: canonical from CLI API | 52 | regex-level public-API parse |
| emit: distill delegation task | 51 | task + instructions |
| — instructions payload | 6.6 KB | includes full id-stability prompt |
| merge: validate + merge draft | 88 | schema + id validator + upsert |
| link (per pack) | 65–134 | matrix materialization |
| verify per pack | 59–230 | tier classification |
| status cockpit | 142 | project-wide |
| sync drift rescan | 255 | incremental SHA compare |
| spec export v3 | 171 | deterministic JSON |
| import-spec (5-feature ADR) | 114 | deterministic parse |

**AE-side cost of the whole tool pipeline: ~1 second.** The dominant cost of
a distillation cycle is the host agent reading files and writing the draft —
exactly where it should be. AE adds negligible overhead to any harness.

Coverage: 14 canonical rows vs 7 `lib/src` source files in the CLI package —
the extractor captures every top-level unit plus nested resources.

## What this proves about the pivot

1. **Code→docs projection: proven.** Extraction → scaffold → delegation →
   validated merge runs on a real 60+ KLOC monorepo in ~1s of tool time.
2. **Harness-agnosticism: strengthened today.** Removing the executors means
   AE now works identically on any agent that can read a file and return
   JSON. No keys, no model CLIs, offline-capable.
3. **Standards-level work: partially proven.** Two real canonical seeds
   (oauth2_pkce, mcp/server) import cleanly; cross-implementation linking
   (Dart CLI ↔ core ↔ MCP facade ↔ Rust crate) surfaces gaps per pack.
4. **Docs→code direction: NOT proven.** There is no generation from canonical
   to code. Today's "bidirectional" is extract/verify one way plus
   human/agent-driven edits the other way.

## Weakest points, ranked

1. **Evidence marking is manual YAML editing.** Verify is only as honest as
   the `impl/tests` cells, and nothing writes them except a human or a script
   (the KV demo patches YAML with Python). This is the biggest integrity hole:
   nothing prevents marking `tests: yes` without tests existing.
2. **No test-evidence grounding.** Tier 1 says "no test verifies this" but AE
   never looks at actual test results. Invariants fire forever until someone
   hand-edits cells — noise risk ("alert fatigue") on large packs.
3. **Scaffold granularity is file/symbol-level.** 14 rows for a CLI whose real
   behavioral surface is ~20 commands with dozens of flags. Symbol rows ≠ the
   promises users care about. Import-spec fills this gap only when a written
   spec exists.
4. **Single-repo scope.** Cross-pack requires-graph works within one hub; the
   "standards adoption" story still leans on the registry repo being manually
   populated (2 seed canonicals).
5. **Rust realization is thin.** The parity crate consumes exported shapes;
   it does not yet exercise the delegation loop from a second language, so
   multi-language claims rest mostly on the Dart side plus fixtures.

## What should change next (priority order)

1. **Evidence commands**: `ae artifact mark-evidence --pack P --feature F
   --tests <path>` writing provenance (test file, command, timestamp), and a
   `--evidence-from <test-report.json>` bulk mode. Kills the YAML-editing
   hole; makes Tier 1 trustworthy.
2. **Wire verify to real test runs**: optional `verify --run-tests` executing
   mapped test commands per invariant and recording pass/fail as evidence.
   This converts AE from bookkeeping to enforcement — the killer feature the
   pivot needs.
3. **Command-surface extractor upgrade**: derive features from the CLI parser
   itself (commands/flags as rows) instead of Dart symbols, closing the
   granularity gap for tool-type packages.
4. **Canonical corpus growth**: 10–20 seeded standards via import-spec in the
   registry repo; each is a marketing unit AND a dogfood test of import-spec.
5. **Docs→code spike**: pick one narrow generator (e.g., generate a Rust
   parity check skeleton from a canonical) to make the reverse direction real
   before claiming it.

## Bottom line

The pivot survives its own falsification test on the hardest available
subject (the project itself): the loop code→contract→agent-enrichment→
verified-gaps closes with AE overhead ≈ nil, and the architecture is now
strictly tool-only. The weakest link is evidence integrity, not extraction
or delegation. Fix evidence (items 1–2) and AE graduates from honest
bookkeeping to enforcement — the point where "docs that catch code lying"
becomes "code cannot lie."
