#!/usr/bin/env bash
# Pipeline benchmark: runs the FULL canonical workflow against this repo
# itself (Dart monorepo + Rust contract crate) from a fresh hub, and
# reports per-phase wall time from each envelope's meta.timing_ms.
#
# Usage: benchmarks/pipeline_bench.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AE="dart run $REPO/agentic_executables_cli/bin/ae.dart"
CLI_DIR="$REPO/agentic_executables_cli"

ms() { python3 -c "import json,sys; d=json.load(sys.stdin); print(d['meta']['timing_ms'])"; }

run() { # run <label> <args...>  -> prints "label<TAB>ms"
  local label="$1"; shift
  local out
  out=$(cd "$CLI_DIR" && $AE "$@" --root "$REPO" 2>/dev/null | tail -1)
  printf "%-38s\t%s\n" "$label" "$(echo "$out" | ms)"
  echo "$out" > /tmp/ae_bench_last.json
}

echo "phase	ms"
# Fresh hub
rm -rf "$REPO/.ae_hub"
(cd "$CLI_DIR" && $AE hub init --project --path "$REPO" >/dev/null 2>&1)

run "ingest: ae init (4 packages)"        init
run "scaffold: canonical from CLI API"    canonical scaffold --concept ae/cli --title "AE CLI contract" --from-artifact agentic_executables_cli
run "emit: distill delegation task"       canonical distill --pack agentic_executables_cli --concept ae/cli
python3 - <<'PY'
import json
d=json.load(open('/tmp/ae_bench_last.json'))
instr=d['data']['instructions']
open('/tmp/ae_bench_emit_size','w').write(str(len(instr)))
print(f"emit: instructions payload bytes      \t{len(instr)}")
PY

# Simulate host-agent work with a minimal valid draft (3 rows enriched)
SEEDS=$(python3 -c "
import json, re
ids=[]
for line in open('$REPO/.ae_hub/canonical/ae/cli/matrix.yaml'):
    m=re.match(r'\s*-\s*id:\s*(\S+)', line)
    if m: ids.append(m.group(1))
print(json.dumps(ids[:3]))")
python3 - "$SEEDS" <<'PY'
import json,sys
seeds=json.loads(sys.argv[1])
draft={
 "schema":"ae.canonical.draft.v1","concept_id":"ae/cli","concept_version":1,
 "index_md":"# AE CLI contract\n",
 "matrix":{"schema":"ae.canonical_matrix.v1","concept":"ae/cli","version":1,
   "column_schema":[{"id":"spec","type":"text"},{"id":"invariant","type":"text"}],
   "features":[{"id":i,"spec":"benched","invariant":"benched"} for i in seeds]},
 "proposed_concepts":[]}
open('/tmp/ae_bench_draft.json','w').write(json.dumps(draft))
print(f"agent work: rows returned             \t{len(seeds)}")
PY
run "merge: validate + merge draft"       canonical distill --concept ae/cli --from-output /tmp/ae_bench_draft.json

for p in agentic_executables_core agentic_executables_mcp selfdemo_rust; do true; done
run "link: core -> ae/cli"                artifact link --pack agentic_executables_core --canonical ae/cli
run "link: mcp -> ae/cli"                 artifact link --pack agentic_executables_mcp --canonical ae/cli
run "verify: cli pack (14 features)"      artifact verify --pack agentic_executables_cli
run "verify: core pack"                   artifact verify --pack agentic_executables_core
run "verify: mcp pack"                    artifact verify --pack agentic_executables_mcp
run "status: project cockpit"             status
run "sync: drift rescan"                  sync
run "spec export: v3 JSON"                spec export --out /tmp/ae_bench_spec

# Coverage metric: scaffolded rows vs real source files in the CLI package
SRC=$(find "$REPO/agentic_executables_cli/lib/src" -name "*.dart" | wc -l | tr -d ' ')
ROWS=$(grep -c "  - id:" "$REPO/.ae_hub/canonical/ae/cli/matrix.yaml" || true)
echo ""
echo "coverage: $ROWS canonical rows / $SRC cli lib/src files"
