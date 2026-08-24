class EmbeddedCliResources {
  static const Map<String, String> prompts = {
    'ae_context.md': _aeContext,
    'ae_use.md': _aeUse,
    'ae_bootstrap.md': _aeBootstrap,
  };

  static const String skillTemplate = _skillTemplate;
  static const String skillVersion = '1.1.0';
}

const String _aeContext = r'''# AE Context
## Purpose
- Define the minimal shared contract for creating and executing Agentic Executable (AE) documents.
- Standardize terms, file boundaries, and quality rules across library and project contexts.

## Canonical Terms
- AE: A library treated as an executable artifact managed by instruction files.
- Library context: Maintainer mode for generating and updating AE files.
- Project context: Consumer mode for applying AE files in a codebase.
- Lifecycle stage Installation: Add dependencies and establish baseline setup.
- Lifecycle stage Configuration: Set required options, environment, and runtime settings.
- Lifecycle stage Integration: Wire library APIs into project entry points and flows.
- Lifecycle stage Usage: Apply library capabilities through repeatable task patterns.
- Lifecycle stage Uninstallation: Remove dependencies and reverse integration safely.
- Action `bootstrap`: Create or refresh core AE files for a library.
- Action `install`: Apply installation, configuration, and integration instructions.
- Action `uninstall`: Remove prior integration and installed dependencies.
- Action `update`: Move from current version or state to target version or state.
- Action `use`: Generate or apply frequent-operation usage rules.

## Context-Action Matrix
| Context | Allowed actions | Required docs |
| --- | --- | --- |
| library | bootstrap, update | ae_context.md + ae_bootstrap.md |
| project | install, uninstall, update, use | ae_context.md + ae_use.md |

## Core Principles
1. Agent Empowerment: Write instructions that allow autonomous execution with minimal clarification.
2. Modularity: Separate stages and responsibilities so actions are composable and replaceable.
3. Contextual Awareness: Include enough domain context to choose correct integration points.
4. Reversibility: Define uninstall and rollback paths that restore a stable pre-change state.
5. Validation: Require explicit checkpoints after installation, integration, updates, and removal.
6. Documentation Focus: Optimize for compact machine parsing over narrative explanation.

## File Responsibilities
| File | Primary owner | Responsibility |
| --- | --- | --- |
| ae_context.md | framework maintainer | Define global terms, principles, and constraints. |
| ae_bootstrap.md | library maintainer agent | Generate and update library AE operation files. |
| ae_use.md (core) | project execution agent | Execute install, use, update, and uninstall workflows. |
| ae_install.md | library maintainer agent | Specify install, configuration, integration, and validation steps. |
| ae_uninstall.md | library maintainer agent | Specify reverse operations and removal validation. |
| ae_update.md | library maintainer agent | Specify migration, rollback, and update validation steps. |
| ae_use.md (library output) | library maintainer agent | Specify frequent usage patterns and guardrails. |

## Minimal File Skeletons
- `ae_install.md`: `# Installation` + `## Prerequisites` + `## Installation Steps` + `## Configuration` + `## Integration` + `## Validation`.
- `ae_uninstall.md`: `# Uninstallation` + `## Prerequisites` + `## Removal Steps` + `## Cleanup` + `## Validation`.
- `ae_update.md`: `# Update` + `## Prerequisites` + `## Migration Steps` + `## Rollback` + `## Validation`.
- `ae_use.md` (library output): `# Usage` + `## Prerequisites` + `## Patterns` + `## Validation` + `## Troubleshooting`.

## Quality Constraints
- LOC target: keep each AE file under 500 lines.
- LOC warning: 500-800 lines requires compaction before release.
- LOC fail: over 800 lines blocks acceptance.
- Keep every instruction atomic, imperative, and directly executable.
- Keep templates abstract; use placeholders like `<path>`, `<command>`, and `<version>`.
- Keep required headings stable; do not rename section contracts.

## Authoring Rules
- Use short bullets or ordered steps; avoid long prose paragraphs.
- Use one responsibility per step and one validation outcome per checkpoint.
- Use explicit paths, commands, and expected outputs in template form.
- Ban emojis, themed framing, motivational text, and language-specific examples.
- Preserve filename contracts and tool-facing schemas without modification.
''';

