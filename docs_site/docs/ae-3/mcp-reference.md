---
title: "MCP tools reference"
outline: deep
---

# MCP tools reference

The `agentic_executables_mcp` server exposes AE's surface as MCP tools. Fourteen tools ship in 3.0; this page documents each one's purpose, parameters, response envelope, and the most likely error codes you'll see. Schemas come from `agentic_executables_mcp/lib/src/server.dart`.

If you're consuming AE from Claude Code, the [Claude Code plugin](./plugin) auto-wires this server. From any other MCP client, point it at the `agentic_executables_mcp` binary in stdio mode.

## Response envelope

All AE MCP tools return the same envelope shape (omitted from each section to keep things short):

```jsonc
{
  "success": true,
  "data": { /* tool-specific payload */ },
  "error": null
}
```

On failure: `success: false`, `data: null`, and `error: { code: "...", message: "..." }`. Codes are stable identifiers; the table at [Reference](/reference/) (and `docs/error_code_playbook.md` in the repo) is authoritative.

## Hub-aware tools

### `ae_init`

Scan a project for known language manifests and ingest each sub-package as a local artifact. The MCP equivalent of [`ae init`](./cli-reference#ae-init).

| Parameter | Type | Notes |
|---|---|---|
| `root` | string | Project root path (default: cwd). |
| `strict` | bool | Exit non-zero on unhandled subdirectories. |

Common errors: `no_hub`, `unhandled_subdirs`.

### `ae_status`

Project-wide tier-classified gap report. See [Concepts](./) for the four tiers.

| Parameter | Type | Notes |
|---|---|---|
| `root` | string | Project root. |
| `pack` | string | Narrow to one artifact pack (delegates to per-pack verify). |
| `tier` | string | Show only entries at this tier (`1`–`4`). |

Common errors: `no_hub`.

### `ae_sync`

Re-scan source files for artifact packs and report drift (code + intent).

| Parameter | Type | Notes |
|---|---|---|
| `root` | string | Project root. |
| `pack` | string | Sync only the named pack (default: all). |
| `prune` | bool | Remove artifacts whose source path no longer exists (spec §6.2). Pruned pack names appear in `data.pruned`. |

Common errors: `no_hub`.

### `ae_canonical`

Multiplexed canonical operations.

| Parameter | Type | Notes |
|---|---|---|
| `operation` | string (req) | One of: `init`, `scaffold`, `list`, `snapshot`, `diff`, `import`, `distill` (emit), `distill-merge` (merge agent draft), `accept-concept`. |
| `concept` | string | Concept slug. Required for most operations. |
| `title` | string | Human title (for `init`, `scaffold`). |
| `from` | string | Source path (for `import`); from-version (for `diff`). |
| `to` | string | To-version (for `diff`). |
| `as` | string | Concept id under which to import. |
| `pack` | string | Source artifact pack name (for `distill`). |
| `mode` | string | `upsert` or `refine` (for `distill`). |
| `from_artifact` | string \| string[] | Artifact pack name(s) for `scaffold` — one or many. |
| `overwrite` | bool | Replace an existing canonical at `concept` (for `scaffold`). |
| `update` | bool | Reconcile mode for `scaffold` — diffs source symbols against the existing matrix; mutually exclusive with `overwrite`. |
| `renames` | array of {from, to} | Operator-confirmed id renames during `scaffold` `update` (e.g. `[{"from": "ae_cli.old_name", "to": "ae_cli.new_name"}]`). |
| `id` | string | Operator-chosen feature id for `accept-concept`. |
| `from_proposal` | string | Proposal name (from `.last_proposals.json`) for `accept-concept`. |
| `root` | string | Project root. |

Common errors: `no_hub`, `validation_error`, `artifact_not_found` (distill, scaffold), `canonical_exists` (scaffold), `draft_parse_failed` / `draft_schema_mismatch` / `draft_invalid` / `draft_concept_mismatch` (distill-merge), `id_not_in_matrix` (distill-merge), `canonical_not_found` (scaffold update / accept-concept), `proposal_not_found` (accept-concept), `id_collision` (accept-concept).

The `scaffold` operation (spec §6.7) seeds a draft canonical pack heuristically from one or more artifacts' `## Public API` sections — no LLM, no network. Returns `data.feature_count` and `data.authored = "scaffolded"` so callers can distinguish from `hand` (init) or `distilled_from_artifact` (distill).

The `scaffold` operation in `update` mode reconciles an existing canonical against current source symbols (no LLM). `data.mode` is `"update"`; `data.added` and `data.removed` list the diff. With `renames`, `data.renamed` lists `{from, to}` pairs. Vanished symbols are tombstoned (`removed: true` cell) rather than deleted; renamed rows leave a `renamed_to` cell on the tombstone for traceability. Idempotent.

The `distill` operation returns `data.concept`, `data.version`, `data.feature_count` (alias for `data.feature_count_after_merge`, retained for back-compat), `data.feature_count_received`, `data.feature_count_after_merge`, `data.mode`, `data.executor_used`, and `data.proposed_concepts` (only present when non-empty). Each entry in `proposed_concepts` has `name`, `spec`, `invariant`, and optional `rationale`; promote one to a matrix row via `ae canonical accept-concept` (Phase B). Distill never invents feature ids — every emitted row must already be in the matrix; rejected ids surface as a non-zero envelope with `error.code = "id_not_in_matrix"`. When received and post-merge counts diverge, duplicate-id collisions are reported in the envelope's `warnings` array (3.0.2).

The `accept-concept` operation promotes a proposal from `.last_proposals.json` to a stable matrix row at an operator-chosen `id`. Required params: `concept`, `id`, `from_proposal`. Returns `data.concept`, `data.accepted_id`, `data.from_proposal`. Errors `proposal_not_found` if the file is missing or the name is absent, `id_collision` if the id is already in the matrix, `canonical_not_found` if the concept does not exist. The accepted proposal is removed from `.last_proposals.json`; remaining proposals retain the original `produced_at` timestamp so the file keeps reflecting when distill ran.

Sample MCP call (using `operation` as the dispatch key):

```json
{
  "name": "ae_canonical",
  "arguments": {
    "operation": "accept-concept",
    "concept": "ae_cli",
    "id": "ae_cli.json_envelope_shape",
    "from_proposal": "envelope-shape"
  }
}
```

### `ae_artifact`

Multiplexed artifact operations.

| Parameter | Type | Notes |
|---|---|---|
| `operation` | string (req) | One of: `list`, `verify` (`run_tests` bool), `link`, `upgrade-canonical`, `mark-evidence` (`pack`, `feature_id`, `test_command` req; `location`, `notes`, `impl` optional). |
| `pack` | string | Pack name (required for `verify`/`link`/`upgrade-canonical`). |
| `canonical` | string | Canonical reference (e.g. `ecs` or `gltf/core@v2`). |
| `to` | string | Target version (for `upgrade-canonical`). |
| `strict` | bool | Fail on Tier 1+2 (for `verify`). |
| `root` | string | Project root. |

Common errors: `no_hub`, `validation_error`.

### `ae_hub`

Hub management: init, status, pull, push.

| Parameter | Type | Notes |
|---|---|---|
| `operation` | string (req) | One of: `init`, `status`, `pull`, `push`. |
| `path` | string | Hub directory path (for `init`). |
| `project` | bool | Initialize in current project (for `init`). |
| `hub_path` | string | Hub path override (for `status`/`pull`/`push`). |
| `remote` | string | Remote name (default `origin`; for `pull`/`push`). |
| `library_id` | string | Specific library to pull. |
| `type` | string | One of `know`, `use`, `packages` (legacy 2.x partitions; pull/push). |

Common errors: `hub_init_failed`, `hub_not_found`, `hub_status_failed`, `hub_pull_failed`, `hub_push_failed`.

## Registry (carry-over)

### `ae_registry`

| Parameter | Type | Notes |
|---|---|---|
| `operation` | string (req) | One of: `submit_to_registry`, `get_from_registry`, `bootstrap_local_registry`. |
| `library_url` | string | For `submit_to_registry`. |
| `library_id` | string | Library id. |
| `ae_use_files` | string | CSV of AE Use file paths. |
| `action` | string | One of `install`, `uninstall`, `update`, `use`. |
| `ae_use_path` | string | For `bootstrap_local_registry`. |

Common errors: `registry_not_found`, `registry_fetch_failed`, `registry_get_failed`, `registry_submit_failed`, `registry_bootstrap_failed`.

## Definition / instructions / generate (carry-over)

### `ae_definition`

Get the AE framework definition. No parameters.

### `ae_instructions`

Retrieve AE instructions for context (library/project) and action (bootstrap/install/uninstall/update/use). Required: `context_type`, `action`. Optional: `know_name`. Common error: `instructions_failed`.

### `ae_generate`

Generate AE files using `auto|template` engine selection (auto resolves to template inside MCP). Required: `library_id`, `library_root`. Optional: `output_dir`, `engine`, `dry_run`, `know_name`. Common errors: `generation_failed`, `engine_unavailable`, `invalid_generation_output`.

## Verify / evaluate (carry-over, typed payloads)

### `ae_verify`

Verify AE implementation using a typed checklist. Required: `context_type`, `action`. Optional: `files_modified`, `checklist_completed`. Legacy string-encoded JSON payloads are rejected. Common error: `verify_failed`.

### `ae_evaluate`

Evaluate AE compliance. Required: `context_type`, `action`. Optional: `files_created`, `sections_present`, plus boolean flags (`validation_steps_exists`, etc.). Legacy string-encoded JSON payloads are rejected. Common error: `evaluate_failed`.

## Preflight and package tools (spec §13)

### `ae_doctor`

Preflight checks: codex availability, Dart SDK, skill target writability (critical), and registry reachability (critical). MCP equivalent of [`ae doctor`](./cli-reference#ae-doctor).

| Parameter | Type | Notes |
|---|---|---|
| `target` | string (req) | Skill target directory probed for writability (e.g. `~/.codex/skills`). |

The envelope's `data` carries `overall_status` (`pass` / `fail`), an optional `failure_code: doctor_checks_failed`, and a `checks: [...]` array of `{ id, label, status, critical, diagnostic, fix_command }` entries.

### `ae_package`

Resolve / validate Lythe-compatible package instructions (`ae.v3.package.v1`). MCP equivalent of [`ae package`](./cli-reference#ae-package).

| Parameter | Type | Notes |
|---|---|---|
| `operation` | string (req) | `resolve` or `validate`. |
| `package` | string | Package id (required for `resolve`). |
| `target` | string | Runtime target (default `linux`). |
| `format` | string | Output format (default `json`). |
| `package_root` | string | Optional path used to detect the package version from `pubspec.yaml` / `package.json` / `pyproject.toml`. |
| `instructions` | object \| string | For `validate`: a JSON object, an inline JSON string, or a path to a JSON file. |

Common errors: `validation_error`.

## Where to next

- [CLI reference](./cli-reference) — same operations from a shell.
- [Claude Code plugin](./plugin) — slash commands that pre-fill the most common MCP calls.
