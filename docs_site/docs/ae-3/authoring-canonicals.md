---
title: "Authoring canonicals"
outline: deep
---

# Authoring canonicals

A canonical pack is the score, not the performance. It's a language-agnostic, token-efficient cognitive map of one load-bearing concept — `ecs`, `render_pipeline`, `gltf/core`, `physics_step`. The matrix-of-features is the contract; the prose `index.md` is the orientation. Everything in this page exists to keep canonicals small, attributed, and useful for both humans and the agent that consumes them.

If you haven't read [Concepts](./) yet, do that first. The four crystallizations explain why this layer is separate from artifacts in the first place.

## Granularity — small or split

The granularity rule is hard. **10–50 features per canonical, ~2–4k tokens total.** If you're past 50 features, you're conflating ideas; split. A well-shaped canonical fits in an agent's working context next to actual code without crowding it out.

The pattern that holds up in practice is sibling decomposition. glTF is the canonical example:

```text
canonical/
  gltf/
    core/                 # the base format
    extensions/
      khr_materials_clearcoat/
      khr_lights_punctual/
      khr_gaussian_splatting/
```

Each sibling is its own pack with its own `meta.yaml`, `matrix.yaml`, `index.md`. Artifacts pick which siblings they implement via `references_canonical:`.

The same shape works for project-private concepts. An ECSly-style engine might decompose as `ecsly/render_pipeline`, `ecsly/physics_step`, `ecsly/schedule`, etc. — each one a focused canonical, all referenced from the relevant artifacts.

## Attribution — first-class

Canonicals carry attribution. License is required (default suggestion CC-BY-4.0). `sources` is required. `authors` is encouraged. The future public canonical hub (see [Roadmap](./roadmap)) will block publish on missing license.

A real `meta.yaml` for a hand-authored canonical:

```yaml
schema: ae.canonical.meta.v1
concept: ecs
version: 1
title: "Entity-Component-System (canonical)"
license:
  spdx: "CC-BY-4.0"
  url: "https://creativecommons.org/licenses/by/4.0/"
authors:
  - name: "Anton Malofeev"
    role: original_author # original_author | contributor | maintainer
sources:
  - kind: paper # paper | website | code | book | spec
    title: "Data-Oriented Design Book"
    url: "https://www.dataorienteddesign.com/dodbook/"
  - kind: code
    title: "Bevy ECS"
    url: "https://github.com/bevyengine/bevy"
provenance:
  authored: hand # hand | distilled_from_artifact | imported_from_public_hub
  authored_at: "2026-04-17"
  distilled_from: null
```

`provenance.authored` records how the pack came into being. Hand-authored canonicals have `authored: hand`. A canonical produced by `ae canonical distill` records `authored: distilled_from_artifact` and the source. Imports from a future public hub will record `imported_from_public_hub`.

## The matrix — the contract

`matrix.yaml` is where the actual features live. The canonical declares the column schema (what cells will look like in artifacts that reference it) and lists features with `id`, `spec`, and `invariant`. **Cells live in artifacts, not in the canonical.** The canonical only declares the shape.

```yaml
schema: ae.canonical_matrix.v1
concept: ecs
version: 1
column_schema:
  - { id: spec, type: text }
  - { id: invariant, type: text }
  - { id: test_recipe, type: text } # how to verify the invariant; optional
features:
  - id: entity.create # stable id; namespaced; never reused
    spec: "An entity is created with a unique, opaque handle."
    invariant: "Handles are non-reusable within a session."
  - id: system.tick
    spec: "Systems run in declared order each tick."
    invariant: "Tick is monotonically increasing."
```

Two things matter about feature IDs:

1. **They're stable.** Once a feature ID is published in a canonical, it doesn't get reused for a different concept. Artifact matrices reference these IDs; reusing one breaks the world.
2. **They're namespaced when project-private.** Use `<project>/<feature>` (e.g. `ecsly/render.scene_extract`) for canonicals that belong to one project. Bare names (`entity.create`) are reserved for canonicals you'd publish.