const String _aeUse = r'''# AE Use
## Objective
- Execute `install`, `uninstall`, `update`, and `use` actions deterministically from registry AE files with mandatory validation and concise reporting.

## Inputs
- `context_type`: Must be `project`.
- `action`: One of `install|uninstall|update|use`.
- `library_id`: Registry key in `<language>_<library_name>` format.
- `project_root`: Working path for file and command execution.
- `constraints`: Optional policy limits for versioning, security, or runtime.
- `user_overrides`: Optional explicit deviations approved by the user.

## Action Mapping
| Action | Registry call | Primary file | Lifecycle focus |
| --- | --- | --- | --- |
| install | `get_from_registry(..., action="install")` | `ae_install.md` | Installation, Configuration, Integration |
| uninstall | `get_from_registry(..., action="uninstall")` | `ae_uninstall.md` | Uninstallation |
| update | `get_from_registry(..., action="update")` | `ae_update.md` | Migration, rollback, compatibility |
| use | `get_from_registry(..., action="use")` | `ae_use.md` | Frequent operation patterns |

## Execution Algorithm
1. Parse request into `{action, library_id, project_root, constraints}`.
2. Validate required inputs and reject invalid action-context pairs.
3. Fetch AE file via `manage_ae_registry(operation="get_from_registry", library_id, action)`.
4. Parse required sections from the fetched file and fail fast if structure is incomplete.
5. Build an execution plan that preserves instruction order and validation checkpoints.
6. Apply minimal adaptations only when project structure or tooling requires equivalent mapping.
7. Execute each step sequentially and log command output or file diffs per step.
8. Run all mandatory validation checkpoints for the action before marking success.
9. If any step fails, enter Error Protocol, then retry only the failed scope when safe.
10. Emit Completion Report Format with executed scope, adaptations, validations, and residual risks.

## Adaptation Rules
- Allowed: remap paths to existing project layout while preserving instruction intent.
- Allowed: translate naming conventions (`snake_case` vs `camelCase`) without changing behavior.
- Allowed: swap equivalent package-manager commands (`npm|pnpm|yarn`, `pip|uv`) when semantically identical.
- Allowed: inject project-required wrappers (workspace scripts, task runners) when outputs are unchanged.
- Allowed: parameterize templates with project values (`<path>`, `<module>`, `<version>`).
- Forbidden: skip required steps or validations.
- Forbidden: weaken security controls, remove permission checks, or bypass secrets handling.
- Forbidden: change dependency constraints or migration order without explicit user approval.
- Forbidden: replace documented algorithms with alternative logic.
- Forbidden: invent undocumented cleanup behavior that risks destructive side effects.
- Rule: record every adaptation in the completion report with reason and equivalence statement.

## Validation Protocol
- Preflight checkpoint: verify toolchain, permissions, and required files before execution.
- Step checkpoint: after each major step, confirm expected artifact exists or expected output appears.
- Action checkpoint (`install`): verify dependency presence, integration path, and runtime smoke test.
- Action checkpoint (`uninstall`): verify integration removal, dependency removal, and clean build/test.
- Action checkpoint (`update`): verify target version, migration success, rollback path, and regression smoke test.
- Action checkpoint (`use`): verify usage rule artifacts and at least one successful reference execution.
- Final checkpoint: confirm no mandatory validation was skipped.
- Failure rule: any failed mandatory checkpoint blocks success status.

## Error Protocol
1. Capture error tuple `{step, command_or_edit, message, exit_code, context}`.
2. Classify failure as `precondition`, `execution`, `validation`, or `environment`.
3. Run minimal triage: verify prerequisites, path assumptions, permissions, and version constraints.
4. Apply documented fix if present in AE file; otherwise apply reversible equivalent fix.
5. Re-run only the failed step and directly dependent validations.
6. Escalate to user when failure persists, requires risky changes, or conflicts with constraints.
7. On escalation, include attempted fixes, blocked reason, and exact next decision needed.

## Completion Report Format
- `[ ] Action`: `<install|uninstall|update|use>` on `<library_id>` at `<project_root>`.
- `[ ] Inputs`: constraints and user overrides applied.
- `[ ] Retrieved file`: source identifier and section integrity status.
- `[ ] Executed steps`: ordered list of commands/edits with status.
- `[ ] Adaptations`: each adaptation with equivalence justification.
- `[ ] Validation`: each mandatory checkpoint with pass/fail evidence.
- `[ ] Failures`: unresolved issues or `none`.
- `[ ] Final status`: `success|partial|blocked` with one-line rationale.

## Stop Conditions
- Stop when required inputs are missing and cannot be inferred safely.
- Stop when registry document retrieval fails after retry.
- Stop when mandatory section structure is invalid or incomplete.
- Stop when a step requires destructive or security-sensitive change without approval.
- Stop when repeated retries fail and no reversible mitigation remains.
- Stop when user constraints conflict with AE-required behavior.
''';

