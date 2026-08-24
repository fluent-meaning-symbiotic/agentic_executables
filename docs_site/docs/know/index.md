---
title: Knowledge Extraction
outline: deep
---

# Knowledge Extraction

## Purpose

Use `ae know` to extract domain knowledge from specs, docs, repos, or APIs and store it in the hub for generation, agents, or direct implementation.

## Summary

`ae know` extracts domain knowledge from any source — specs, docs, repos, APIs — and stores it in the hub. Use it to generate instructions for libraries, apps, games, servers, or any implementation.

## How knowledge flows

```text
                    ┌→ Implement features directly (read and code)
ae know build ──────┤
                    └→ ae generate --know ──┬→ Integrate into project
                                            └→ ae package (optional deploy)
```

**Know** extracts domain knowledge. **Use** turns it into executable instructions. Combine them however your project needs.

### Extract → implement (full loop)

For a concise pipeline (extract → plan → `instructions` / `generate` → verify → evaluate), large-codebase sharding, and what to simplify vs strengthen next, see the repository document **`docs/ae_know_extract_implement.md`** in the [agentic_executables](https://github.com/fluent-meaning-symbiotic/agentic_executables) repo (not mirrored on this site). Local monorepo E2E for that repo uses **`just e2e`** (see **`docs/e2e/ae_e2e_log.md`**).

### Example flows

**Implement from a spec** — extract glTF knowledge, then build a loader:

```bash
ae know build --url <gltf-spec> --name gltf_2 --format html
ae know show --name gltf_2  # agent reads and implements
```

**Generate lifecycle files** — extract MCP knowledge, then produce ae_use files:

```bash
ae know build --url https://modelcontextprotocol.io/llms-full.txt --name mcp
ae generate --library-id dart_mcp --library-root . --know mcp
```

**Rewrite to another language** — extract existing project knowledge, then reimplement:

```bash
ae know build --repo https://github.com/my-org/my-dart-lib --name my_lib
ae know show --name my_lib  # agent reads and rewrites in Rust
```

## Prerequisites

- Hub initialized: `ae hub init`
- Network access (for URL and repo sources)

## Build a knowledge pack

### From an llms.txt or markdown URL

```bash
ae know build --url https://modelcontextprotocol.io/llms-full.txt --name mcp
```

### From an HTML page (converted via Jina Reader)

```bash
ae know build --url https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html --name gltf_2 --format html
```

### From a PDF URL (e.g. arXiv)

PDFs are converted to markdown via Jina Reader. Use `--format pdf` explicitly or rely on auto-detection for URLs ending in `.pdf` or containing `/pdf/`:

```bash
ae know build --url https://arxiv.org/pdf/2312.11514 --name llm_flash
ae know build --url https://example.com/paper.pdf --name my_paper --format pdf
```

### From a git repository

```bash
ae know build --repo https://github.com/anthropics/anthropic-sdk-python --name anthropic_sdk
```

### From a local file

```bash
ae know build --url file:///path/to/spec.md --name my_spec
```

Expected result: knowledge pack stored in hub under canonical layout `know/{type}/{format}/{sourceId}/` with alias `know/_aliases/{name}.yaml` for lookups. Legacy layout `know/{name}/` is still supported for backward compatibility until migrated.

### On-conflict when the same source already exists

When the source (e.g. URL) is already stored, use `--on-conflict` to control behavior:

| Value             | Behavior                                                           |
| ----------------- | ------------------------------------------------------------------ |
| `reuse` (default) | Attach the new name as an alias to the existing pack; no re-fetch. |
| `update`          | Re-fetch and update the canonical pack; attach name as alias.      |
| `fail`            | Return an error (e.g. in CI when duplicates are not allowed).      |
| `new_version`     | Create a new version under the same source id.                     |

```bash
ae know build --url https://example.com/spec.pdf --name spec_a
ae know build --url https://example.com/spec.pdf --name spec_b --on-conflict reuse   # alias only
ae know build --url https://example.com/spec.pdf --name spec_b --on-conflict fail    # error
```

### Migrate legacy packs to canonical layout

If you have packs stored under the old name-only layout, run a one-time migration to collapse duplicates and create the alias index:

```bash
ae know migrate --dry-run   # report only
ae know migrate             # migrate and remove legacy dirs
```

After migration, `ae know show --name <name>` continues to work via the alias index.

## List knowledge packs

```bash
ae know list
```

Returns all stored packs with metadata (source, token estimate, format).

## Show a pack

```bash
ae know show --name mcp
```

Returns the full distilled content.

## Update a pack (re-fetch from source)

```bash
ae know update --name mcp
```

Re-fetches from the original source. If content hasn't changed, returns `no_op: true`.

## Remove a pack

```bash
ae know remove --name mcp
```

## Compare two packs

```bash
ae know diff --from mcp_v1 --to mcp_v2
```

Returns section-level comparison: added, removed, changed, unchanged.

Use this for migration planning between spec versions.

## Spec + feature matrix workflow

1. **Build or have a know pack** (`ae know build ...`) so `index.md` distills the domain.
2. **Add a coverage matrix** (YAML is canonical; Markdown is generated):

   ```bash
   ae know matrix init --name my_spec --columns import,bundle,runtime_native,runtime_web,proof \
     --title "My API coverage" \
     --normative-kind url --normative-ref "https://example.com/spec"
   ```

   This writes `matrix.yaml` + `matrix.md` next to `index.md` and records `artifacts` in `meta.yaml`. Rows use stable **feature ids** for deterministic `ae know matrix diff`.

3. **Export one implementation plan** for agents or humans:

   ```bash
   ae know plan --name my_spec
   ```

4. **Copy matrix into a repo** as a tracked artifact (edit status cells in the repo; re-diff against hub when the template changes):

   ```bash
   ae know matrix scaffold --name my_spec --repo /path/to/project
   # default: <repo>/docs/feature_matrix.yaml
   ```

5. **Compare matrices** (hub vs hub, file vs file, or hub vs file):

   ```bash
   ae know matrix diff --from-name my_spec_v1 --to-name my_spec_v2
   ae know matrix diff --from-file ./hub_matrix.yaml --to-file ./docs/feature_matrix.yaml
   ```

### Example column templates

| Use case               | Example `--columns`                                          |
| ---------------------- | ------------------------------------------------------------ |
| Multi-runtime pipeline | `imported,bundle_preserved,runtime_native,runtime_web,proof` |
| Minimal                | `scope,done,proof`                                           |

`ae instructions` / `ae generate --know` include **index + rendered matrix + normative link** when present.

## Use knowledge in generation

The `--know` flag pipes domain knowledge into AE file generation:

```bash
ae generate --library-id dart_mcp_sdk --library-root . --know mcp
```

The inference engine uses the knowledge to produce domain-aware install, uninstall, update, and use instructions.

Also works with instructions:

```bash
ae instructions --context library --action bootstrap --know mcp
```

## Knowledge pack format

**Canonical layout** (default for new builds):

```text
hub/know/{type}/{format}/{sourceId}/
├── meta.yaml           # Source, current_content_sha, fingerprint
├── aliases.yaml        # List of names (aliases) for this pack
└── versions/{contentSha}/
    ├── index.md        # Distilled content (the core artifact)
    ├── matrix.yaml     # Optional feature matrix (canonical for tooling)
    ├── matrix.md       # Optional; generated from matrix.yaml
    └── patterns.md     # Optional implementation patterns

hub/know/_aliases/{name}.yaml   # name → source_id, canonical_path
hub/know/_by_source/{sourceId}.yaml  # source_id → type, format
```

**Legacy layout** (still supported; migrate with `ae know migrate`):

```text
hub/know/{name}/
├── index.md      # Distilled content
├── meta.yaml     # Source URL, format, token estimate, fingerprint; optional artifacts
├── matrix.yaml   # Optional
├── matrix.md     # Optional
└── patterns.md   # Optional
```

### meta.yaml example

```yaml
name: mcp
version: ""
source:
  type: url
  url: "https://modelcontextprotocol.io/llms-full.txt"
  format: llms_txt
distill:
  engine: passthrough
  token_estimate: 349042
fetched_at: "2026-03-18T14:29:30.647953Z"
sha256: "073216e0"
tags: []
```

## Extraction strategies

| Source                  | Extractor      | Format flag          | What happens                                    |
| ----------------------- | -------------- | -------------------- | ----------------------------------------------- |
| llms.txt / markdown URL | Passthrough    | `auto` or `llms_txt` | Fetch → normalize → store                       |
| HTML page               | URL Extractor  | `html`               | Fetch → Jina Reader → markdown → store          |
| PDF URL (e.g. arXiv)    | PDF Extractor  | `auto` or `pdf`      | Fetch → Jina Reader → markdown → store          |
| Git repository          | Repo Extractor | auto-detected        | Clone → scan README/docs/examples → build index |
| Local file              | Passthrough    | `auto` or `markdown` | Read → store                                    |

Use `--format pdf` when the URL does not end in `.pdf` or contain `/pdf/` but you know the response is PDF. Use `auto` for standard PDF URLs so the format is inferred.

## Common failure modes

### `invalid_name`

Cause: name doesn't match `[a-z][a-z0-9_]*`.

Recovery: use lowercase letters, numbers, and underscores only.

### `already_exists`

Cause: pack with that name exists, or same source already stored and `--on-conflict fail` was used.

Recovery: use `--on-conflict reuse` to attach the name as an alias, `--on-conflict update` to refresh, or choose a different name.

### `hub_not_found`

Cause: no hub initialized.

Recovery: `ae hub init`

### `unsupported_source`

Cause: no extractor available for the source type.

Recovery: use `--format html` for HTML pages, `--format pdf` for PDFs, or use a URL/local source.

## Verify

`ae know list` shows your pack; `ae know show --name <name>` returns distilled content for a built pack.

## If it fails

Use **Common failure modes** above, then [Troubleshooting](/troubleshooting/).

## What to do next

- [Generate domain-aware AE files](/use/) with `ae generate --know`
- [Compare specs](/know/) with `ae know diff`
- [Sync with team](/hub/) via `ae hub push`
