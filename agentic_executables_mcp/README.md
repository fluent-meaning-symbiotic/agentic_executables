# Prompts Framework MCP Server

A Model Context Protocol (MCP) server that provides strategic guidance for AI agents managing Agentic Executables (AE) - a framework-agnostic approach to library management.

## Overview

This MCP server acts as a **strategic thinking tool** for AI agents, providing structured guidance on how to bootstrap, install, uninstall, update, and use libraries as Agentic Executables across any programming language or framework.

### Key Features

- **Language & Framework Agnostic**: Works with any programming language or framework
- **Strategic Guidance**: Provides HOW-TO guidance rather than direct execution tools
- **Registry Integration**: Submit and fetch AE files from centralized registry
- **Five Core Tools**:
  - `get_agentic_executable_definition` - Get AE framework overview and definitions
  - `get_ae_instructions` - Retrieve contextual instructions for AE operations
  - `verify_ae_implementation` - Generate verification checklists based on AE principles
  - `evaluate_ae_compliance` - Evaluate implementation compliance with scoring
  - `manage_ae_registry` - Submit libraries to registry or fetch library files

## Use Cases

### Case 1: Library Author - Bootstrap & Submit AE

When a library author wants to create and publish AE files:

```
AI Agent → MCP: "get_ae_instructions" (context: library, action: bootstrap)
MCP → AI Agent: Returns ae_bootstrap.md + ae_context.md
AI Agent: Creates ae_install.md, ae_uninstall.md, ae_update.md, ae_use.md
AI Agent → MCP: "manage_ae_registry" (operation: submit_to_registry)
MCP → AI Agent: Returns PR instructions for registry submission
```

### Case 2: Developer - Fetch & Install Library as AE

When a developer wants to use a library with AE support:

```
AI Agent → MCP: "manage_ae_registry" (operation: get_from_registry, library_id: python_requests)
MCP → AI Agent: Returns ae_install.md content
AI Agent: Follows installation instructions, executes after confirmation
```

### Case 3: Understand AE Framework

When an AI agent needs to understand what AE is:

```
AI Agent → MCP: "get_agentic_executable_definition"
MCP → AI Agent: Returns AE definition, contexts, actions, tools, principles
```

## Installation

For detailed installation instructions, see [ae_install.md](ae_install.md).

### Quick Start

```bash
# Clone and build
cd agentic_executables_mcp
./build.sh

# Run the server
./build/server
```

### MCP Client Configuration

Add to your MCP client configuration (e.g., Claude Desktop):

```json
{
  "mcpServers": {
    "agentic_executables": {
      "command": "/absolute/path/to/agentic_executables_mcp/build/server"
    }
  }
}
```

## Docker Deployment

### Build Image

```bash
docker build -t prompts-framework-mcp:latest .
```

### Run Container

```bash
docker run -i prompts-framework-mcp:latest
```

The server communicates via STDIO, so it needs interactive mode (`-i` flag).

### Cloud Deployment

For cloud deployment, the Docker container can be orchestrated using:

- Kubernetes (as a sidecar or standalone pod)
- Cloud Run / Cloud Functions (with STDIO handling)
- ECS/Fargate (with proper task configuration)

## MCP Tools

### 1. get_agentic_executable_definition

**Purpose**: Get core AE framework definition and overview.

**Parameters**: None

**Example**:

```json
{}
```

**Returns**:

- AE definition and description
- Available contexts (library, project)
- Available actions (bootstrap, install, uninstall, update, use)
- All 5 tools with descriptions
- Core principles
- Usage guide for maintainers and developers

**Use Case**: Essential for agents unfamiliar with AE framework or when no server instructions are available.

### 2. get_ae_instructions

**Purpose**: Retrieve contextual AE documentation based on context and action.

**Parameters**:

- `context_type` (required): `"library"` or `"project"`
- `action` (required): `"bootstrap"`, `"install"`, `"uninstall"`, `"update"`, or `"use"`

**Example**:

```json
{
  "context_type": "library",
  "action": "bootstrap"
}
```

**Returns**:

- Relevant .md documentation files
- Context-specific guidance
- Principles reference (ae_context.md)

**Use Case**: Get instructions for creating AE files (library) or integrating libraries (project).

### 3. verify_ae_implementation

**Purpose**: Generate verification checklist with objective pass/fail criteria.

