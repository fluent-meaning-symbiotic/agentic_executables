# Prompts Framework MCP Server

A Model Context Protocol (MCP) server that provides strategic guidance for AI agents managing Agentic Executables (AE) - a framework-agnostic approach to library management.

## Overview

This MCP server acts as a **strategic thinking tool** for AI agents, providing structured guidance on how to bootstrap, install, uninstall, update, and use libraries as Agentic Executables across any programming language or framework.

### Key Features

- **Language & Framework Agnostic**: Works with any programming language or framework
- **Strategic Guidance**: Provides HOW-TO guidance rather than direct execution tools
- **Three Core Tools**:
  - `get_ae_instructions` - Retrieve contextual instructions for AE operations
  - `verify_ae_implementation` - Generate verification checklists based on AE principles
  - `evaluate_ae_compliance` - Evaluate implementation compliance with scoring

## Use Cases

### Case 1: Bootstrap AE in a Library

When a developer tasks an AI agent to create AE files for a library:

```
AI Agent → MCP: "get_ae_instructions" (context: library, action: bootstrap)
MCP → AI Agent: Returns ae_bootstrap.md + ae_context.md
AI Agent: Analyzes instructions, creates plan, executes after confirmation
```

### Case 2: Integrate Library as AE in Project

When a developer wants to use a library with AE support:

```
AI Agent → MCP: "get_ae_instructions" (context: project, action: install)
MCP → AI Agent: Returns ae_use.md + ae_context.md
AI Agent: Follows integration instructions, creates plan, executes after confirmation
```

## Installation

### Development

```bash
cd prompts_framework_mcp
dart pub get
```

### Build Native Binary

```bash
dart compile exe bin/prompts_framework_mcp_server.dart -o build/server
```

### Run Server

```bash
# Development
dart run bin/prompts_framework_mcp_server.dart

# Production (compiled binary)
./build/server
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

### 1. get_ae_instructions

Retrieves appropriate AE documentation based on context and action.

**Parameters:**

- `context_type` (required): `"library"` or `"project"`
- `action` (required): `"bootstrap"`, `"install"`, `"uninstall"`, `"update"`, or `"use"`

**Example:**

```json
{
  "context_type": "library",
  "action": "bootstrap"
}
```

**Returns:**

- Relevant .md documentation files
- Context-specific guidance
- Principles reference (ae_context.md)

### 2. verify_ae_implementation

Generates verification checklist based on AE core principles.

**Parameters:**

- `context_type` (required): `"library"` or `"project"`
- `action` (required): Same as above
- `description` (required): Description of what was implemented

**Example:**

```json
{
  "context_type": "project",
  "action": "install",
  "description": "Installed go_router package as AE with configuration files"
}
```

**Returns:**

- Verification checklist with critical items
- Principle-based checks (Modularity, Reversibility, Validation, etc.)
- Action-specific validation points

### 3. evaluate_ae_compliance

Evaluates implementation against AE principles with scoring.

**Parameters:**

- `implementation_details` (required): Detailed implementation description
- `context_type` (required): `"library"` or `"project"`

**Example:**

```json
{
  "implementation_details": "Created ae_install.md with step-by-step instructions for dependency installation, configuration setup, and service integration. Included validation checks at each step.",
  "context_type": "library"
}
```

**Returns:**

- Overall compliance score (0-100)
- Principle-based scoring:
  - Agent Empowerment (20%)
  - Modularity (20%)
  - Contextual Awareness (20%)
  - Reversibility (15%)
  - Validation (15%)
  - Documentation Quality (10%)
- Recommendations for improvement

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
prompts_framework_mcp/
├── bin/
│   └── prompts_framework_mcp_server.dart   # Entry point
├── lib/
│   └── src/
│       ├── server.dart                     # MCPServer implementation
│       ├── resources/
│       │   └── ae_documents.dart           # Document loading/caching
│       └── tools/
│           ├── get_ae_instructions.dart
│           ├── verify_ae_implementation.dart
│           └── evaluate_ae_compliance.dart
├── resources/
│   ├── ae_context.md                       # Core principles
│   ├── ae_bootstrap.md                     # Bootstrap guidance
│   └── ae_use.md                          # Usage guidance
├── Dockerfile                              # Multi-stage build
└── pubspec.yaml                           # Dependencies
```

## Integration with AI Agents

AI agents (like Claude, GPT-4, or others) can integrate this MCP server to:

1. **Query for guidance** when faced with library management tasks
2. **Verify their work** against AE principles before execution
3. **Evaluate compliance** of their implementations
4. **Adapt instructions** to specific project contexts and languages

### Example Agent Workflow

```
1. Developer: "Bootstrap AE for the 'axios' library"
2. Agent: Queries MCP → get_ae_instructions(library, bootstrap)
3. Agent: Receives ae_bootstrap.md + ae_context.md
4. Agent: Analyzes codebase, creates plan
5. Agent: Presents plan to developer
6. Developer: Approves
7. Agent: Executes plan
8. Agent: Queries MCP → verify_ae_implementation(...)
9. Agent: Reviews checklist, confirms all items met
10. Agent: Queries MCP → evaluate_ae_compliance(...)
11. Agent: Reviews score, makes improvements if needed
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

- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [dart_mcp Package](https://pub.dev/packages/dart_mcp)
- AE Framework Documentation (see `resources/` directory)
