# AE ⇄ Harness ETL — Workspace-Oracle Wire (spec, URGENT)

Status: proposed → implement (ties to dart_flutter_packages
[ADR 0022](../../storage_problem/dart_flutter_packages/docs/decisions/0022_workspace_oracle_meaning_pipeline.md)
and harness PLAN track R6; 2026-09-02).

## Why AE owns this

AE's North Star: **make any specification verifiable against any
implementation.** The harness's meaning tier currently violates that: its
expectation tables are host-authored per task, so the "specification" is
hand-written and the workspace's own tests never verify anything. AE is the
bidirectional-ETL layer — raw sources → canonical rows, canonical rows →
realizations (to code, from code, from raw docs/standards) — so the
workspace-oracle derivation is AE work, not harness-core work. The harness
consumes the wire shapes (hosts never embed AE — same layering rule as
`problem_wire.dart`).

## What already exists (reused, not rebuilt)

- `agentic_executables_wire/problem_wire.dart` — canonical problem rows
  (`classId`, span, evidence, `source`) + project-guided repair packs
  (ADR 0021 pattern). Diagnostics were the first raw source; failing tests
  are the second.
- `agentic_executables_wire/meaning_tree_export.dart` — canonical pack →
  meaning-tree nodes/edges (deterministic, LLM-free). The ETL-in target is
  this existing export path, extended.
- `verify_wire.dart` — tier-classified gaps (`AeTier`), reused for honest
  `evidence`-tier reporting.

## New wire contract: `test_wire.dart` (workspace-oracle rows)

Raw source: test-framework output (`dart test --machine` first; adapters
per framework, syntax-only per the ADR 0021 layering rule).

```dart
/// One canonical workspace-oracle row — ETL output over failing tests.
class TestRowWire {
  final String classId;      // '<lang>/test_failure' family, e.g. 'dart/test_failure'
  final String suitePath;    // project-relative test file
  final String caseName;     // e.g. 'calc add returns sum'
  final String subjectHint;  // file under test (test→subject link, may be empty)
  final String assertion;    // structured: expected / actual / matcher
  final String message;      // raw message (evidence, never the contract)
  final String source;       // 'dart_test', 'flutter_test', ...
}

/// A derived intent skeleton — the ETL product the host imports as data.
class IntentSkeletonWire {
  final String intent;            // e.g. 'calc.add' or 'game.winner'
  final List<ParamWire> params;   // 'name:type' pairs
  final String returns;
  final List<ExpectationWire> expectations; // DERIVED from rows — never hand-authored
  final String originRow;         // provenance: the TestRowWire(s) it came from
}
```

Rules:

1. **Expectations are derived, never authored.** Every `ExpectationWire`
   cites the failing test rows it was extracted from. A host-authored
   expectation table is a conformance violation of ADR 0022.
2. **Skeletons are AE canonical rows**: same durable-truth/tier rules as
   repair packs; capture-back applies (a resolved skeleton's realization
   becomes a pack entry — the synthesis loop's "capture" mirror of ADR
   0021's repair-pack capture).
3. **Materializer specs are data.** A materializer target (VM-replay vs
   workspace-Dart with imports/types) is declared as data the host
   validates. AE owns "one canonical, many realizations"; the idiomatic
   Dart realization is the first *external* realization — the VM-replay
   program stays the interpreter-parity oracle only.

## ETL directions (all AE, one canonical truth)

| Direction | Source | Canonical form | Consumer |
| --- | --- | --- | --- |
| diagnostics → work | analyzer/linter output | `ProblemRowWire` + repair pack | harness mechanical/meaningful tiers (ADR 0021) |
| **tests → intent skeletons** | failing test suites | `TestRowWire` → `IntentSkeletonWire` | harness R6 ETL-in (NEW, this spec) |
| canonical → meaning tree | canonical packs | `meaning_tree_export` | harness world state (exists) |
| raw docs/standards → specs | docs/llms.txt/standards | know packs → canonical | AE know pipeline; feeds skeletons the same way (docs ARE specs) |
| realization → code | intent skeletons | materializer spec (data) | harness materializer (new target: workspace Dart) |
| code → canonical | source + spans | analyzer round-trip | span edits (P4 projection); capture-back |

## Boundaries

- Wire stays zero-dep; adapters syntax-only; no repair/skeleton semantics
  in adapters (ADR 0021 §2 rule, extended to `test_wire`).
- The model never chooses executables, expectations, or materializer specs
  — it fills bounded slots of host-derived skeletons (propose-as-data only,
  host-validated).
- Free-form text stays out of the code law: text artifacts route to the
  `evidence` tier, never `pass` (ADR 0019 §2 / North Star guardrail).

## Validation gate (DoD for the wire)

- Round-trip tests: `dart test --machine` output → `TestRowWire` →
  `IntentSkeletonWire` → harness meaning profile → materialized Dart →
  `dart test` PASS, LLM-free (scripted actor), zero hand-authored
  expectations.
- Parity: interpreter ⇄ materialized Dart pinned for every new op
  (arithmetic/compare/string, bounded iteration, `call`).

## Edit executables (R7b/R7d — ADR 0023, the next wire contract)

The workspace-oracle wire (above) covers generation. **Editing existing
code** extends the same pack pattern:

- `EditExecutableWire` — a parameterized, project-declared edit executable:
  `{id, kind: rename_symbol|insert_member|replace_member_body|delete_member|move_member, params, scope, verification: [analyze, test]}`.
  Sourced from know packs (standards/docs → AE ETL) and project repair
  packs (ADR 0021 capture loop). `scope: lexical|analyzer` names the
  expansion grade: v1 rename is LEXICAL (refs-frontier, hard-capped,
  ambiguity bounce, analyzer+auto-revert as the safety net — handles plain
  identifiers, private symbols, combinators, doc refs; bounces on
  getter/setter pairs, constructors/file conventions, operators);
  analyzer-grade rename (all Dart declaration kinds, Element-precise) is
  the P4/J3 adapter's job. Named-parameter renames are API-breaking and
  must be flagged, never silent.
- The model picks an executable id + fills bounded slots. It NEVER authors
  patches; the HOST materializes span-anchored patches from the meaning
  tree (file+line per symbol) and verifies mechanically with auto-revert.
- `replace_member_body` compiles an op-chain (the r6 materializer) into the
  body slot — the same meaning→Dart pipeline, one level deeper.
- Cross-file scope comes from the tree's `refs` edges (impact frontier,
  hard-capped) — rename/move executables expand over the frontier
  deterministically.