**Parameters**:

- `context_type` (required): `"library"` or `"project"`
- `action` (required): Action that was performed
- `files_modified` (optional): JSON string array of file objects with path, LOC, sections
- `checklist_completed` (optional): JSON string object of checklist items (true/false)

**Example**:

```json
{
  "context_type": "project",
  "action": "install",
  "files_modified": "[{\"path\": \"ae_install.md\", \"loc\": 180, \"sections\": [\"Installation\", \"Configuration\"]}]",
  "checklist_completed": "{\"modularity\": true, \"contextual_awareness\": true, \"agent_empowerment\": true}"
}
```

**Returns**:

- Verification checklist with critical items
- Pass/fail results based on provided data
- Principle-based checks (Modularity, Reversibility, Validation, etc.)

**Use Case**: Objective verification after implementation using structured metrics.

### 4. evaluate_ae_compliance

**Purpose**: Evaluate implementation with structured scoring (favors conciseness).

**Parameters**:

- `context_type` (required): `"library"` or `"project"`
- `action` (required): Action that was performed
- `files_created` (optional): JSON string array of file objects with path and LOC
- `sections_present` (optional): JSON string array of section names
- `validation_steps_exists` (optional): Boolean string ("true" or "false")
- `integration_points_defined` (optional): Boolean string
- `reversibility_included` (optional): Boolean string
- `has_meta_rules` (optional): Boolean string

**Example**:

```json
{
  "context_type": "library",
  "action": "bootstrap",
  "files_created": "[{\"path\": \"ae_install.md\", \"loc\": 150}]",
  "sections_present": "[\"Installation\", \"Configuration\", \"Validation\"]",
  "validation_steps_exists": "true",
  "reversibility_included": "true"
}
```

**Returns**:

- Overall compliance score with pass/fail verdict
- LOC scoring: <500 PASS, 500-800 WARNING, >800 FAIL (lower is better)
- Principle-based evaluation
- Recommendations for improvement

**Use Case**: Objective scoring based on concrete metrics, not subjective descriptions.

### 5. manage_ae_registry

**Purpose**: Submit libraries to registry (authors) or fetch library files (developers).

**Parameters**:

- `operation` (required): `"submit_to_registry"`, `"get_from_registry"`, or `"bootstrap_local_registry"`
- `library_url` (for submit): GitHub repository URL
- `library_id` (for submit/get): Format `<language>_<library_name>` (e.g., `python_requests`)
- `ae_use_files` (for submit): Comma-separated list of ae_use file paths
- `action` (for get): Which file to fetch (`"install"`, `"uninstall"`, `"update"`, `"use"`)
- `ae_use_path` (for bootstrap_local): Path to local ae_use folder

**Example - Submit to Registry**:

```json
{
  "operation": "submit_to_registry",
  "library_url": "https://github.com/owner/requests",
  "library_id": "python_requests",
  "ae_use_files": "ae_use/ae_install.md,ae_use/ae_uninstall.md,ae_use/ae_update.md,ae_use/ae_use.md"
}
```

**Example - Get from Registry**:

```json
{
  "operation": "get_from_registry",
  "library_id": "python_requests",
  "action": "install"
}
```

**Returns**:

- For submit: PR instructions, file mappings, registry folder path
- For get: File content directly from registry
- For bootstrap_local: Instructions for monorepo setup

**Use Case**: Authors publish AE files, developers fetch them directly without manual browsing.

## Registry Configuration

The server integrates with the centralized AE registry:

- **Registry URL**: https://github.com/fluent-meaning-symbiotic/agentic_executables
- **Registry Path**: `ae_use_registry/`
- **Library ID Format**: `<language>_<library_name>` (e.g., `python_requests`, `dart_provider`)
- **Required Files**: `ae_install.md`, `ae_uninstall.md`, `ae_update.md`, `ae_use.md`, `README.md`

### For Library Authors

1. Create AE files using `get_ae_instructions`
2. Call `manage_ae_registry` with `submit_to_registry` operation
3. Follow PR instructions to submit to registry
4. Developers can then fetch your library files directly

### For Developers

1. Call `manage_ae_registry` with `get_from_registry` operation
2. Specify `library_id` and `action` (install/uninstall/update/use)
3. Receive file content directly from registry
4. No authentication required for public registry

## AE Framework Principles

The server guides agents to follow these core principles:

