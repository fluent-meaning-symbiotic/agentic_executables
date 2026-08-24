# AE local hub E2E log (agentic_executables)

**Last updated:** 2026-03-26  
**Hub:** `.ae_hub/` at repository root (from `ae hub init --project`).  
**CLI:** `dart run agentic_executables_cli/bin/ae.dart` from repo root (`dart pub get` in `agentic_executables_cli` first).

**Product / pipeline notes:** [`../ae_know_extract_implement.md`](../ae_know_extract_implement.md) (extract → implement → what to improve next).

## Schema names (glossary)

| Artifact                                                  | `schema` / purpose                                                                                                                                                              |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`docs/e2e/e2e_know_sources.yaml`](e2e_know_sources.yaml) | **`spec_export.know_sources.v1`** — declarative list of packs for `ae e2e sync-know`.                                                                                           |
| `experiments/ae_rust_contract/spec/spec_index.json`       | **`spec_export.v2`** — index + `export_base` + `definition_yaml` / `definition_md` / `definition_json` (pointer) + optional `matrix_diff` + `e2e_manifest`; per-pack filenames. |
| `experiments/ae_rust_contract/spec/definition.yaml`       | **`ae.definition.v1`** — machine-oriented contexts/actions/tools/principles.                                                                                                    |
| `experiments/ae_rust_contract/spec/definition.md`         | Human-oriented usage guide + message (not required for strict parsers).                                                                                                         |
| `experiments/ae_rust_contract/spec/definition.json`       | **`ae.spec_definition_ptr.v1`** — small pointer to YAML/MD files (replaces monolithic definition JSON).                                                                         |
| `experiments/ae_rust_contract/spec/matrix_diff.json`      | Optional; from `ae spec export --matrix-baseline <prior.yaml>` (same shape as `ae know matrix diff`).                                                                           |
| `docs/feature_matrix.yaml` (from `know matrix scaffold`)  | **`ae.know.matrix.v1`** — feature matrix in the repo.                                                                                                                           |

These are **different** documents; the shared `spec_export` prefix is intentional but easy to confuse—check the file path.

## Rust contract stub (policy)

[`experiments/ae_rust_contract`](../experiments/ae_rust_contract/) is **not** a second CLI and **must not accumulate features**. It only checks that exported JSON/YAML still parses (how far **know packs + `ae spec export`** carry you). **Prefer deleting Rust code over extending it.** E2E truth is in Dart + manifests + exported spec.

## Parity check exit codes

- **`cargo run -p ae_cli_stub -- parity-check`** — **exit 0** when spec is missing (skip) or when checks pass. CI can misread “green” if `just e2e` was never run.
- **`parity-check --strict`** or **`AE_PARITY_REQUIRE_SPEC=1`** — **exit 2** if `definition.json` (pointer), `definition.yaml`, `spec_index.json`, etc. are missing (fail closed).

## Repeatability (DX): reset and run again

