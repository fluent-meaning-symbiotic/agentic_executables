# AE MCP Server

A Model Context Protocol (MCP) server for managing Agentic Executable (AE) frameworks. This server provides tools for bootstrapping, improving, installing, and uninstalling libraries as Agentic Executables.

## Overview

The AE MCP Server enables AI agents to autonomously manage libraries as Agentic Executables, following the principles defined in the AE framework:

- **Agent Empowerment**: Equip AI agents with meta-rules to autonomously maintain libraries
- **Modularity**: Structure AE instructions in clear, reusable steps
- **Contextual Awareness**: Provide sufficient domain knowledge for integration
- **Reversibility**: Design uninstallation to cleanly remove all traces
- **Validation**: Include checks for reliability and corrections

## Features

### Core Tools

1. **`bootstrap_ae`** - Create AE files for a library
2. **`improve_ae_bootstrap`** - Enhance existing AE files
3. **`install_ae`** - Install a library as an Agentic Executable
4. **`uninstall_ae`** - Uninstall a library as an Agentic Executable

### Supported Operations

- **Bootstrap**: Generate installation, uninstallation, update, and usage files
- **Improvement**: Enhance existing AE files with examples, documentation, troubleshooting
- **Installation**: Add dependencies, copy AE files, create usage guides
- **Uninstallation**: Remove dependencies, clean up files, restore original state

## Installation

### Prerequisites

- Dart SDK >= 3.0.0
- Flutter SDK (if using Flutter)

### Install from Source

```bash
git clone https://github.com/your-org/ae_mcp_server.git
cd ae_mcp_server
dart pub get
```

### Install as Executable

```bash
dart pub global activate ae_mcp_server
```

## Usage

### Starting the Server

```bash
# From source
dart run bin/ae_mcp_server.dart

# As global executable
ae_mcp_server
```

### Using with MCP Clients

The server communicates via stdio and can be used with any MCP-compatible client:

```json
{
  "mcpServers": {
    "ae-mcp-server": {
      "command": "dart",
      "args": ["run", "bin/ae_mcp_server.dart"]
    }
  }
}
```

## Tool Reference

### bootstrap_ae

Bootstrap AE files for a library.

**Parameters:**

- `libraryPath` (string, required): Path to the library directory
- `targetAIAgent` (string, required): Target AI agent (e.g., "Cursor AI", "Claude")
- `options` (object, optional): Additional options for bootstrap

**Example:**

```json
{
  "libraryPath": "/path/to/library",
  "targetAIAgent": "Cursor AI",
  "options": {
    "includeExamples": true,
    "addSecurityNotes": true
  }
}
```

### improve_ae_bootstrap

Improve existing AE bootstrap files.

**Parameters:**

- `libraryPath` (string, required): Path to the library directory
- `improvementGoals` (array, required): List of improvement goals
- `options` (object, optional): Additional options for improvement

**Improvement Goals:**

- `add_examples`: Add practical examples
- `improve_documentation`: Enhance documentation quality
- `add_troubleshooting`: Add troubleshooting section
- `add_validation`: Add validation steps
- `improve_structure`: Improve file structure
- `add_best_practices`: Add best practices section
- `add_security_notes`: Add security considerations
- `add_performance_tips`: Add performance optimization tips

**Example:**

```json
{
  "libraryPath": "/path/to/library",
  "improvementGoals": [
    "add_examples",
    "improve_documentation",
    "add_troubleshooting"
  ],
  "options": {
    "targetAudience": "developers",
    "includeAdvancedExamples": true
  }
}
```

### install_ae

Install a library as an Agentic Executable.

**Parameters:**

- `libraryPath` (string, required): Path to the library directory
- `targetProjectPath` (string, required): Path to the target project directory
- `options` (object, optional): Additional options for installation

**Example:**

```json
{
  "libraryPath": "/path/to/library",
  "targetProjectPath": "/path/to/project",
  "options": {
    "skipDependencyCheck": false,
    "backupExisting": true
  }
}
```

### uninstall_ae

Uninstall a library as an Agentic Executable.

**Parameters:**

- `libraryPath` (string, required): Path to the library directory
- `targetProjectPath` (string, required): Path to the target project directory
- `options` (object, optional): Additional options for uninstallation

**Example:**

```json
{
  "libraryPath": "/path/to/library",
  "targetProjectPath": "/path/to/project",
  "options": {
    "deepClean": true,
    "backupBeforeRemoval": true
  }
}
```

## AE Framework Structure

The server creates and manages the following AE file structure:

```
project/
├── ae_use/
│   ├── ae_install.md      # Installation instructions
│   ├── ae_uninstall.md    # Uninstallation instructions
│   ├── ae_update.md       # Update instructions
│   ├── ae_use.md          # Usage guidelines
│   └── {library}_usage.mdc # Library-specific usage rules
└── pubspec.yaml           # Project dependencies
```

## Development

### Project Structure

```
lib/
├── src/
│   ├── server/
│   │   ├── ae_mcp_server.dart
│   │   └── tools/
│   │       ├── bootstrap_tool.dart
│   │       ├── improve_tool.dart
│   │       ├── install_tool.dart
│   │       └── uninstall_tool.dart
│   ├── models/
│   │   └── ae_context.dart
│   └── utils/
│       └── file_operations.dart
├── ae_mcp_server.dart
bin/
└── ae_mcp_server.dart
```

### Running Tests

```bash
dart test
```

### Code Style

The project follows Dart's official style guide. Run the linter:

```bash
dart analyze
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the BSD-3-Clause License - see the [LICENSE](LICENSE) file for details.

## Support

- Documentation: [AE Framework Documentation](https://github.com/your-org/ae-framework)
- Issues: [GitHub Issues](https://github.com/your-org/ae_mcp_server/issues)
- Community: [Discord/Slack Channel](https://your-community-link)

## Acknowledgments

- Built with [dart_mcp](https://pub.dev/packages/dart_mcp)
- Inspired by the Agentic Executable framework
- Community contributions and feedback
