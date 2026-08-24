---
title: "Walkthroughs"
outline: deep
---

# Walkthroughs

Three scenarios, each end-to-end. Read [Concepts](./) and [Quick start](./quick-start) first; this page assumes you know what canonicals and artifacts are. Output below is realistic but synthetic — the shapes are real, the names are illustrative.

## Multi-language monorepo

A 250-KLOC engine: a Dart core, a Rust physics module, a couple of Kotlin/Swift bridges, and a fistful of plugins. The interesting bit isn't `ae init` — it's `ae status` reading the `requires:` graph across languages.

```bash
$ cd ~/code/ecsly
$ ae init
ae 3.0 init: scanning ecsly
  + dart    core_packages/ecs                 → artifacts/local/dart_ecs
  + dart    core_packages/render3d            → artifacts/local/dart_render3d
  + rust    core_packages/physics             → artifacts/local/rust_physics
  + kotlin  bridges/android                   → artifacts/local/kotlin_android_bridge
  + swift   bridges/ios                       → artifacts/local/swift_ios_bridge
  + dart    plugins/audio                     → artifacts/local/dart_audio
  ... (8 more)
ingested 14 artifacts in 1.1s
```

Author the canonicals that matter (`ecsly/render_pipeline`, `ecsly/physics_step`, `ecsly/schedule`), link them from the relevant artifacts, then declare cross-artifact dependencies in each artifact's `matrix.yaml`:

```yaml
# .ae_hub/artifacts/local/dart_render3d/matrix.yaml
requires:
  - artifact: rust_physics
    canonical: ecsly/physics_step
    features: [physics.step, physics.spatial_index]
  - artifact: dart_ecs
    canonical: ecsly/schedule
    features: [schedule.fixed_tick, schedule.frame_pacing]
```

Now `ae status` walks the `requires:` graph and reports tier-2 upstream blockers sorted by downstream-count:

```text
$ ae status
AE 3.0 — ecsly

Tier 1  INVARIANT VIOLATIONS              4
  ecsly/physics_step/physics.step      "Step is deterministic for fixed dt"
                                        → no test asserts this   (rust_physics)
  ...

Tier 2  UPSTREAM BLOCKERS                 2  (sorted by downstream count)
  rust_physics                          ecsly/physics_step/physics.spatial_index
                                        impl=missing — blocks 4 downstream artifacts
                                        (dart_render3d, dart_ai, dart_gameplay, swift_ios_bridge)

Tier 3  PARTIAL FEATURES                  6
Tier 4  UNREFERENCED CANONICALS           1
  ecsly/render_pipeline                 not linked from any artifact yet

14 artifacts, 3 canonicals.
```

Tier 2 is the working signal in a multi-language repo. Land that one missing feature in `rust_physics` and four downstream artifacts move forward.

## External standard with KHR extensions

glTF + KHR extensions is the canonical example of sibling-canonical decomposition (see [Authoring canonicals → Granularity](./authoring-canonicals#granularity-small-or-split)). One canonical for the base format; one per extension you care about.

```bash
ae canonical init --concept gltf/core --title "glTF 2.0 (core)"
ae canonical init --concept gltf/extensions/khr_materials_clearcoat \
                  --title "KHR_materials_clearcoat"
ae canonical init --concept gltf/extensions/khr_lights_punctual \
                  --title "KHR_lights_punctual"
```

Each canonical lists its own ~10–30 features in `matrix.yaml`. Now the artifact that loads glTF in your engine declares which of these it implements:

```yaml
# .ae_hub/artifacts/local/dart_gltf_loader/meta.yaml
references_canonical:
  - gltf/core
  - gltf/extensions/khr_materials_clearcoat
  - gltf/extensions/khr_lights_punctual@v1 # locked to v1 snapshot
```

The first two are **live** references — they re-resolve against whatever `canonical/gltf/core/` currently holds at `ae sync` time. The third is **locked** — it always resolves to `canonical/gltf/extensions/khr_lights_punctual/v1/`, the frozen snapshot. Use locks when an extension you depend on is moving and you don't want to chase it. See [Hub layout](./hub-layout) for the snapshot directory shape.

`ae artifact verify --pack dart_gltf_loader` runs a tiered verify against all three referenced canonicals. In CI, add `--strict` so Tier 1 + Tier 2 gaps fail the build (unless explicitly accepted via `drift.yaml`).

## A new-extension flow (hypothetical 2026)

Imagine the Khronos group ratifies `KHR_gaussian_splatting` next quarter. Adding it to your project is a five-step loop, no migration tools needed.

```bash
# 1. Author the canonical for the new extension.
$ ae canonical init --concept gltf/extensions/khr_gaussian_splatting \
                    --title "KHR_gaussian_splatting"
created canonical/gltf/extensions/khr_gaussian_splatting/

# Edit matrix.yaml by hand (or distill from a reference impl):
$ ae canonical distill --pack rust_gltf_kgs_ref \
                       --concept gltf/extensions/khr_gaussian_splatting \
                       --mode upsert
distillation: emitted delegation task (ae.distillation.task.v1)
distillation: validated against ae.canonical.draft.v1
merged 11 features into canonical/gltf/extensions/khr_gaussian_splatting/
```

```bash
# 2. Link the canonical from your loader artifact.
$ ae artifact link --pack dart_gltf_loader \
                   --canonical gltf/extensions/khr_gaussian_splatting
linked dart_gltf_loader → gltf/extensions/khr_gaussian_splatting (live)
materialized 11 matrix rows (impl: missing)
```

```bash
# 3. Status now flags the new extension as Tier 4 → 3 as you implement.
$ ae status --pack dart_gltf_loader
dart_gltf_loader

Tier 1  0
Tier 2  0
Tier 3  11   gltf/extensions/khr_gaussian_splatting/* (impl=missing)
Tier 4  0
```

```bash
# 4. As you write code, ae sync keeps file hashes honest and surfaces drift.
$ ae sync --pack dart_gltf_loader
re-scanned 12 files
drift: 8 files modified since last extract
drift: 1 file added
drift.yaml updated
```

```bash
# 5. When tests assert the invariants and impl cells flip to "done",
#    the tier counts decrement automatically.
$ ae status --pack dart_gltf_loader
dart_gltf_loader

Tier 1  0
Tier 2  0
Tier 3  3    (8 features now done; 3 still partial)
Tier 4  0
```

That's the loop — for one extension, for a whole engine, or for an external standard with thirty siblings. AE doesn't ship a "migrate to new extension" command because it doesn't need one: canonical-init, link, sync, fill in cells.

## Where to next

- [CLI reference](./cli-reference) — every flag used above.
- [MCP tools reference](./mcp-reference) — same operations from inside an agent.
- [Claude Code plugin](./plugin) — slash commands that wrap the same flow.