- **One-shot local E2E + Rust spec export:** from repo root, install [Just](https://github.com/casey/just), then:
  - `just e2e` — deletes `.ae_hub`, `docs/feature_matrix.yaml`, and `experiments/ae_rust_contract/spec/*` (except `.gitkeep`), then `dart pub get`, `hub init --project`, **`ae e2e sync-know --manifest docs/e2e/e2e_know_sources.yaml`** (declarative packs; URL rows need `AE_E2E_NETWORK=1`), `matrix init` / `scaffold` / `diff`, and **`ae spec export`** into `experiments/ae_rust_contract/spec/` (**spec_export.v2**: `definition.yaml` / `definition.md` / pointer `definition.json`, `know_list`, per-pack portable `know show` + `plan`, `feature_matrix.yaml` copy, **`spec_index.json`** with `export_base`, **`e2e_manifest`**, `locale`; default **`en`** unless `AE_E2E_LOCALE` is set). Run **`ae spec export` from repo root** so local `know_show` paths relativize under `export_base`.
  - Optional **matrix delta artifact:** `AE_E2E_MATRIX_BASELINE=docs/some_baseline.yaml just e2e` (or absolute path) adds **`matrix_diff.json`** vs the current `docs/feature_matrix.yaml` (via `just spec-export`). Commit a baseline file and gate CI on an empty diff when you want matrix-led alignment.
  - `just e2e-reset` — wipe only (no rebuild).
  - `just e2e-export` — export spec only (requires hub + `docs/feature_matrix.yaml`).
  - Optional network smoke pack: `AE_E2E_NETWORK=1 just e2e`.
  - Optional **downstream smoke**: `AE_E2E_EXTENDED=1 just e2e`.
  - Optional **locale for exported plans**: `AE_E2E_LOCALE=ja just e2e` (BCP 47; passed to `spec export` and recorded in `spec_index.json`).
- Migration history (short): [`ae_e2e_just_migration.md`](ae_e2e_just_migration.md).
- **Matrix primary pack:** [`docs/e2e/e2e_know_sources.yaml`](e2e_know_sources.yaml) field **`matrix_primary`** (used by `just e2e` for `know matrix init/scaffold/diff`). Override with **`E2E_MATRIX_PRIMARY`** if needed.
- **`.gitignore`** ignores `.ae_hub/`, generated `docs/feature_matrix.yaml`, and `experiments/ae_rust_contract/target/` so the experiment stays out of git noise; force-add files if you intentionally want them tracked.
- **Rust stub:** `cargo test` / `parity-check` **skip** (exit **0**) when `spec/definition.json` or **`spec/spec_index.json`** is missing (fresh clone). For CI, use **`parity-check --strict`** or **`AE_PARITY_REQUIRE_SPEC=1`** (exit **2** if spec missing). After `just e2e`: `cargo run -p ae_cli_stub -- parity-check` (validates **spec_export.v2**, pointer + YAML definition, portable `know_show` paths, optional **`matrix_diff.json`**, every pack in `spec_index.json`).

## Matrix-led alignment (know → matrix → code)

1. Update know (`ae know build` / `e2e sync-know`) so hub content changes.
2. Refresh or edit **`docs/feature_matrix.yaml`** (`know matrix scaffold` copies from the primary pack’s hub matrix).
3. Compare against a saved baseline: `ae know matrix diff --from-file <baseline> --to-file docs/feature_matrix.yaml`, or rely on **`matrix_diff.json`** from `ae spec export --matrix-baseline <baseline>` (also wired via **`AE_E2E_MATRIX_BASELINE`** in `just spec-export`).
4. Use the diff to drive tests and implementation updates (feature ids and cells are stable keys).

## Parity pyramid (complete parity vs cost)

| Layer  | What it proves                                                                           |
| ------ | ---------------------------------------------------------------------------------------- |
| **L0** | Exported files exist and parse (`ae_cli_stub` default).                                  |
| **L1** | `spec_index` + `know_list` + matrix schema consistent.                                   |
| **L2** | Matrix vs baseline (`matrix_diff.json` or `know matrix diff`) reviewed or empty.         |
| **L3** | Golden command vectors: argv/env → stdout hash (Dart subprocess), checked into the repo. |
| **L4** | Structured CLI surface export (future) shared by Dart and alternate implementations.     |
| **L5** | Property tests on pure parsing/helpers (best for large monorepos).                       |

This repo targets **L0–L2** in Rust; **L3+** is optional for harder codebases.

## Command matrix

| Area              | Command(s)                                                                                     | Result  | Notes                                                                                                    |
| ----------------- | ---------------------------------------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| Core              | `definition`                                                                                   | works   | JSON envelope; non-empty `data.definition`.                                                              |
| Hub               | `hub init --project`, `hub status --hub <abs-path>`                                            | works   | Project hub under `.ae_hub`.                                                                             |
| Hub               | `hub pull` / `hub push`                                                                        | not run | No remote configured; treat as **out of scope** for this pass.                                           |
| Know              | `know build --url file:///...`, `know build --path <file>`                                     | works   | `file://` reads via `PassthroughExtractor`; `--path` uses local source.                                  |
| Know              | `know list`, `know show`, `know diff`, `know migrate --dry-run`                                | works   |                                                                                                          |
| Know              | `know plan --name <pack>`                                                                      | works   | After `matrix init`, plan includes matrix + index. Optional `--locale` / `--language` adds front matter. |
| E2E               | `e2e sync-know --manifest docs/e2e/e2e_know_sources.yaml`                                      | works   | Declarative `know build`; `network: true` rows need `AE_E2E_NETWORK=1`.                                  |
| E2E               | `spec export --out <dir> --hub … --matrix … [--matrix-baseline …] [--manifest …]`              | works   | **spec_export.v2** + portable paths; optional `matrix_diff.json`.                                        |
| Know              | `know matrix init`, `matrix scaffold`, `matrix diff`                                           | works   | Pass `--hub` on the `matrix` subcommand when needed.                                                     |
| Know              | `know build --url https://...`                                                                 | works   | Smoke: Flutter `llms.txt` (network).                                                                     |
| Instructions      | `instructions --context library --action bootstrap [--know <name>]`                            | works   | Resolves project `.ae_hub` by walking up from cwd (`FileHubResolver`).                                   |
| Generate          | `generate --engine template --dry-run [--know <name>]`                                         | works   | Same hub resolution as instructions.                                                                     |
| Registry          | `registry get --library-id dart_mcp --action install --check`                                  | partial | Completes with `registry_not_found` (library not published). Not a hang when using a valid check.        |
| Registry          | `registry bootstrap-local --ae-use-path ...`                                                   | works   | Instructional payload for local registry layout.                                                         |
| Package           | `package resolve` / `package validate --instructions <file>`                                   | works   | Validate needs full v3 shape including `profile` (use resolve output file).                              |
| Verify / Evaluate | `verify --input docs/e2e/ae_e2e_verify.json`, `evaluate --input docs/e2e/ae_e2e_evaluate.json` | works   | Fixtures align with `docs/error_code_playbook.md` contracts.                                             |
| Doctor            | `doctor`                                                                                       | works   | Registry URL reachable in this environment.                                                              |
| Skill             | `skill install --target /tmp/...`                                                              | works   | Non-destructive temp target.                                                                             |
| MCP               | `ae_know` / `ae_hub`                                                                           | not run | Optional parity; CLI exercised above.                                                                    |

## Self-ingestion packs (sharded)

| Pack name                   | Source                                         | ~tokens (`token_estimate`) |
| --------------------------- | ---------------------------------------------- | -------------------------- |
| `ae_docs_know_design`       | `docs/ae_know_design.md` (`path:` in manifest) | 2617                       |
| `ae_docs_error_codes`       | `docs/error_code_playbook.md`                  | 1791                       |
| `ae_docs_site_know_index`   | `docs_site/docs/know/index.md`                 | 2394                       |
| `ae_pkg_cli_readme`         | `agentic_executables_cli/README.md`            | 705                        |
| `ae_pkg_mcp_readme`         | `agentic_executables_mcp/README.md`            | 407                        |
| `ae_url_smoke_flutter_llms` | `https://docs.flutter.dev/llms.txt`            | 4198                       |

Primary pack for matrix/plan: **`ae_docs_know_design`**. Repo-level matrix file: **`docs/feature_matrix.yaml`** (from `know matrix scaffold`).

## Limits (honest)

- **Scale:** Largest smoke pack (`ae_url_smoke_flutter_llms`) ~4.2k token estimate; sharding keeps individual `know show` payloads manageable.
- **Single `--know`:** `instructions` and `generate` accept one pack name; large repos still need multiple scripted invocations or a future **bundle / default pack set** in `hub.yaml`.
- **Registry:** `registry get` fails fast for unknown ids; publishing is a separate workflow.
- **Rust:** Contract-only serde checks; do not grow the Rust crate—see [`experiments/ae_rust_contract/README.md`](../experiments/ae_rust_contract/README.md).

## Large-codebase workflow (patterns validated)

- **Shard by concern:** separate `know build` names (`ae_pkg_*`, `ae_docs_*`) so agents pick 2–3 relevant packs.
- **Stable prefixes:** predictable names for scripts and docs.
- **Repo-level matrix:** `matrix scaffold` → edit `docs/feature_matrix.yaml` for cross-cutting status without one mega-pack.
- **Friction logged for product follow-up:** multi-pack selection for `--know`, optional `know build --path <dir>` shard mode, MCP one-call multi-pack attach.

## Contributor smoke question

_Can a new contributor pick 2–3 `--know` names and get enough context without reading the whole hub?_  
**Yes**, using e.g. `ae_docs_know_design` + `ae_pkg_cli_readme` + `ae_docs_error_codes`, assuming the hub is populated as above.
