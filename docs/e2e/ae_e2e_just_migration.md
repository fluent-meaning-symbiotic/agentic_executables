# E2E: migration note (historical)

Shell script + Python in the E2E path were removed in favor of **Just**, **`ae know plan --out`**, **`ae e2e sync-know`**, and **`ae spec export`**.

**Authoritative doc:** [`ae_e2e_log.md`](ae_e2e_log.md) — commands, env vars, schema names, Rust contract policy, and CI parity.

**History (one line each):** `scripts/ae_e2e_local_hub.sh` deleted; Python JSON extraction for plan markdown removed; know sources live in [`e2e_know_sources.yaml`](e2e_know_sources.yaml); export is one Dart command writing `spec_index.json` + per-pack fixtures.
