# AGENTS.md — agentic_executables

Guidance for AI agents working in this repository.

## North Star

**Make any specification verifiable against any implementation.** Every
decision below serves that: deterministic imports over authoring friction,
tier-classified verification over prose docs, agent-native surfaces over
model lock-in, shareable canonical packs over private notes.


## Project Overview

**Agentic Executables (AE)** — an open framework that turns domain knowledge into
executable lifecycle instructions. Dart monorepo:

- `agentic_executables_core/` — typed business logic, ports, adapters
- `agentic_executables_wire/` — zero-dep wire contracts (verify tiers,
  canonical→meaning-tree export) consumed by agent hosts without embedding AE
- `agentic_executables_cli/` — the `ae` CLI (JSON-first output; `--human` for readable)
- `agentic_executables_mcp/` — MCP v3 adapter
- `docs_site/` — VitePress docs (publishes `/llms.txt`)
- `docs/ae_harness_etl_spec.md` — **URGENT cross-repo contract** (workspace-oracle
  wire: failing tests → intent skeletons, materializer specs as data; ties to
  harness ADR 0022 / PLAN R6) — read before touching `agentic_executables_wire/`
- `skills/ae-cli/` — repo-managed agent skill template (installed via `ae skill install`)

## Commands

```bash
# Tests (run per package)
cd agentic_executables_core && dart test
cd agentic_executables_cli && dart test
cd agentic_executables_mcp && dart test

# Run CLI locally without installing
cd agentic_executables_cli && dart pub get && dart run bin/ae.dart definition

# Full E2E pipeline (hub + know builds + matrix + Rust spec export)
just e2e            # optional: AE_E2E_EXTENDED=1 just e2e
just e2e-reset      # wipe hub / matrix / spec exports

# Docs site
cd docs_site && npm run dev
```

## Conventions

- CLI responses are JSON-first; keep new commands parseable and add `--human`
  variants where useful.
- Error handling follows `docs/error_code_playbook.md` — use existing stable
  error codes; add new ones there when introducing them.
- Architecture changes should be reflected in `docs_site/docs/ae-3-overview.md`
  and the relevant plan docs under `docs/superpowers/plans/`.
- Keep generated artifacts (`.ae_hub/`, `docs/feature_matrix.yaml`,
  `experiments/ae_rust_contract/spec/`) out of hand edits — regenerate via `just`.

## Skill Stewardship Practices

This repo both *contains* skills (`skills/`, `plugins/*/skills/`) and *consumes*
agent skills. When working on or with skills, follow these practices:

### Creating / editing skills in this repo

1. Each skill lives at `<dir>/<skill-name>/SKILL.md`; directory name must match
   the frontmatter `name` exactly (lowercase, hyphen-separated).
2. Frontmatter requires `name` and a specific, actionable `description`
   (this is what agents use to decide to load it).
3. Write instructions imperatively ("Do X", "Run Y") with concrete commands and
   file paths. Keep focused — don't duplicate AGENTS.md content.
4. Supporting files (templates, examples) live beside `SKILL.md` and are
   referenced by relative path.
5. The canonical AE skill template is `skills/ae-cli/SKILL.md`. It carries a
   version marker comment (`<!-- ae-cli-skill-version: X.Y.Z -->`) — bump it
   when changing the template, since `ae skill update` uses explicit upgrades
   (`skill_upgrade_required` error otherwise).

### Consuming external skills

1. Before inventing a workflow, check whether a reusable skill exists
   (`npx skills find <query>`); prefer one strong match over many.
2. Install only after confirming fit and quality (description clarity,
   maintenance signal, examples).
3. Prefer project-local placement (`.agents/skills/`) for repo-specific skills;
   global (`~/.agents/skills/`) only for personal cross-project workflows.

### Skill hygiene

- Don't let skills drift from reality: if a command surface changes in the CLI,
  update `skills/ae-cli/SKILL.md` and related plugin skills in the same change.
- Validate skill instructions by actually running the documented commands.
- Keep skill docs consistent with `README.md` command tables and MCP tool list.