Wire evolution lives in `agentic_executables_wire` (zero-dep) as soon as
R7b's host materializer fixes the shape; adapters stay syntax-only per the
layering rule.

### Scanner ownership matrix (one scanner per concern)

Duplication guard (2026-09-02): both AE and the harness now extract Dart
declarations (`DartHeuristicExtractor` vs harness `code_etl`). The rule:

| Concern | Owner | Output |
|---|---|---|
| Spec/knowledge side — know packs, standards, canonical truth, verify tiers, public-API + docs artifacts | AE | `HeuristicArtifact`, canonical packs, tier-classified gaps |
| Implementation side — actor world input: symbol graph, spans, refs, test expectations | harness | meaning tree, `IntentSkeletonWire`, spans |
| Diagnostics/test wire shapes | AE (`problem_wire`, `test_wire`) | canonical rows |
| In-loop discovery ray | harness (`locate`) | bounded identifier index |

- Wire shapes are the ONLY shared vocabulary; neither side embeds the
  other (AE stays standalone; the harness cannot require AE).
- CONVERGENCE CHECK: wherever both scan the same package, AE public-API
  extraction and the harness manifest must agree on public declarations —
  disagreement is a gate failure. Two independent grammars agreeing is
  evidence; drifting apart is drift.
- Direction rule: when AE verify (T3/T4) needs implementation facts, it
  CONSUMES the harness manifest — AE never grows a second structural
  scanner to feed verify. New languages implement AE extractors (knowledge)
  AND harness adapters (world-input), each per its own concern.

### Materializer spec fields (per executable, ADR 0023 §2)

An `EditExecutableWire` / materializer spec names its toolchain as data —
the ADR 0019 invented-language mechanism, formalized:

| Field | Dart value | Generic? |
|---|---|---|
| span currency | `source_span` (FileSpan, byte offsets) | yes — any text |
| map format | `source_maps` (generated range → meaning-node id) | yes |
| emitter | `code_builder` + dart_style | NO — per-language field |
| oracle | `dart analyze` + workspace convention | NO — per-language field |

Only the emitter + oracle fields change across languages; the span and map
layers are shared infrastructure. Analyzer/test diagnostics interop with
patch coordinates through the span currency, so failure evidence is
language-shaped but location-shaped identically.

### Distillation ↔ harness planning (delegation protocol, one seam missing)

AE distillation is a DELEGATION protocol: AE emits `ae.distillation.task.v1`
(concept, source artifact, matrix seed rows, few-shots) + instructions; an
external agent returns `ae.canonical.draft.v1`; the operator merges. AE
never calls a model. For the harness this means:

- **The distiller is a squad ROLE** (offline reduction transform, evidence
  tier, own cut composition) — reusable across pi/AFM/hosted backends. Not
  a new protocol; the N5c role machinery exercised for real.
- **Planning chain (three-quarters landed)**: raw doc → AE know/delegated
  distill → canonical matrix → `canonicalToMeaningTree` →
  `planFromMatrix` → Goal+Steps → plan-frontier projection. Missing seam:
  `planFromMatrix` consuming canonical DRAFTS as a planning source + the
  `distiller` role composition in the harness host.
- **Tier honesty**: distilled rows are evidence-tier — plan steps derived
  from prose get `verificationKind: observable/open` with evidence; only
  test/code-derived rows are mechanical. A distilled plan never auto-passes.
- **Cost labeling**: distill tokens are ETL cost (offline transform), never
  counted in the actor's tokens-per-task columns.
- **Scanner convergence**: `DistillationSourceArtifact.structuralSummary`
  for code artifacts in harness-managed workspaces comes from the HARNESS
  manifest (one scanner per concern — see the ownership matrix above).
- **Duplication guard**: the harness tier tests' section-split is a FIXTURE,
  not a distiller. AE owns text reduction; the harness owns graph/world
  input; the canonical-matrix boundary is the only seam.
