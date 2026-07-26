```
   ___   ____
  / _ | / __/
 / __ |/ _/
/_/ |_/___/  Agentic Executables
```

**Define once. Reuse anywhere.**

**Turn domain knowledge into executable instructions.** Humans and AI agents run the same deterministic commands.


<!-- badges -->
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Discord](https://img.shields.io/discord/1234567890?label=Discord)](https://discord.gg/y54DpJwmAn)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/fluent-meaning-symbiotic/agentic_executables)

> **AE v3.x** is here. See [`docs_site/docs/ae-3-overview.md`](docs_site/docs/ae-3-overview.md) for the architecture overview and [`plugins/claude-code-ae-plugin/`](plugins/claude-code-ae-plugin/) for the Claude Code integration. (will be expanded to include Cursor and Codex integrations soon)

## Status

AE v3.x is in beta. The core functionality is stable, but the API is subject to change.

## What is AE?

AE is an open framework that extracts domain knowledge and turns it into executable lifecycle instructions. It works for libraries, apps, games, servers — any implementation. Humans and AI agents share the same deterministic workflows.

Think of AE like a USB-C port for project knowledge. Just as USB-C provides a standardized way to connect devices, AE provides a standardized way to connect domain knowledge to executable workflows.


<p align="center">
  <img src="docs/fun_image.png" alt="Fun image" style="max-width:100%;">
</p>

## What can AE do?

- Extract domain knowledge from specs, docs, or git repos
- Generate deterministic install / uninstall / update / use instructions
- Store everything in a local-first hub that works offline
- Sync with remote registries when ready
- Produce deployment-ready packages
- Let AI agents and humans execute the same workflows

## Two Core Capabilities

**Know** — extract and store domain knowledge from specs, docs, repos, or any source.
**Use** — turn knowledge into executable instructions (install, uninstall, update, use).

They compose freely depending on what you need:

```text
Know alone       → implement features directly from extracted knowledge
Use alone        → manage project lifecycles with deterministic instructions
Know + Use       → generate domain-aware lifecycle files
Know + Use + Pkg → full deployment pipeline (optional)
```

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/fluent-meaning-symbiotic/agentic_executables/main/install.sh | bash
```

```bash
# Extract domain knowledge
ae hub init
ae know build --url https://modelcontextprotocol.io/llms-full.txt --name mcp
ae know build --url https://arxiv.org/pdf/2312.11514 --name llm_flash   # PDF (e.g. arXiv); --format pdf or auto

# Use it however you need:
ae know show --name mcp                                          # read and implement directly
ae generate --library-id my_sdk --library-root . --know mcp      # generate lifecycle files
ae registry get --library-id python_requests --action install     # or just manage a project
```

Source fallback:

```bash
cd agentic_executables_cli && dart pub get && dart run bin/ae.dart definition
```

## Commands

| Command | What it does |
|---------|-------------|
| `ae hub init` | Create local-first hub |
| `ae hub status` | Show hub artifacts and config |
| `ae hub pull` | Pull from remote registry |
| `ae hub push` | Generate push instructions |
| `ae know build` | Extract knowledge from URL, repo, or file (supports PDF via `--format pdf` or auto; `--on-conflict reuse\|update\|fail\|new_version`) |
| `ae know list` | List stored knowledge packs |
| `ae know show` | Display knowledge pack content |
| `ae know diff` | Compare two knowledge versions |
| `ae know update` | Re-fetch from source |
| `ae know migrate` | Migrate legacy name-keyed packs to canonical layout (source-id + aliases) |
| `ae generate` | Generate ae_use lifecycle files |
| `ae instructions` | Get context-appropriate guidance |
| `ae registry get --library-id <id>` | Fetch from remote registry |
| `ae registry submit` | Submit to registry |
| `ae package resolve` | Produce deployment JSON (optional) |
| `ae package validate` | Validate package instructions |
| `ae verify` | Verify implementation checklist |
| `ae evaluate` | Evaluate AE compliance |
| `ae doctor` | Preflight environment checks |
| `ae definition` | Framework definition |
| `ae skill install [--upgrade]` | Install AE skill template |

## MCP Tools

| Tool | Purpose |
|------|---------|
| `ae_definition` | Framework definition |
| `ae_instructions` | Context guidance (supports `--know`) |
| `ae_generate` | Lifecycle file generation (supports `--know`) |
| `ae_registry` | Registry operations |
| `ae_hub` | Hub management |
| `ae_know` | Knowledge extraction |
| `ae_verify` | Implementation verification |
| `ae_evaluate` | Compliance evaluation |

## Architecture

| Package | Role |
|---------|------|
| `agentic_executables_core/` | Typed business logic, ports, adapters |
| `agentic_executables_cli/` | `ae` CLI (JSON-first, `--human` for readable) |
| `agentic_executables_mcp/` | MCP v3 adapter |
| `docs_site/` | VitePress docs with `/llms.txt` output |

## Ecosystem

AE works with any AI agent or IDE that supports MCP: Claude, Cursor, VS Code Copilot, Codex, and more.

Machine-readable docs are published at `/llms.txt` and `/llms-full.txt` for direct agent consumption.

## Links

- [Docs Site](https://github.com/fluent-meaning-symbiotic/agentic_executables/tree/main/docs_site)
- [Registry](https://github.com/fluent-meaning-symbiotic/agentic_executables_registry)
- [Error Code Playbook](docs/error_code_playbook.md)
- [Architecture Diagram](docs/architecture_diagram.md)
- [Discord](https://discord.gg/y54DpJwmAn)

## Testing

```bash
cd agentic_executables_core && dart test
cd ../agentic_executables_cli && dart test
cd ../agentic_executables_mcp && dart test
```


## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=fluent-meaning-symbiotic/agentic_executables&type=Date)](https://www.star-history.com/#fluent-meaning-symbiotic/agentic_executables&Date)


## License

[MIT](LICENSE)
