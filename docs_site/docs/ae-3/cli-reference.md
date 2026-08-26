---
title: "CLI reference"
outline: deep
---

# CLI reference

Every command in the AE 3.0 surface, organized by topic. Synopses come straight from `agentic_executables_cli/lib/src/cli.dart`; if the spec and the code disagree, the code wins (see [Surprises](./roadmap#surprises) on the Roadmap page for the running list).

All commands accept `--human` for readable output (default is JSON envelope) and `-h` / `--help` for command-specific help.

## Commands at a glance

| Command                                                           | Purpose                                                                      |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| [`ae init`](#ae-init)                                             | Heuristic-extract every package in a project into artifacts                  |
| [`ae status`](#ae-status)                                         | Tier-classified gap report                                                   |
| [`ae sync`](#ae-sync)                                             | Re-scan source, write `drift.yaml`                                           |
| [`ae canonical init`](#ae-canonical-init)                         | Stub a new canonical pack with an empty matrix                               |
| [`ae canonical scaffold`](#ae-canonical-scaffold)                 | Heuristic seed from one or more artifacts (no LLM)                           |
| `ae canonical scaffold --update`                                  | Reconcile matrix against current source symbols (no LLM).                    |
| `ae canonical accept-concept`                                     | Promote a distilled `proposed_concept` to a stable matrix row.               |
| [`ae canonical list`](#ae-canonical-list)                         | List canonicals in the resolved hubs                                         |
| [`ae canonical snapshot`](#ae-canonical-snapshot)                 | Freeze a breaking change into `vN/`                                          |
| [`ae canonical diff`](#ae-canonical-diff)                         | Diff two versions of a canonical                                             |
| [`ae canonical import`](#ae-canonical-import)                     | Copy a canonical from a path                                                 |
| [`ae canonical import-spec`](#ae-canonical-import-spec)           | Import any document (roadmap, strategy, ADR, markdown) as canonical rows — no LLM  |
| [`ae canonical distill`](#ae-canonical-distill)                   | Emit delegation instructions / merge the agent's draft (never calls a model) |
| [`ae artifact list`](#ae-artifact-list)                           | List artifacts in the project hub                                            |
| [`ae artifact verify`](#ae-artifact-verify)                       | Tiered verify for one artifact                                               |
| [`ae artifact mark-evidence`](#ae-artifact-mark-evidence)         | Record test-evidence provenance for one feature row                          |
| [`ae artifact link`](#ae-artifact-link)                           | Add a canonical reference; materialize matrix                                |
| [`ae artifact upgrade-canonical`](#ae-artifact-upgrade-canonical) | Move an artifact to a newer canonical version                                |
| [`ae hub init`](#ae-hub-init)                                     | Create `.ae_hub/`                                                            |
| [`ae hub status`](#ae-hub-status)                                 | Hub config and resolution diagnostics                                        |
| [`ae registry`](#ae-registry)                                     | AE Use registry operations (carry-over)                                      |
| [`ae package`](#ae-package)                                       | Package resolve / validate (carry-over)                                      |
| [`ae use`](#ae-use)                                               | Local-first AE Use install / uninstall / update                              |
| [`ae doctor`](#ae-doctor)                                         | Preflight checks                                                             |
| [`ae definition`](#ae-definition)                                 | Emit AE framework definition                                                 |
| [`ae skill`](#ae-skill)                                           | Install / update the AE CLI skill template                                   |
| [`ae spec export`](#ae-spec-export)                               | Emit `spec_export.v3` JSON for the hub                                       |

## Project-level commands

### `ae init`

```bash
ae init [--root <dir>] [--strict]
```

Walks `--root` (default cwd) for known manifests, dispatches each sub-package to a [HeuristicExtractor](./adapters#heuristicextractor), and writes one artifact pack per package under `.ae_hub/artifacts/local/`. The hub must exist at `<root>/.ae_hub`; bootstrap with [`ae hub init`](#ae-hub-init) first if it doesn't. Sub-second per package.

Exit codes: `0` on success, non-zero with `unhandled_subdirs` if `--strict` and any sub-directory had no matching extractor, non-zero with `no_hub` if `.ae_hub/` is missing.

See [Quick start](./quick-start) for a full session.

### `ae status`

```bash
ae status [--root <dir>] [--pack <name>] [--tier <n>]
```

Tier-classified gap report across all artifacts, walking the `requires:` graph for Tier 2 downstream-count sorting. `--pack` narrows to a single artifact (delegates to a single-pack verify). `--tier 1..4` shows only the named tier.

Exit codes: `0` on success. Non-zero envelope on hub-resolution failures.

See [Concepts](./) for the four tiers and [Walkthroughs → Multi-language monorepo](./walkthroughs#multi-language-monorepo) for sample output.

### `ae sync`

```bash
ae sync [--root <dir>] [--pack <name>] [--prune]
```

Re-scans source files for each artifact (or just `--pack`). Updates `meta.yaml.files[].sha256`, writes `drift.yaml` with added / modified / removed files. No LLM. No network.

`--prune` (spec §6.2) removes artifact packs whose `meta.source.path` no longer exists on disk — useful after deleting a sub-package. Pruned pack names are surfaced in the envelope under `pruned: [...]`.

## Canonical commands

### `ae canonical init`

```bash
ae canonical init --concept <slug> --title "<title>" [--root <dir>]
```

Scaffolds `canonical/<concept>/` with `meta.yaml`, `matrix.yaml` (empty `features:`), and `index.md`. You edit by hand. Use `<project>/<concept>` slugs for project-private canonicals; bare slugs for canonicals you'd publish.

### `ae canonical scaffold`

```bash
ae canonical scaffold --concept <slug> --title "<title>"
                      --from-artifact <pack> [--from-artifact <pack2> ...]
                      [--overwrite] [--root <dir>]
```

Heuristic seed (no LLM) of a draft canonical pack from one or more artifact packs (spec §6.7). Parses each artifact's `## Public API` section in `index.md` and emits one feature row per detected symbol with stub `spec`/`invariant` cells the user fills in. The draft is the starting line of the editing pass — run `ae canonical distill` against an artifact later for an LLM-assisted enrichment.

Feature ids are namespaced as `<artifact_pack>.<sanitized_symbol>`: camelCase becomes snake_case, non-id characters collapse to underscores, and the first occurrence wins on collision across artifacts. The pack's `meta.yaml.provenance.authored = scaffolded` distinguishes it from `hand` (init) and `distilled_from_artifact` (distill).

Exit codes: `0` on success, non-zero with `canonical_exists` if a pack already lives at `--concept` and `--overwrite` was not passed, `artifact_not_found` if any `--from-artifact` is unknown.

**`--update` mode (3.2.0).** Reconciles an existing canonical against current source-artifact symbols. Deterministic — no LLM. Adds rows for new symbols (with stub spec/invariant text), marks vanished symbols `removed: true` while preserving their text, and leaves unchanged rows untouched. Idempotent.

Mutually exclusive with `--overwrite`. Requires the canonical to exist (`canonical_not_found` otherwise). The envelope's `data` carries `mode: "update"`, `added: [...]`, `removed: [...]`, `unchanged: <int>`, and (when `--rename` was supplied) `renamed: [{from, to}, ...]`.

Accepted-concept rows (created via `accept-concept`) are preserved across `--update` runs — they are not symbol-derived and do not get tombstoned even when no source symbol matches their id.

```bash
ae canonical scaffold --concept ae_cli --from-artifact agentic_executables_cli --update
```

**`--rename old=new` (3.2.0).** Repeatable. Strict-by-default rename detection — without `--rename`, a renamed source symbol appears as `removed: true` of the old id plus a fresh row at the new id (text is lost). With `--rename`, the row's `spec`/`invariant` text migrates to the new id; a tombstone row at the old id retains `removed: true` plus `renamed_to: <new>` for downstream traceability. Errors `validation_error` if `old` is missing or `new` already exists in the matrix. See [id-stability design Q4](https://github.com/fluent-meaning-symbiotic/agentic_executables/blob/v2/docs/superpowers/specs/2026-04-27-canonical-id-stability-design.md#q4-rename-detection).

```bash
ae canonical scaffold --concept ae_cli --from-artifact agentic_executables_cli --update \
  --rename ae_cli.old_name=ae_cli.new_name
```

### `ae canonical list`

```bash
ae canonical list [--root <dir>]
```

Lists every canonical visible from this project — project hub first, user hub second. Useful when you can't remember whether a canonical lives in `~/.ae_hub/` or here.

### `ae canonical snapshot`

```bash
ae canonical snapshot --concept <slug> [--root <dir>]
```

Freezes the current live canonical into `canonical/<concept>/v<n>/` and bumps `meta.yaml.version`. Run only when you're introducing a breaking change. See [Authoring canonicals → Living vs snapshot](./authoring-canonicals#living-vs-snapshot).

### `ae canonical diff`

```bash
ae canonical diff --concept <slug> --from <ver> --to <ver> [--root <dir>]
```

Shows the diff between two versions (e.g. `--from v1 --to current`). Used during snapshot review and `upgrade-canonical` planning.

### `ae canonical import`

```bash
ae canonical import --from <path> --as <concept-id> [--root <dir>]
```

Copies a canonical directory from `<path>` (e.g. a package's `.ae_hub/canonical/<concept>/`) into the target hub. The 3.0 path for package-shipped canonicals until auto-discovery lands.

### `ae canonical import-spec`

```bash
ae canonical import-spec --from <file.md> --concept <slug> [--title <t>] [--format auto|document|speckit|headings] [--root <dir>]
```

Deterministically parses an external specification document into canonical feature rows. No LLM. This is the on-ramp for specs you already have:

- **`document` format** — any markdown: `##`+ headings become features, concise body text folds into `spec`, and must/shall sentences fold into `invariant`. Works for roadmaps, strategy notes, ADRs, and structured markdown.
- **`speckit` format** — explicit legacy compatibility for GitHub Spec Kit style `FR-1:` / `NFR-2:` requirement lines and `User Story` sections.
- **`auto`** (default) parses any markdown while preserving backward-compatible recognition of legacy Spec Kit shapes.

Merge semantics are safe by construction: existing rows are never overwritten; colliding ids land in `skipped_ids`. Feature ids are assigned as `spec.<slug>` with deterministic `_N` suffixes.

Seed canonicals ready to import live in the repo's [`canonicals/`](https://github.com/fluent-meaning-symbiotic/agentic_executables/tree/main/canonicals) directory (OAuth2 PKCE, MCP server contract).

### `ae canonical distill`

```bash
# Phase 1 (emit): compose the delegation task — no model is called.
ae canonical distill --pack <artifact> --concept <slug> [--mode upsert|refine] [--root <dir>]

# Phase 1 alternative (code-agnostic): distill from any public git repo.
ae canonical distill --repo <git-url> --concept <slug> [--root <dir>]

# Phase 2 (merge): validate + merge the agent's returned draft.
ae canonical distill --concept <slug> --from-output <file.json|-> [--root <dir>]
```

`--repo` makes distillation **code-agnostic**: AE shallow-clones the URL, ingests it via the best available extractor (specific if recognized, otherwise the language-agnostic [generic extractor](./adapters#heuristicextractor)), and emits delegation instructions from the resulting pack. The temp clone is deleted before the command returns; the hashed file list in the artifact pack is the durable record. Error: `repo_clone_failed` when `git clone --depth 1` fails (bad URL, private repo, no network). `--pack` and `--repo` are mutually exclusive.

**AE never calls a model.** Distillation is a two-phase delegation:

1. **Emit** — AE builds a `DistillationTask` from the artifact's real source files plus the canonical seed rows, and returns delegation instructions embedding the task JSON (`ae.distillation.task.v1`). Hand these to any coding agent (Claude Code, pi, Codex CLI, Cursor...).
2. **Merge** — the agent returns an `ae.canonical.draft.v1` JSON; merge it with `--from-output <file>` (or `-` for stdin). AE validates the schema and `concept_id`, enforces id stability (no invented ids), merges into the live canonical, and persists any `proposed_concepts` for [`ae canonical accept-concept`](#ae-canonical-accept-concept).

Envelope `data` keys (emit): `mode: "delegate"`, `concept`, `pack`, `seed_rows`, `instructions`, `next`. Envelope `data` keys (merge): `merged: true`, `concept`, `version`, `feature_count`, `feature_count_received`, `feature_count_after_merge`, `executor_used: "host_agent"`, and `proposed_concepts` when non-empty. Each entry in `proposed_concepts` has `name`, `spec`, `invariant`, and optional `rationale`.

Distill never invents feature ids — every row in a merged draft must already be in the matrix. New symbol-derived features arrive via `ae canonical scaffold` / `--update`; new cross-cutting concepts arrive via `proposed_concepts` and an explicit accept-concept. Rejected ids surface as a non-zero envelope with `error.code = "id_not_in_matrix"`.

Error codes (merge phase): `draft_parse_failed` (invalid JSON), `draft_schema_mismatch` (wrong schema), `draft_invalid` (structural validation), `draft_concept_mismatch` (wrong concept), `id_not_in_matrix`.

### `ae canonical accept-concept`

Promote a proposed cross-cutting concept (from the most recent `distill` run) to a stable matrix row at an operator-chosen id.

Required: `--concept`, `--id` (the new feature id), `--from-proposal` (the proposal's `name` field as it appeared in `proposed_concepts`).

Reads `.ae_hub/canonical/<concept>/.last_proposals.json` (written automatically at distill end, gitignored). Errors:

- `invalid_feature_id` — `--id` is malformed (segments must match `[a-z][a-z0-9_]*`; hyphens, uppercase, and empty segments are rejected). Validated before the proposals file is consulted.
- `proposal_not_found` — no proposals file exists, or `--from-proposal` is not in the file.
- `id_collision` — `--id` already exists in the matrix.
- `canonical_not_found` — the concept does not exist (run `ae canonical scaffold` or `ae canonical init` first).

```bash
ae canonical accept-concept --concept ae_cli \
  --id ae_cli.json_envelope_shape \
  --from-proposal envelope-shape
```

The new row carries `spec` and `invariant` from the proposal verbatim, plus `provenance: accepted_concept` for audit. The accepted proposal is removed from `.last_proposals.json` so subsequent `accept-concept` calls cannot double-promote it (the file's `produced_at` timestamp is preserved across rewrites). See [id-stability design Q5](https://github.com/fluent-meaning-symbiotic/agentic_executables/blob/v2/docs/superpowers/specs/2026-04-27-canonical-id-stability-design.md#q5-proposal-then-accept) for the proposal-then-accept rationale.

## Artifact commands

### `ae artifact list`

```bash
ae artifact list [--root <dir>]
```

Lists artifacts under `.ae_hub/artifacts/{local,external,use}/`.

### `ae artifact verify`

```bash
ae artifact verify --pack <name> [--strict] [--run-tests] [--root <dir>]
```

Tiered gap report for one artifact against its referenced canonicals. With `--strict`, exits non-zero on Tier 1+2 unless accepted in `drift.yaml`.

With `--run-tests`, every referenced-canonical row carrying a recorded `evidence_command` is **executed** (via `bash -c`, 120 s cap, cwd = the pack's source path) instead of trusted: exit 0 confirms the evidence; a failing command becomes a Tier 1 entry (`evidence failed: '<cmd>' exited N`) — the pack is caught lying about its own tests. Rows without recorded commands keep legacy behavior (claimed cells are trusted).

### `ae artifact mark-evidence`

```bash
ae artifact mark-evidence --pack <pack> --feature <id> --test-command <cmd>
                          [--location <path>] [--impl <status>] [--notes <text>]
                          [--root <dir>]
```

Records test evidence for one feature row: sets the cell's test status, stores the executing command as provenance (`evidence_command`), optionally records the test-file `location`, and promotes an `impl: missing` cell to the given status (default `done`). Errors: `feature_not_found` when the id is not in the pack's matrix (link a canonical containing it first).

### `ae artifact link`

```bash
ae artifact link --pack <name> --canonical <ref>[@<version>] [--root <dir>]
```

Adds the canonical to the artifact's `references_canonical:` list. Bare ref (`ecs`) is live; `@v2` locks to a snapshot. After link, run [`ae sync`](#ae-sync) to materialize matrix rows for the new canonical's features.

### `ae artifact upgrade-canonical`

```bash
ae artifact upgrade-canonical --pack <name> --canonical <slug>
                              --to <version> [--root <dir>]
```

Moves an artifact's reference from one canonical version to another. Renames preserved cells by feature ID, adds new rows, surfaces removed/changed invariants in `drift.yaml`.

## Hub commands

### `ae hub init`

```bash
ae hub init [--project] [--path <dir>]
```

Creates `.ae_hub/` with a starter `hub.yaml`. `--project` initializes in the current project root; `--path` specifies an absolute path (e.g. for the user hub `~/.ae_hub`).

### `ae hub status`

```bash
ae hub status [--hub <path>]
```

Prints hub config, resolution chain, and counts of canonicals/artifacts. The diagnostic for "why isn't AE seeing my canonical?".

`ae hub pull` and `ae hub push` are carry-over from 2.x and operate on the legacy `know/`, `use/`, `packages/` partitions; they do not yet understand 3.0 canonical/artifact layout.

## Registry / package / use (carry-over)

### `ae registry`

```bash
ae registry get        --library-id <id> --action install|uninstall|update|use [--out <path>]
ae registry submit     --library-url <url> --library-id <id> --ae-use-files <csv>
ae registry bootstrap-local --ae-use-path <path>
```

Carry-over from AE 2.x. The AE Use registry (install / uninstall / update instructions for libraries) is unchanged in 3.0.

### `ae package`

```bash
ae package resolve  --package <id> [--target <t>] [--format json]
ae package validate --instructions <file|->
```

Carry-over. Resolves a package version from a manifest; validates an instruction file payload. Does not touch the hub.

### `ae use`

```bash
ae use install   --library-id <id> [--root <dir>]
ae use uninstall --library-id <id> [--root <dir>]
ae use update    --library-id <id> [--root <dir>]
```

Local-first shim over [`ae registry get`](#ae-registry) (spec §12). Resolves the project hub via `<root>/.ae_hub`, looks for a matching local override at `<hub>/artifacts/use/<library_id>/<ae_install|ae_uninstall|ae_update>.md`, and falls back to the registry when no local override exists. The envelope reports `source: "local_artifact"` or `source: "registry"` and includes the resolved `path` (file path on disk for local artifacts; registry URL otherwise) and the `content` body.

Exit codes: `0` on success, non-zero with `no_hub` if `<root>/.ae_hub/hub.yaml` is missing, `validation_error` for missing `--library-id`.

## System commands

### `ae doctor`

```bash
ae doctor [--target <skills-dir>]
```

Preflight checks. Returns structured check data; non-zero exit when critical checks fail (`failure_code: doctor_checks_failed`).

### `ae definition`

```bash
ae definition
```

Emits the AE framework definition (used by hosts to discover AE's capabilities).

### `ae skill`

```bash
ae skill install [--target <dir>] [--name <slug>] [--upgrade] [--template-path <path>]
ae skill update  [--target <dir>] [--name <slug>] [--template-path <path>]
```

Installs or updates the `ae-cli` skill template into a host's skills directory.

### `ae spec export`

```bash
ae spec export --out <dir> [--hub <path>] [--root <dir>] [--locale <code>]
```

Emits `spec_export.v3` for the hub: `spec_index.json`, one `canonical_<slug>.json` per canonical, one `artifact_<name>.json` per artifact. Drives the Rust parity-check at `experiments/ae_rust_contract/` — the first non-Dart canonical consumer (per spec §9.5).

**Schema additions (3.2.0).** Feature rows in `spec_index.json` may now include `removed: true` (set by `ae canonical scaffold --update` for symbols that vanished from source) and a `renamed_to: <new_id>` cell (set by `ae canonical scaffold --update --rename`). Both fields are additive — old consumers of `spec_export.v3` ignore them. See [id-stability design Q11](https://github.com/fluent-meaning-symbiotic/agentic_executables/blob/v2/docs/superpowers/specs/2026-04-27-canonical-id-stability-design.md#q11-spec-export-schema-additions).

`ae mcp` (run AE's MCP server in stdio mode) is shipped as the separate `agentic_executables_mcp` binary, not as a subcommand on the `ae` CLI. See [MCP tools reference](./mcp-reference) for the tool surface it exposes.

## Where to next

- [MCP tools reference](./mcp-reference) — the same operations behind ten MCP tools.
- [Walkthroughs](./walkthroughs) — these commands stitched into real flows.
