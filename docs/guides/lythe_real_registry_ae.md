# Lythe real-registry E2E and AE

Lythe’s `scripts/ensure-real-ae.sh` builds this repo’s `agentic_executables_cli` binary into a cache (for example `.tmp/real-tools/ae`) and sanity-checks:

- `ae --help`
- `ae package resolve --help`
- `ae package validate --help`

Resolution order for the agentic_executables checkout root:

1. `LYTHE_REAL_AE_REPO_ROOT` when it contains `agentic_executables_cli/`
2. Relative paths from the Lythe repo root (same rules as Lythe’s Rust `discover_default_ae_repo_root`), for example `../../mcp/cline/agentic_executables` when Lythe and this repo share a common parent

Real Flutter integration tests invoke that binary on the live host path. No stub AE executable is used in those flows.
