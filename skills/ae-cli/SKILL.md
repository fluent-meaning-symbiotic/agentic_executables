---
name: ae-cli
description: Execute Agentic Executables (AE) workflows through the `ae` CLI — AE 3.x canonical/artifact verification (spec import, code extraction from any language, distill delegation), plus framework definition, lifecycle file generation, quality gates, registry operations, and skill install/update. Use when working with AE hubs, canonical or artifact packs, knowledge packs, or ae_* commands.
---

<!-- ae-cli-skill-version: 1.5.0 -->

# ae-cli

Use this skill to execute Agentic Executables workflows through the `ae` CLI.

## Why Use This Skill

- Fast and consistent AE operations for both library and project contexts.
- JSON-first command responses that agents can parse reliably (`data.meta.timing_ms` on every envelope).
- Makes specs verifiable against code: one canonical contract, many language realizations, tiered gap reports.
- AE never calls a model — when model work is needed, AE emits instructions and THIS agent does the work, then hands back JSON.

## Quick Decision Flow

1. Setting up a project hub? `ae hub init --project`, then `ae init`.
2. Have an existing document (roadmap / strategy / ADR / markdown)? `ae canonical import-spec`.
3. Need a spec FROM code? `ae canonical scaffold --from-artifact <pack>`.
4. Need LLM-quality enrichment? Run the distill delegation loop (below) — you are the executor.
5. Code changed? `ae sync` then `ae artifact verify`.
6. Need framework capabilities? `ae definition`. Context rules? `ae instructions`.
7. Need lifecycle files? `ae generate`; gate with `ae verify` + `ae evaluate`.

## Canonical Workflow (AE 3.x)

```bash
ae hub init --project                                   # create .ae_hub/
ae init                                                 # extract packages -> artifacts (Dart/Rust/Kotlin-Swift)
ae canonical import-spec --from vision.md --concept <id> --format document  # OR: canonical scaffold --from-artifact <pack>
ae artifact link --pack <pack> --canonical <id>         # attach realization to contract
ae artifact verify --pack <pack>                        # tiered gaps: T1 invariant violations, T2 blockers
ae status                                               # project-wide cockpit
```

### Distillation Delegation Loop (you ARE the executor)

1. Emit: `ae canonical distill --pack <pack> --concept <concept>` — returns
   `data.instructions` embedding the task JSON (`ae.distillation.task.v1`).
   For any public git repo (any language): `ae canonical distill --repo <url>
--concept <concept>` — clones, ingests via the best extractor (generic
   fallback for unknown languages), emits, cleans up.
2. Do the work: read the listed source files, enrich each seed row's
   `spec`/`invariant`. NEVER invent row ids. Cross-cutting ideas go to
   `proposed_concepts`.
