---
name: ae-distill
description: Run one AE distillation delegation loop — emit the task, enrich canonical rows from real source code, merge the draft back. Works on artifact packs or any public git repo (code-agnostic). Usage — /ae-distill <pack-or-repo-url> <concept>
---

You will complete an AE distillation for artifact pack `<pack>` (or a public
repo URL — detect `https://` and pass it via `--repo`) into canonical
`<concept>` (arguments). AE never calls a model — **you** are the model worker
in this loop.

Steps:

1. Emit the task:
   - Pack source: `ae canonical distill --pack <pack> --concept <concept>`
   - Repo source (any language): `ae canonical distill --repo <url> --concept <concept>`
     Parse the JSON envelope; keep `data.instructions` and note `data.seed_rows`.
     For repo sources, the files live in the ingested artifact pack named in
     `data.pack` — read them relative to that pack's `meta.yaml` source path.
2. Read every source file listed in the task's `source_artifact.files`, plus
   the current canonical matrix at `.ae_hub/canonical/<concept>/matrix.yaml`.
3. Enrich each seeded row with a precise `spec` and a testable `invariant`.
   HARD RULES (enforced by AE's validator on merge):
   - Never invent or rename row ids — only ids present in `matrix_seed_rows`.
   - Cross-cutting findings that match no id go to top-level `proposed_concepts`
     (`name`, `spec`, `invariant`, `rationale`), not new feature rows.
4. Return/save ONLY a JSON object matching `ae.canonical.draft.v1`
   (see the `ae-distill-skill` for the exact shape). No prose outside one
   optional ```json fenced block.
5. Merge it back:
   `ae canonical distill --concept <concept> --from-output <draft.json>`
   On success, report `feature_count_after_merge`. If rejected
   (`id_not_in_matrix`, `draft_schema_mismatch`, ...), fix the draft per the
   error message and re-merge.

The operator then promotes accepted proposals:
`ae canonical accept-concept --concept <concept> --id <new.id> --from-proposal <name>`.
