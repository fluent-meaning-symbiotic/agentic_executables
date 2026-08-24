# Documentation Index

Organized reference for repository documentation. For the published docs site, see `docs_site/`.

## Architecture & Design

| Document                                                       | Purpose                                              |
| -------------------------------------------------------------- | ---------------------------------------------------- |
| [`architecture_diagram.md`](architecture_diagram.md)           | System architecture diagram                          |
| [`ae_know_design.md`](ae_know_design.md)                       | Know pipeline design (extraction → hub → generation) |
| [`ae_know_roadmap.md`](ae_know_roadmap.md)                     | Know implementation roadmap                          |
| [`ae_know_extract_implement.md`](ae_know_extract_implement.md) | Extract → implement loop and improvement backlog     |
| [`error_code_playbook.md`](error_code_playbook.md)             | Stable error codes and recovery guidance             |

## Guides

| Document                                                                   | Purpose                                   |
| -------------------------------------------------------------------------- | ----------------------------------------- |
| [`guides/inference_provider_guide.md`](guides/inference_provider_guide.md) | Provider-agnostic inference configuration |
| [`guides/lythe_real_registry_ae.md`](guides/lythe_real_registry_ae.md)     | Real-world registry walkthrough           |

## E2E (local pipeline)

| Document                                                       | Purpose                                                                                                    |
| -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| [`e2e/ae_e2e_log.md`](e2e/ae_e2e_log.md)                       | Authoritative E2E log: schema glossary, Rust contract policy, command matrix                               |
| [`e2e/ae_e2e_just_migration.md`](e2e/ae_e2e_just_migration.md) | Migration note for the `just`-based E2E                                                                    |
| [`e2e/e2e_know_sources.yaml`](e2e/e2e_know_sources.yaml)       | Declarative know-pack manifest (`spec_export.know_sources.v1`) — consumed by `just e2e` via repo-root path |
| [`e2e/ae_e2e_verify.json`](e2e/ae_e2e_verify.json)             | Verify fixture used by `AE_E2E_EXTENDED=1 just e2e`                                                        |
| [`e2e/ae_e2e_evaluate.json`](e2e/ae_e2e_evaluate.json)         | Evaluate fixture used by `AE_E2E_EXTENDED=1 just e2e`                                                      |

> Note: `docs/e2e/e2e_know_sources.yaml` is referenced by path from `justfile`
> recipes; if you move it, update `justfile` accordingly.

## Plans, Notes, Specs

Long-form working documents live under [`superpowers/`](superpowers/):

- `superpowers/plans/` — detailed implementation plans (TDD-style)
- `superpowers/specs/` — design specs
- `superpowers/notes/` — session notes and dogfood findings

## Images

- `fun_image.png`, `prompts_to_use.png`, `workflow_developer.png`, `workflow_lib_author.png` — README and docs-site assets