const String _aeBootstrap = r'''# AE Bootstrap
## Objective
- Generate and maintain compact library AE files (`ae_install.md`, `ae_uninstall.md`, `ae_update.md`, `ae_use.md`) that are executable, reversible, and validation-complete.

## Inputs
- `context_type`: Must be `library`.
- `action`: `bootstrap` for first generation or `update` for existing AE files.
- `library_id`: Registry key in `<language>_<library_name>` format.
- `library_root`: Path containing source, manifests, tests, and examples.
- `target_version`: Intended release or integration version.
- `current_version`: Existing version baseline for migration diffs.
- `existing_ae_dir`: Existing AE directory when already present.
- `constraints`: Policy limits for security, compatibility, CI, and style.

## Discovery
- Inspect manifests and lockfiles to extract dependency requirements and version constraints.
- Inspect source entry points to map setup paths, config surfaces, and integration seams.
- Inspect runtime resources to map cleanup targets for files, hooks, jobs, and secrets.
- Inspect changelog and API diffs to identify migrations, deprecations, and breaking changes.
- Inspect tests/examples to derive deterministic validation commands and expected outcomes.
- Inspect existing AE files to detect drift, stale versions, missing sections, and redundancy.
- Emit discovery matrix entries as `{artifact, finding, affected_file, validation_hook}`.

## Output Contracts
- Required outputs: `ae_install.md`, `ae_uninstall.md`, `ae_update.md`, `ae_use.md`.
- Optional output: `README.md` in the AE folder for maintainers.
- `ae_install.md` sections: `# Installation`, `## Prerequisites`, `## Installation Steps`, `## Configuration`, `## Integration`, `## Validation`.
- `ae_uninstall.md` sections: `# Uninstallation`, `## Prerequisites`, `## Removal Steps`, `## Cleanup`, `## Validation`.
- `ae_update.md` sections: `# Update`, `## Prerequisites`, `## Version Scope`, `## Migration Steps`, `## Rollback`, `## Validation`.
- `ae_use.md` sections: `# Usage`, `## Prerequisites`, `## Core Patterns`, `## Guardrails`, `## Validation`, `## Troubleshooting`.
- Template rule: use placeholders (`<path>`, `<command>`, `<old_version>`, `<new_version>`) instead of concrete language snippets.
- Install to uninstall reversibility matrix:
| Install artifact or step | Required uninstall reversal |
| --- | --- |
| Add dependency | Remove dependency and verify lockfile cleanup |
| Add configuration key or file | Remove key or file or restore previous value |
| Add imports or initialization wiring | Remove wiring and restore previous entry path |
| Add generated runtime artifact | Remove artifact and dependent references |
| Add permissions or secrets | Revoke permissions and remove secret references |
| Add background process or hook | Disable process or hook and verify stop state |
| Add install validation | Add removal validation proving rollback completeness |

## Generation Algorithm
1. Build required section skeletons for all output files before filling details.
2. Populate `ae_install.md` in lifecycle order: prerequisites, install, config, integration, validation.
3. Derive `ae_uninstall.md` by reversing each install step with one-to-one matrix mapping.
4. Populate `ae_update.md` from version diff data with ordered migrations and rollback triggers.
5. Populate `ae_use.md` with high-frequency patterns, guardrails, and validation checks.
6. Keep instructions template-only and parameterized with placeholders.
7. Add explicit pass criteria for every validation checkpoint.
8. Run quality gates and compress until all constraints pass.

## Update Algorithm
1. Load existing AE files and compare against required output contracts.
2. Preserve valid unchanged sections and rewrite only stale or drifted content.
3. Refresh version-sensitive instructions in install, update, and use files.
4. Recompute uninstall reversals from current install content, not prior uninstall text.
5. Regenerate migration steps and rollback logic from current diff evidence.
6. Revalidate every checkpoint against current project layout and toolchain.
7. Remove duplicated, conflicting, and obsolete instructions.
8. Fail update when any mandatory section or reversal mapping is missing.

## Quality Gates
- Gate 1 Structure: all required files exist with mandatory section headers in required order.
- Gate 2 Reversibility: each install step has a paired uninstall reversal.
- Gate 3 Migration: update file defines scope, ordered migrations, rollback triggers, and rollback steps.
- Gate 4 Validation: every file includes executable checkpoints and explicit expected outcomes.
- Gate 5 Consistency: placeholders, versions, terms, and paths are consistent across files.
- Gate 6 Safety: risky operations include prerequisites, safeguards, and recovery guidance.
- Gate 7 Compactness: instructions are concise, non-redundant, and within line budgets.

## Compression Rules
- Keep one instruction per line and one action per bullet.
- Prefer tables and checklists over repeated prose.
- Remove rationale text unless it changes execution behavior.
- Deduplicate repeated steps by referencing canonical step names.
- Collapse equivalent variants into parameterized placeholders.
- Keep headings stable and short; avoid decorative framing.
- Ban emojis, themed metaphors, and language-specific concrete snippets.

## Done Criteria
- Required output files exist and satisfy Output Contracts.
- Install and uninstall files are fully reversible via matrix mapping.
- Update file covers migration expectations, rollback, and validation.
- Use file covers core patterns, guardrails, and validation.
- Validation checkpoints are complete, executable, and action-specific.
- Quality Gates pass with no blocking failures.
- Output is compact, template-only, and ready for registry publication.
''';

