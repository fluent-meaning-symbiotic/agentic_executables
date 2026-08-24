---
title: "Roadmap"
outline: deep
---

# Roadmap

What's next, what's deferred, what's deliberately not coming. AE 3.0 ships lean on purpose — the [anti-goals](#anti-goals) section explains why several "obvious" features are absent. Three time horizons follow.

## 3.1 fast-follow

Things 3.0 is designed for and that should land within weeks of 3.0:

- **Spec importers (SHIPPED 2026-08).** `ae canonical import-spec` deterministically imports GitHub Spec Kit specs, ADRs, and structured markdown as canonical feature rows — no LLM, merge-safe. The strategy shifted from "authors write canonicals" to "make any existing spec verifiable"; language extractors stop being the adoption bottleneck.
- **AE never calls a model (SHIPPED 2026-08, breaking).** The executor family (claude_code / codex / byok) was hard-cut. Distillation is now emit-delegation (task + instructions for the host agent) plus validated merge (`--from-output` / op `distill-merge`). AE is a tool that delegates instructions — never a model caller.
- **Code-agnostic distillation (SHIPPED 2026-08).** `ae canonical distill --repo <url>` distills any public repo in any language: shallow clone → generic-extractor ingest (specific extractor when recognized) → delegation emit. Language extractors are now accelerators, not gates. Self-dogfooded: all three AE packages distilled into verified canonicals (`ae-core`, `ae-cli2`, `ae-mcp`), Tier-1 clean with executed evidence.

- **Polished `ae status` cockpit UI.** The current report is honest but plain. 3.1 adds proper formatting, color, paging, and a `--watch` mode for `ae artifact verify` that's friendly inside a terminal split next to the editor.
- **Pre-commit hook recipes.** A small set of recipes for git pre-commit / pre-push that run `ae artifact verify --strict` against the artifacts touched by the commit, so Tier 1+2 gaps fail before they merge.
- **Cursor-flavored Claude Code plugin equivalent.** Same shape as `plugins/claude-code-ae-plugin/`, adapted to Cursor's command and skill conventions. See [Claude Code plugin](./plugin).
- **Multi-pack distillation.** `ae canonical distill --from-artifact a,b,c --concept <slug>` so a canonical can be seeded from several language implementations at once, increasing the chance the distilled features are genuinely language-neutral.
- **Agent-delegated artifact→canonical scaffolding (LLM variant).** Heuristic `ae canonical scaffold --from-artifact <pack>` shipped in 3.1.0-alpha.1; 3.1 adds an LLM-assisted variant for the cases where pure heuristics undershoot.
- **`ae status --pack`-level invariant evidence.** Today Tier 1 says "no test asserts this"; 3.1 attaches the evidence — which test files were searched, what patterns were tried — so users can act on the finding without a separate hunt.

## 3.2 / 3.x

Larger pieces that need their own design rounds but are firmly on the trajectory:

- **Auto package-hub discovery.** The resolver already supports `<pkg>/.ae_hub/canonical/`. 3.x walks installed packages automatically and offers to pull canonicals into the project hub. Until then, [`ae canonical import`](./cli-reference#ae-canonical-import) is the manual path.
- **`ae canonical migrate`.** Automated upgrade of artifacts to a newer canonical snapshot. Orthogonal to the "no migration from old `know/` layout" decision in spec §9 — that one is hard-cut on purpose; this one is canonical-version migration only, and is much smaller in scope.
- **JS/TS heuristic extractor.** Optional accelerator — the generic fallback already distills JS/TS via delegation; a specific extractor improves the structural summary and sync fidelity. Python and Go likewise.
- **Public canonical hub.** Pack format is publishable today (deterministic IDs, attribution required, no machine-specific paths). The remote sharing system itself needs a separate design doc covering hosting, trust, signing, and discovery.

## Post-3.x

Genuinely longer-horizon, dependent on the world catching up or on real demand materializing:

- **Cross-language code generation.** "Same canonical, multiple language implementations" is the seed. Going from canonical-to-Rust-port-of-this-Dart-package requires LLMs that are credibly capable of idiomatic non-trivial ports, which they aren't reliably in 2026. Watch the space; revisit when it changes.
- **Multi-repo workspaces.** One `.ae_hub/` per repo today; cross-repo aggregation deliberately not in 3.0. If multi-repo becomes a real bottleneck for solo devs maintaining several engines, this comes back.
- **Dgraph (or other graph backend).** Filesystem packs already model a graph via stable IDs and references. If cross-pack graph queries become valuable enough to justify the operational cost of a graph DB, the storage adapters from [Adapters](./adapters) make it a swap, not a rewrite.
- **Team / shared hub / RBAC.** AE 3.0 is solo-dev focused. Shared hubs are a different product surface; designing for teams without solo-dev nailed first is how you ship neither.
- **Agent-teams integration.** Claude Code's agent-teams primitives are interesting; AE could plausibly orchestrate distillation across a team of subagents. Reserved for post-3.x once the basics have landed.

## Anti-goals

Things AE 3.0 deliberately does **not** ship, and why:

- **Cross-language code generation today.** See above. The matrix-as-language-neutral-spec is the seed; full generation is post-3.x.
- **Auto-sync between code and canonical.** Drift visibility is honest; auto-sync would lie. Drift detection stays; auto-sync stays out.
- **Public canonical hub.** Format is publishable; the system isn't designed yet.
- **Multi-repo workspaces.** One hub per repo.
- **Team / sharing flows.** Solo-dev focus.
- **Dgraph or any graph backend.** Filesystem packs already model the graph.
- **Auto package-hub discovery (yet).** Manual `ae canonical import` is the 3.0 path.
- **Migration from 2.x `know/` layout.** Hard cut. Old hubs error out with clear instructions; back up and re-run [`ae init`](./cli-reference#ae-init).

## Surprises

Running list of spec-vs-code deltas the 3.0 docs site flags:

- **`ae mcp`** as a subcommand of `ae` (spec §12) is not in `cli.dart`. The MCP server ships as the separate `agentic_executables_mcp` binary.

## Where to next

- [Concepts](./) — the four crystallizations that frame all of this.
- [Walkthroughs](./walkthroughs) — what 3.0 does ship, end-to-end.