3. Return ONLY a JSON object matching `ae.canonical.draft.v1` (single
   ```json fenced block if the host requires wrapping).

   ```
4. Merge: save the JSON, run
   `ae canonical distill --concept <concept> --from-output draft.json`.
5. Promote proposals: `ae canonical accept-concept --concept <c> --id
<snake_case.id> --from-proposal <name>` — id segments are lowercase
   snake_case only (hyphens rejected with `invalid_feature_id`).

## Command Cheatsheet

```bash
# --- AE 3.x: canonical / artifact ---
ae hub init --project
ae init [--strict]
ae status [--tier N]
ae sync [--prune]
ae canonical init --concept <slug> --title <text>
ae canonical import-spec --from <file.md> --concept <slug> [--format auto|document]
ae canonical scaffold --concept <slug> --title <t> --from-artifact <pack>
ae canonical scaffold --update --concept <slug>
ae canonical list
ae canonical distill --pack <pack> --concept <slug>            # emit
ae canonical distill --repo <git-url> --concept <slug>         # emit, code-agnostic (any language)
ae canonical distill --concept <slug> --from-output <file|->   # merge
ae canonical accept-concept --concept <slug> --id <new.id> --from-proposal <name>
ae canonical snapshot --concept <slug>
ae canonical diff --concept <slug> --from v1 --to current
ae canonical import --from <dir> --as <slug>
ae artifact list
ae artifact link --pack <name> --canonical <ref[@vN]>
ae artifact verify --pack <name> [--strict] [--run-tests]
ae artifact mark-evidence --pack <name> --feature <id> --test-command <cmd> [--location <path>] [--impl <status>] [--notes <text>]
ae artifact upgrade-canonical --pack <name> --canonical <id> --to vN
ae spec export --out <dir>

# --- Lifecycle / registry (v2 carry-over) ---
ae definition
ae instructions --context library --action bootstrap
ae generate --library-id <id> --library-root <path> --engine auto
ae verify --input <verify.json|->
ae evaluate --input <evaluate.json|->
ae registry get --library-id <id> --action <install|uninstall|update|use>
ae skill install
```

## Action Recipes

### Verify a repo against its own extracted contract

1. `ae hub init --project && ae init`
2. `ae canonical scaffold --concept <pkg> --title "<Title>" --from-artifact <pack>`
3. `ae canonical distill --pack <pack> --concept <pkg>` — take `data.instructions`
4. Enrich rows per ID STABILITY RULES; return `ae.canonical.draft.v1` JSON only
5. `ae canonical distill --concept <pkg> --from-output <draft.json>`
6. `ae artifact link --pack <pack> --canonical <concept>`
7. `ae artifact verify --pack <pack>` — close Tier 1/2 findings
8. For each Tier-1 row: **first search the existing test suite for coverage
   of the claim** (test filenames, symbol names, behavior keywords). Tier-1
   means "claim not linked to evidence", NEVER "behavior untested". Link
   what exists via `ae artifact mark-evidence` with a REAL passing test
   command (relative to the pack's source path), then re-verify with
   `--run-tests`. Only write a NEW test when you have confirmed no existing
   test covers the claim. Never mark evidence for a test that does not
   exist — verify executes the command and catches the lie.

### Distill an external standard from its reference repo (code-agnostic)

1. `ae canonical distill --repo https://github.com/<org>/<repo> --concept <slug>`
2. Do the delegation work on `data.instructions` (step 3 of the loop above)
3. Merge, link to a realization pack, accept cross-cutting concepts.
   Works for any language: unknown ones go through the generic extractor.

### Import an external document

1. `ae canonical import-spec --from docs/vision.md --concept <slug> --title "<Title>" --format document`
2. `ae artifact link --pack <pack> --canonical <slug>`
3. Record evidence via `ae artifact mark-evidence` (not hand-edited YAML)
4. `ae artifact verify --pack <pack> --run-tests`

### Library Bootstrap (v2 lifecycle)

1. `ae instructions --context library --action bootstrap`
2. `ae generate --library-id <id> --library-root <path> --engine auto`
3. `ae verify --input <verify.json>` then `ae evaluate --input <evaluate.json>`
4. Optional publish prep: `ae registry submit ...`

### Project Install / Update / Uninstall / Use

Follow `ae instructions --context project --action <install|update|uninstall|use>`;
optionally fetch steps via `ae registry get`; execute the generated
`ae_install.md` / `ae_update.md` / `ae_uninstall.md` / `ae_use.md` steps;
re-run verify/evaluate where applicable.

## Operational Notes

- Parse envelopes, not prose: `success`, `data`, `error.code`, `warnings`, `meta.timing_ms`.
- Error codes are documented in `docs/error_code_playbook.md`; surface them verbatim.
  Notable: `repo_clone_failed` (bad/private URL), `invalid_feature_id` (hyphens in id),
  `id_not_in_matrix` (draft invented an id — never do this).
- `--engine template` forces deterministic generation; `auto` may opt into inference.
- Treat `verify` as structural quality gate and `evaluate` as scoring gate.
- Evidence commands run via `bash -c` with cwd = the pack's source path; keep them
  relative to that path and non-interactive.
- This repo dogfoods itself: `.ae_hub/canonical/` holds ae-core, ae-cli2, and ae-mcp
  distilled from the Dart packages, all Tier-1 clean. When changing core APIs, run
  `ae sync && ae artifact verify --run-tests` and update the canonicals in the same change.
