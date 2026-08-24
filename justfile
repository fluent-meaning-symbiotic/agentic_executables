# Local AE E2E (replaces removed scripts/ae_e2e_local_hub.sh).
# Requires: `just`, Dart; optional `cargo` for Rust parity.
# Env: AE_E2E_NETWORK=1 — URL smoke pack; AE_E2E_EXTENDED=1 — downstream smoke.
# Env: AE_E2E_LOCALE — BCP 47 locale for spec export plans (default: en).
# Env: E2E_MATRIX_PRIMARY — overrides matrix_primary from docs/e2e/e2e_know_sources.yaml.
# Env: AE_E2E_MATRIX_BASELINE — optional repo-relative or absolute matrix YAML; writes matrix_diff.json on export.

set shell := ['bash', '-uc']

repo := justfile_directory()
hub := repo / '.ae_hub'
spec_dir := repo / 'experiments' / 'ae_rust_contract' / 'spec'

default:
	@just --list

# Shared: export spec dir (single place for flags; used by `e2e` and `e2e-export`).
spec-export:
	#!/usr/bin/env bash
	set -euo pipefail
	REPO="{{repo}}"
	HUB="$REPO/.ae_hub"
	SPEC="{{spec_dir}}"
	MATRIX="$REPO/docs/feature_matrix.yaml"
	LOCALE="${AE_E2E_LOCALE:-en}"
	mkdir -p "$SPEC"
	cd "$REPO"
	if [[ -n "${AE_E2E_MATRIX_BASELINE:-}" ]]; then
	  BP="${AE_E2E_MATRIX_BASELINE}"
	  if [[ "$BP" != /* ]]; then BP="$REPO/$BP"; fi
	  dart run agentic_executables_cli/bin/ae.dart spec export --out "$SPEC" --hub "$HUB" --matrix "$MATRIX" --locale "$LOCALE" --manifest "$REPO/docs/e2e/e2e_know_sources.yaml" --matrix-baseline "$BP"
	else
	  dart run agentic_executables_cli/bin/ae.dart spec export --out "$SPEC" --hub "$HUB" --matrix "$MATRIX" --locale "$LOCALE" --manifest "$REPO/docs/e2e/e2e_know_sources.yaml"
	fi

# Wipe hub, generated matrix, spec exports (keeps spec/.gitkeep).
e2e-reset:
	#!/usr/bin/env bash
	set -euo pipefail
	REPO="{{repo}}"
	SPEC="{{spec_dir}}"
	rm -rf "$REPO/.ae_hub"
	rm -f "$REPO/docs/feature_matrix.yaml"
	mkdir -p "$SPEC"
	find "$SPEC" -maxdepth 1 -type f ! -name '.gitkeep' -delete 2>/dev/null || true
	touch "$SPEC/.gitkeep"
	echo "ae_e2e: reset (hub + docs/feature_matrix.yaml + spec exports cleared)"

# Export Rust spec only; requires existing `.ae_hub` and `docs/feature_matrix.yaml`.
e2e-export:
	#!/usr/bin/env bash
	set -euo pipefail
	REPO="{{repo}}"
	cd "$REPO"
	just spec-export
	echo "ae_e2e: Rust spec exported to experiments/ae_rust_contract/spec/"

# Full pipeline: reset, pub get, hub, manifest-driven know builds, matrix, spec export, optional extended smoke.
e2e:
	#!/usr/bin/env bash
	set -euo pipefail
	REPO="{{repo}}"
	HUB="$REPO/.ae_hub"
	SPEC="{{spec_dir}}"
	MATRIX="$REPO/docs/feature_matrix.yaml"
	LOCALE="${AE_E2E_LOCALE:-en}"
	just e2e-reset
	( cd "$REPO/agentic_executables_cli" && dart pub get )
	cd "$REPO"
	dart run agentic_executables_cli/bin/ae.dart hub init --project
	dart run agentic_executables_cli/bin/ae.dart e2e sync-know --manifest "$REPO/docs/e2e_know_sources.yaml" --hub "$HUB"
	MATRIX_PRIMARY="${E2E_MATRIX_PRIMARY:-}"
	if [[ -z "$MATRIX_PRIMARY" ]]; then
	  MATRIX_PRIMARY="$(grep -E '^matrix_primary:' "$REPO/docs/e2e_know_sources.yaml" 2>/dev/null | head -1 | awk '{print $2}')"
	fi
	[[ -z "$MATRIX_PRIMARY" ]] && MATRIX_PRIMARY=ae_docs_know_design
	dart run agentic_executables_cli/bin/ae.dart know matrix init --name "$MATRIX_PRIMARY" --columns cli,mcp,know,hub --title "AE E2E matrix" --hub "$HUB"
	dart run agentic_executables_cli/bin/ae.dart know matrix scaffold --name "$MATRIX_PRIMARY" --repo "$REPO" --hub "$HUB"
	dart run agentic_executables_cli/bin/ae.dart know matrix diff --from-name "$MATRIX_PRIMARY" --to-file "$MATRIX" --hub "$HUB" >/dev/null
	echo "ae_e2e: matrix scaffolded to docs/feature_matrix.yaml"
	mkdir -p "$SPEC"
	just spec-export
	echo "ae_e2e: Rust spec exported to experiments/ae_rust_contract/spec/"
	if [[ "${AE_E2E_EXTENDED:-}" == "1" ]]; then
	  MP="$MATRIX_PRIMARY"
	  o=$(dart run agentic_executables_cli/bin/ae.dart instructions --context library --action bootstrap --know "$MP" 2>&1) || { echo "$o" >&2; exit 1; }
	  echo "$o" | grep -q '"success":true' || { echo "$o" >&2; exit 1; }
	  o=$(dart run agentic_executables_cli/bin/ae.dart generate --library-id dart_e2e --library-root /tmp --engine template --dry-run --know ae_pkg_cli_readme 2>&1) || { echo "$o" >&2; exit 1; }
	  echo "$o" | grep -q '"success":true' || { echo "$o" >&2; exit 1; }
	  o=$(dart run agentic_executables_cli/bin/ae.dart verify --input "$REPO/docs/e2e/ae_e2e_verify.json" 2>&1) || { echo "$o" >&2; exit 1; }
	  echo "$o" | grep -q '"success":true' || { echo "$o" >&2; exit 1; }
	  o=$(dart run agentic_executables_cli/bin/ae.dart evaluate --input "$REPO/docs/e2e/ae_e2e_evaluate.json" 2>&1) || { echo "$o" >&2; exit 1; }
	  echo "$o" | grep -q '"success":true' || { echo "$o" >&2; exit 1; }
	  o=$(dart run agentic_executables_cli/bin/ae.dart package resolve --package dev.xs.registry --target linux --format json 2>&1) || { echo "$o" >&2; exit 1; }
	  tmp=$(mktemp)
	  echo "$o" >"$tmp"
	  o=$(dart run agentic_executables_cli/bin/ae.dart package validate --instructions "$tmp" 2>&1) || { rm -f "$tmp"; echo "$o" >&2; exit 1; }
	  rm -f "$tmp"
	  grep -q '^ok$' <<<"$o" || { echo "$o" >&2; exit 1; }
	  o=$(dart run agentic_executables_cli/bin/ae.dart doctor 2>&1) || { echo "$o" >&2; exit 1; }
	  echo "$o" | grep -q '"success":true' || { echo "$o" >&2; exit 1; }
	  echo "ae_e2e: extended smoke ok"
	fi
	echo "ae_e2e: done. Run: cd experiments/ae_rust_contract && cargo test && cargo run -p ae_cli_stub -- parity-check"