1. **Agent Empowerment**: Enable AI agents to work autonomously
2. **Modularity**: Structure instructions in clear, reusable steps
3. **Contextual Awareness**: Provide sufficient domain knowledge
4. **Reversibility**: Ensure clean uninstallation and state restoration
5. **Validation**: Include reliability checks
6. **Documentation Focus**: Prioritize agent-readable, concise instructions

## Architecture

```
agentic_executables_mcp/
├── bin/
│   └── agentic_executables_mcp_server.dart          # Entry point
├── lib/
│   └── src/
│       ├── server.dart                            # MCPServer implementation
│       ├── ae_framework_config.dart               # Registry & framework config
│       ├── ae_validation_config.dart              # Validation rules
│       ├── resources/
│       │   └── ae_documents.dart                  # Document loading/caching
│       ├── tools/
│       │   ├── get_agentic_executable_definition.dart
│       │   ├── get_ae_instructions.dart
│       │   ├── verify_ae_implementation.dart
│       │   ├── evaluate_ae_compliance.dart
│       │   └── manage_ae_registry.dart            # Registry operations
│       └── utils/
│           ├── github_raw_fetcher.dart            # Fetch from GitHub
│           └── registry_resolver.dart             # Registry path resolution
├── resources/
│   ├── ae_context.md                              # Core principles
│   ├── ae_bootstrap.md                            # Bootstrap guidance
│   └── ae_use.md                                  # Usage guidance
├── Dockerfile                                     # Multi-stage build
└── pubspec.yaml                                   # Dependencies
```

## Integration with AI Agents

AI agents (like Claude, GPT-4, or others) can integrate this MCP server to:

1. **Understand AE framework** via `get_agentic_executable_definition`
2. **Query for guidance** when faced with library management tasks
3. **Access registry** to submit or fetch library AE files
4. **Verify their work** against AE principles with objective metrics
5. **Evaluate compliance** using structured scoring
6. **Adapt instructions** to specific project contexts and languages

### Example Workflow: Library Author

```
1. Developer: "Bootstrap AE for the 'axios' library and publish to registry"
2. Agent: Queries MCP → get_ae_instructions(library, bootstrap)
3. Agent: Receives ae_bootstrap.md + ae_context.md
4. Agent: Analyzes codebase, creates AE files
5. Agent: Presents plan to developer
6. Developer: Approves
7. Agent: Executes plan (creates ae_install.md, ae_uninstall.md, etc.)
8. Agent: Queries MCP → verify_ae_implementation(library, bootstrap, files_modified, checklist)
9. Agent: Reviews verification results
10. Agent: Queries MCP → evaluate_ae_compliance(library, bootstrap, files_created, sections)
11. Agent: Reviews score, optimizes if needed
12. Agent: Queries MCP → manage_ae_registry(submit_to_registry, library_url, library_id, ae_use_files)
13. Agent: Receives PR instructions, presents to developer
```

### Example Workflow: Developer Using Library

```
1. Developer: "Install the requests library using AE"
2. Agent: Queries MCP → manage_ae_registry(get_from_registry, library_id: python_requests, action: install)
3. Agent: Receives ae_install.md content
4. Agent: Analyzes instructions, creates plan
5. Agent: Presents plan to developer
6. Developer: Approves
7. Agent: Executes installation steps
8. Agent: Queries MCP → verify_ae_implementation(project, install, files_modified, checklist)
9. Agent: Confirms successful installation
```

## Development

### Running Tests

```bash
dart test
```

### Linting

```bash
dart analyze
```

### Format Code

```bash
dart format .
```

## Contributing

This MCP server is part of the Agentic Executables framework. When contributing:

1. Follow AE principles in all implementations
2. Keep instructions language-agnostic
3. Prioritize agent-readability over human verbosity
4. Test with multiple AI agent implementations

## License

Made by [@arenukvern](https://github.com/arenukvern)
[MIT License](./LICENSE)

## Support

For issues, questions, or contributions, please visit the repository or contact the maintainers.

## References

- [Installation Guide](ae_install.md) - Detailed installation instructions for AI agents
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [dart_mcp Package](https://pub.dev/packages/dart_mcp)
- [AE Registry](https://github.com/fluent-meaning-symbiotic/agentic_executables/tree/main/ae_use_registry)
- AE Framework Documentation (see `resources/` directory)