`invariant` is the test-able promise. If a feature has an invariant and the artifact's matrix doesn't have a `tests: yes` cell with a recipe, that's a Tier 1 violation in `ae status`. See [Walkthroughs → Multi-language monorepo](./walkthroughs#multi-language-monorepo) for what that looks like in a real status output.

## The prose — `index.md`, ~600 words

`canonical/<concept>/index.md` is the condensed prose model. Object model. Lifecycle. Hard rules. Decomposition pointers to sibling canonicals. **Not** a full reference — that's what the docs site or paper you cite in `sources:` is for. The features in `matrix.yaml` are the contract; `index.md` is the cover letter.

Aim for ~600 words. If you're approaching 1500, you're either writing real documentation (don't) or you should split the concept (do).

## Living vs snapshot

Canonical packs are **living documents** by default. The directory `canonical/<concept>/` (no version suffix) is the live current major. Edit it in place to:

- Add a new feature row
- Clarify a `spec` or `invariant`
- Add a column to `column_schema`
- Add an example

You **snapshot** only when you break consumers. Breaking changes are: removing a feature, renaming a feature ID, strengthening an invariant beyond what conformant implementations satisfy, changing the column schema in a non-additive way.

```bash
ae canonical snapshot --concept ecs --migration-doc
```

This freezes the pre-break state to `canonical/ecs/v1/` (whatever the current major was), bumps `meta.yaml.version`, and opens an editor to write `canonical/ecs/v1/migration_to_v2.md`. Artifacts locked to the old major (`references_canonical: ecs@v1`) keep resolving to the snapshot. Live references (`references_canonical: ecs`) re-materialize against the new major next time `ae sync` runs.

## The scaffold workflow

Authoring a canonical from a blank file is fine for small concepts you understand cold. For bigger ones, seed from existing artifacts:

```bash
# 1. Heuristic seed (no LLM, sub-second). Reads each artifact's
#    `## Public API` section in index.md and emits one feature row
#    per detected symbol with stub spec/invariant cells you fill in.
ae canonical scaffold --concept ecsly/render_pipeline \
                      --title "Render pipeline (ecsly)" \
                      --from-artifact dart_render3d \
                      --from-artifact dart_render3d_passes

# 2. Edit canonical/ecsly/render_pipeline/matrix.yaml by hand.
#    Or: enrich with an LLM round-trip via canonical distill.
ae canonical distill --pack dart_render3d --concept ecsly/render_pipeline --mode refine

# 3. Review the draft, tighten specs and invariants.

# 4. Link the artifact(s) you want to track against this canonical.
ae artifact link --pack dart_render3d --canonical ecsly/render_pipeline
```

`ae canonical scaffold` (spec §6.7) is the make-or-break solo-dev entry point: pure-heuristic, no network, no LLM, no host-agent dependency. Feature ids are namespaced as `<artifact_pack>.<sanitized_symbol>` (camelCase becomes snake_case). Re-running on the same concept errors with `canonical_exists` unless you pass `--overwrite`.

`ae canonical distill` emits a delegation task (task JSON + instructions) that **you** — or any coding agent — execute against the real source, then merges the returned `ae.canonical.draft.v1` draft after schema and id-stability validation. The output is always a draft for human review; AE never silently accepts a generated canonical. For sources in any language, emit from a public repo with `--repo <url>` (generic extractor fallback).

If you'd rather start from a blank file (small concepts you know cold), `ae canonical init --concept <slug> --title <text>` writes only the meta/index/empty-matrix scaffolding and leaves the matrix authoring entirely to you.

## Where to next

- [Adapters](./adapters) — the delegation boundary and extractor families.
- [CLI reference](./cli-reference) — every `ae canonical *` flag.
- [Walkthroughs](./walkthroughs) — see canonical authoring inside three real scenarios.
