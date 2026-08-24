# Evidence Enforcement Plan

> Goal: close the #1 weakest point from pivot-validation — evidence integrity.
> Verify is only as honest as hand-edited `impl/tests` cells. This plan makes
> evidence first-class (provenance-recorded) and optionally *executed*.

## Changes

### Phase 1 — `ae artifact mark-evidence` (bookkeeping integrity)

- **Model** (`ArtifactCell`): add nullable `evidenceCommand` (serialized as
  `evidence_command`). Backward compatible via fromMap/toJson.
- **Core** (`DefaultArtifactService.markEvidence`): load pack, find row by id
  (`feature_not_found` on miss), set `tests: yes` (or explicit status),
  `impl` defaults to `done` when still `missing`, record `location`
  (test file) and `evidenceCommand`. Save. Result reports old→new cell.
- **CLI**: `ae artifact mark-evidence --pack P --feature F --test-command <cmd>
  [--location <path>] [--impl done] [--notes <t>]`.
- **MCP**: `ae_artifact` op `mark-evidence` mirroring params.
- Error code: `feature_not_found` (registered in playbook).

### Phase 2 — `verify --run-tests` (enforcement)

- `DefaultArtifactService.verifyOne(pack, {runTests, runner})`: when
  `runTests`, every referenced-canonical row carrying `evidenceCommand` is
  executed via `ProcessRunner` (`bash -c <cmd>`, 120s cap).
  Classification:
  - command exits 0 → row counts as verified (no Tier 1 even though before
    it would only trust the cell);
  - command fails → Tier 1 entry `evidence failed: '<cmd>' exited N` — the
    pack is caught lying about its own evidence;
  - no command recorded + invariant unverified → unchanged Tier 1 behavior.
- **CLI**: `ae artifact verify --pack P [--strict] [--run-tests]`.
- **Doctor-free**: no environment assumptions beyond a POSIX shell.

## Evaluation gate

Run on this repo: mark the embedded-resources byte-equality invariant with
its real test command (`dart test test/embedded_resources_test.dart`) —
`verify --run-tests` must pass it while other packs stay Tier 1; then mark a
deliberately failing command and show Tier 1 catches the lie.
