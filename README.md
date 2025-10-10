# Agentic Executables (AE)

A framework-agnostic approach enabling AI agents to autonomously manage library installation, configuration, and usage across any programming language.

## What is AE?

Agentic Executables treat libraries as executable programs with structured, agent-readable instructions. Instead of relying on human documentation, AI agents follow standardized `.md` files to install, configure, integrate, update, and uninstall libraries autonomously.

## Repository Structure

### 1. Framework Core → [`prompts_framework/`](./prompts_framework/)

Foundation documents defining AE principles and methodology:

- **`ae_context.md`** - Core definitions and principles
- **`ae_bootstrap.md`** - Guide for creating AE files
- **`ae_use.md`** - Guide for using AE files

### 2. MCP Server → [`agentic_executables_mcp/`](./agentic_executables_mcp/)

Model Context Protocol server providing strategic guidance for AI agents:

- 5 core tools: definition, instructions, verification, evaluation, registry management
- Language-agnostic guidance for AE operations
- Docker deployment ready

[**Full Documentation →**](./agentic_executables_mcp/README.md)

### 3. Library Registry → [`ae_use_registry/`](./ae_use_registry/)

Centralized repository of AE-enabled libraries:

- Curated library-specific AE files
- Standardized naming: `<language>_<library_name>`
- Direct fetch via MCP tools or manual download

[**Contributing Guide →**](./ae_use_registry/CONTRIBUTING.md)

## Quick Start

### For Library Authors

1. Use MCP tool or read [`prompts_framework/ae_bootstrap.md`](./prompts_framework/ae_bootstrap.md)
2. Create `ae_use/` folder with 4 required files:
   - `ae_install.md` - Installation instructions
   - `ae_uninstall.md` - Removal instructions
   - `ae_update.md` - Migration guide
   - `ae_use.md` - Usage patterns
3. Submit to registry via MCP tool or PR

[**Full Bootstrap Guide →**](./prompts_framework/ae_bootstrap.md)

### For Developers

**With AI Agent + MCP Server:**

```
Agent → MCP: get_from_registry(library_id: "python_requests", action: "install")
Agent → Executes installation automatically
```

**Manual:**

1. Browse [`ae_use_registry/`](./ae_use_registry/) for your library
2. Download relevant `.md` files
3. Provide to AI agent for execution

[**Installation Guide →**](./agentic_executables_mcp/ae_install.md)

## Core Principles

- **Agent Empowerment** - AI agents work autonomously without human intervention
- **Modularity** - Clear, reusable instruction steps
- **Contextual Awareness** - Sufficient domain knowledge embedded
- **Reversibility** - Clean uninstallation restores original state
- **Validation** - Built-in verification steps
- **Language Agnostic** - Works across all ecosystems

## Workflow Overview

```
Library Author                  Registry                   Developer
      │                            │                           │
      ├─► Create AE files          │                           │
      ├─► Submit to registry ─────►│                           │
      │                            │◄───── Fetch AE files ─────┤
      │                            │                           │
      │                            │                   AI Agent executes
      │                            │                   installation
```

## Resources

- **MCP Server Setup**: [`agentic_executables_mcp/README.md`](./agentic_executables_mcp/README.md)
- **Registry Contribution**: [`ae_use_registry/CONTRIBUTING.md`](./ae_use_registry/CONTRIBUTING.md)
- **Example Libraries**: [`ae_use_registry/dart_xsoulspace_lints/`](./ae_use_registry/dart_xsoulspace_lints/), [`ae_use_registry/python_requests/`](./ae_use_registry/python_requests/)
- **Framework Principles**: [`prompts_framework/ae_context.md`](./prompts_framework/ae_context.md)

## License

MIT License - Made by [@arenukvern](https://github.com/arenukvern)

## Support

- Issues: [GitHub Issues](https://github.com/fluent-meaning-symbiotic/agentic_executables/issues)
- Registry URL: https://github.com/fluent-meaning-symbiotic/agentic_executables
