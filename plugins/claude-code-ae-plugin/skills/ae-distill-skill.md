---
name: ae-distill-skill
description: AE distillation wire contract. Use when you receive AE delegation instructions embedding a DistillationTask (ae.distillation.task.v1) and must return an ae.canonical.draft.v1 JSON for merge via 'ae canonical distill --from-output'. Applies to any source language — tasks emitted via `--repo <url>` use the generic extractor and the same contract.
---

# AE Distillation Contract

When you receive a `DistillationTask` (schema: `ae.distillation.task.v1`), return a `DistillationOutput` (schema: `ae.canonical.draft.v1`). Return ONLY the JSON object — no prose. If the host insists on a wrapper, place the JSON in a single ```json fenced code block.

## Input shape (DistillationTask)

```jsonc
{
  "task": "distill_pack",
  "schema_in": "ae.distillation.task.v1",
  "schema_out": "ae.canonical.draft.v1",
  "concept_id": "ecsly/render_pipeline",
  "concept_version": 1,
  "source_artifact": {
    "name": "dart_ecs_render3d_core",
    "language": "dart",
    "files": ["lib/src/passes/basic.dart", "lib/src/scene.dart"],
    "structural_summary": "<from the artifact's existing index.md>",
  },
  "matrix_seed_rows": [/* canonical rows already present, optional */],
  "examples": [/* few-shot from prior accepted distillations, optional */],
}
```

## Output shape (DistillationOutput)

```jsonc
{
  "schema": "ae.canonical.draft.v1",
  "concept_id": "ecsly/render_pipeline",
  "concept_version": 1,
  "index_md": "...condensed concept doc, ~600 words...",
  "matrix": {
    "schema": "ae.canonical_matrix.v1",
    "concept": "ecsly/render_pipeline",
    "version": 1,
    "column_schema": [
      { "id": "spec", "type": "text" },
      { "id": "invariant", "type": "text" },
    ],
    "features": [
      { "id": "render.scene_extract", "spec": "...", "invariant": "..." },
      { "id": "render.draw_pass", "spec": "...", "invariant": "..." },
    ],
  },
  "patterns_md": "...optional impl-specific idioms...",
}
```

## Distillation guidance

- **Granularity rule:** 10–50 features per pack; ~2–4k tokens total. If the artifact is bigger, decompose into sibling concepts (e.g. `gltf/core` + `gltf/extensions/khr_lights_punctual`) and emit ONE concept per task. Tell the caller about the decomposition in `index_md`.
- **Feature ids** are stable, dot-namespaced, lowercase + underscores: `entity.create`, `lights.spot.cone`, `swarm.flocking_movement`.
- **Spec field** = what the feature does in plain language.
- **Invariant field** (when present) = a property that MUST hold; it drives `ae artifact verify`'s Tier 1 check (the artifact must have a `tests: yes` row for that feature, or it surfaces as an invariant violation).
- **Index.md** = condensed prose model: object model, lifecycle, hard rules, decomposition pointers. ~600 words. Not exhaustive documentation.
- **Patterns.md** (optional) = impl-specific idioms; only emit when the artifact reveals a clear pattern worth recording.