const String _skillTemplate = r'''
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
2. Have an existing spec (Spec Kit / ADR / markdown)? `ae canonical import-spec`.
3. Need a spec FROM code? `ae canonical scaffold --from-artifact <pack>`.
4. Need LLM-quality enrichment? Run the distill delegation loop (below) — you are the executor.
5. Code changed? `ae sync` then `ae artifact verify`.
6. Need framework capabilities? `ae definition`. Context rules? `ae instructions`.
7. Need lifecycle files? `ae generate`; gate with `ae verify` + `ae evaluate`.

## Canonical Workflow (AE 3.x)

```bash
ae hub init --project                                   # create .ae_hub/
ae init                                                 # extract packages -> artifacts (Dart/Rust/Kotlin-Swift)
ae canonical import-spec --from spec.md --concept <id>  # OR: canonical scaffold --from-artifact <pack>
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
ae canonical import-spec --from <file.md> --concept <slug> [--format auto]
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
8. For each Tier-1 row: `ae artifact mark-evidence` with a REAL passing test
   command (relative to the pack's source path), then re-verify with
   `--run-tests`. Never mark evidence for a test that does not exist —
   verify executes the command and catches the lie.

### Distill an external standard from its reference repo (code-agnostic)

1. `ae canonical distill --repo https://github.com/<org>/<repo> --concept <slug>`
2. Do the delegation work on `data.instructions` (step 3 of the loop above)
3. Merge, link to a realization pack, accept cross-cutting concepts.
   Works for any language: unknown ones go through the generic extractor.

### Import an external spec (Spec Kit / ADR)

1. `ae canonical import-spec --from specs/<name>.spec.md --concept <slug> --title "<Title>"`
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
''';
